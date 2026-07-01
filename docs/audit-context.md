# Audit Context

Context for a security review of this repository. It describes the intended design, the areas to
focus on, the invariants that must hold, behaviors that are intended (not findings), and what is
explicitly out of scope.

## 1. Scope

In scope — all first-party contracts under `src/`:

| Area | Files |
|------|-------|
| Types | `types/Balances.sol`, `types/Allowances.sol`, `types/Token.sol`, `types/Metadata.sol`, `types/Permit.sol`, `types/UERC20Config.sol` |
| Extensions | `extensions/Lockup.sol` |
| Tokens | `tokens/UERC20.sol`, `tokens/LockedUERC20.sol` |
| Factory | `factories/TokenFactory.sol` |
| Interfaces | `interfaces/IUERC20.sol`, `interfaces/ITokenFactory.sol` |

Compiler: Solidity `0.8.28` (checked arithmetic). No proxies, no upgradeability; all tokens are
immutable once deployed.

## 2. Intended design

**Type-driven composition, not inheritance.** Token behavior is implemented as small value types
with attached free functions (`Balances`, `Allowances`, `Token`, `Metadata`, `Permit`) plus optional
behavioral extensions (`Lockup`). Each token is a **standalone contract** that implements `IUERC20`
and wires a thin, fully explicit external surface to those free functions. There is intentionally no
shared base contract; the surface re-declaration per token is deliberate. Reviewers should verify
each token's wiring independently — there is no hidden inherited behavior.

**Generic factory.** `TokenFactory` is permissionless and generic:

- `register(initCode)` stores a token's creation code once via SSTORE2 and returns an incrementing
  `id` (starting at 1).
- `createToken(id, data, graffiti)` reads the stored creation code and deploys it with `CREATE2`.
  The salt is `keccak256(abi.encode(id, msg.sender, graffiti, keccak256(data)))`.
- The factory never decodes token config. It exposes the deployment context
  (`{creator, graffiti, data}`) via `deployment()`; the token's constructor calls back to read and
  `abi.decode`s `data` into its own config struct. `creator` is the `createToken` caller; `data` is
  opaque to the factory.
- `getAddress(...)` predicts the deployed address and must match `createToken`'s result for identical
  inputs.

This is the SSTORE2 technique, not EIP-5202 (no `0xFE71` preamble) — intentional, since the factory
only reads its own pointers.

**Config passing.** Tokens decode a canonical `UERC20Config` (name, symbol, decimals, totalSupply,
recipient, metadata). Feature tokens nest it, e.g. `LockedUERC20.Config { UERC20Config base; address owner; }`.
Callers are expected to encode with named struct literals.

**Standard-token surface.** `UERC20` targets full parity: ERC-20, EIP-2612 `permit`, a default
infinite allowance to the canonical Permit2 address, ERC-165, `IERC20Metadata`, and `tokenURI`.
Permit verification is composed from OpenZeppelin `ECDSA.recover` + `MessageHashUtils.toTypedDataHash`;
the EIP-712 domain separator is built and cached in the `Permit` type.

## 3. Trust model

- The factory is **permissionless and unauthenticated**: anyone may register any creation code and
  deploy it. "Deployed by the factory" carries **no** implication of safety or provenance. Off-chain
  consumers are expected to allowlist known-good `initCodeHash` values (emitted in `Registered` and
  derivable per deployment). This is by design (see Out of scope).
- `LockedUERC20` is intentionally centralized: the `owner` can allowlist/deny transfers and unlock
  globally. This owner power is a feature, not a finding.

## 4. Focus areas (ranked)

### 4.1 `Permit` (highest priority — hand-composed EIP-712/EIP-2612)
- Domain separator correctness: typehash, `name`, `version = "1"`, `chainId`, `verifyingContract`.
- Fork handling: `domainSeparator()` must recompute when `block.chainid` differs from the cached id.
- `verifyingContract` is captured as `address(this)` at construction; confirm this is always the
  token's own address given CREATE2 deployment.
- Replay/nonce: the owner nonce must be consumed exactly once per successful permit and never reused;
  a failed verification must not consume it (atomic revert).
- Deadline enforcement; signer recovery via `ECDSA.recover` (malleability handled) and the
  `signer == owner` check.

### 4.2 `TokenFactory`
- Re-entrancy: `_ctx` is set immediately before the `CREATE2` and `delete`d immediately after, guarded
  by `nonReentrant`. Verify a malicious constructor cannot observe or corrupt another deployment's
  context, and that nested `createToken` is correctly blocked.
- Address determinism and collisions: `createToken` and `getAddress` must derive identical salts;
  deploying to an already-occupied address must revert cleanly. `msg.sender` is in the salt, so one
  caller cannot occupy another caller's predicted address.
- `_deploy` assembly: correct revert-reason bubbling and memory safety.

### 4.3 Token accounting (`Token`, `Balances`, `Allowances`)
- `transferFrom` allowance spend ordering and checked-arithmetic underflow on both allowance and
  balance.
- Permit2 default allowance: `allowance(_, PERMIT2)` must always read `type(uint256).max` and must
  never be decremented on spend; confirm finite allowances still decrement correctly.

### 4.4 `LockedUERC20` / `Lockup`
- Access control on `allowlist`, `unlock`, `setOwner` (`onlyOwner`), and non-zero `owner` invariants.
- Transfer gating: `transfer`/`transferFrom` are permitted iff globally unlocked **or** the sender
  **or** recipient is allowlisted; the initial mint is exempt.

## 5. Key invariants

- Sum of all balances equals `totalSupply` for every token (supply is fixed at construction; there is
  no external mint or burn).
- `allowance(owner, PERMIT2) == type(uint256).max` regardless of stored value.
- Permit nonces are strictly increasing and each signature is usable at most once.
- `TokenFactory.getAddress(id, caller, graffiti, keccak256(data))` equals the address returned by
  `createToken(id, data, graffiti)` from `caller`.
- While no token is under construction, `TokenFactory.deployment()` returns zeroed context.
- On `LockedUERC20`, no transfer succeeds while locked unless a party is allowlisted; only `owner`
  can change lock state.

## 6. Intended behaviors (not findings)

- **Permissionless factory / arbitrary code.** Registering and deploying arbitrary or malicious
  creation code is expected; provenance is an off-chain concern.
- **Transfers to `address(0)`** are allowed (balance moves without reducing `totalSupply`); the
  balance invariant still holds. This matches common gas-optimized ERC-20 behavior.
- **Fixed supply.** Tokens mint once in the constructor and expose no mint/burn.
- **Caller-supplied `decimals`.** Arbitrary `uint8`; not validated.
- **Irreversible unlock.** `LockedUERC20.unlock()` is one-way; there is no re-lock.
- **`creator` attribution.** Set to the `createToken` caller by the factory, not self-attested by the
  token config.
- **Tokens are factory-only.** A token's constructor calls `ITokenFactory(msg.sender).deployment()`;
  deploying a token by any means other than the factory will revert or misbehave and is unsupported.

## 7. Out of scope

- **Third-party libraries** (assumed correct): Solady `SSTORE2`; OpenZeppelin `ECDSA`,
  `MessageHashUtils`, `Create2`, `Base64`, `Strings`, and the `IERC20*`/`IERC165` interfaces.
- **Provenance of factory-deployed tokens** — permissionless deployment of arbitrary code is a design
  property, not a vulnerability (see Trust model).
- **EIP-5202 compliance** — the factory deliberately uses SSTORE2, not the EIP-5202 blueprint format.
- **ERC-1271 / smart-contract-wallet signatures** for `permit` — only ECDSA/EOA signatures are
  supported.
- **Off-chain tooling, tests, and deployment scripts.**
- **Gas optimization**, except where it affects correctness.
- **Stale artifacts** under `docs/autogen/` and `snapshots/` describe previous, removed contracts and
  are not part of the current system.
