# Type-Driven Token Refactor — Migration Plan

**Status:** Proposal for review (no code yet)
**Decisions locked in:**
1. Token internals: **full type-driven rewrite** (hand-roll ERC-20 from composable types; drop Solady *inheritance* but keep Permit2 default allowance + EIP-712 + EIP-2612 parity, re-expressed as free functions).
2. Factory: **permissionless blueprint registry** — init-code is stored once via SSTORE2, then referenced by `id` per deploy so L2 calldata stays small. (This is the SSTORE2 technique, not the EIP-5202 standard — no `0xFE71` preamble; the factory only reads its own pointers.)
3. This document is plan-only.

> Terminology: the token variants below are **features**, not "flavors".

References:
- https://github.com/jtriley2p/type-driven-tokens
- https://gist.github.com/jtriley2p/2e9ed88fe48a6162d2c6e60f6b5bebae

---

## 1. Goals & non-goals

**Goals**
- Eliminate per-feature `Parameters` structs, per-feature factory interfaces, and per-feature factory contracts.
- Express each token feature as *composed types + one behavior policy*, not a new inheritance branch.
- Make the basic ERC-20 surface testable once and reused across every feature; isolate custom-logic tests.
- Add features: wrapper, receipt, transfer-locked, permissioned, fee-on-transfer (plus existing UERC20, USUPERC20).

- Keep Permit2 default allowance, EIP-712, and EIP-2612 behavior identical to the current Solady-based token.

**Scope (this is a rewrite)**
- **Delete** the old factories (`UERC20Factory`, `USUPERC20Factory`) and token contracts (`BaseUERC20`, `UERC20`, `USUPERC20`) and their interfaces — no parallel v2/v3.
- **Preserve** the `UERC20Metadata` struct + `toJSON`/`escapeJSON` work as-is (ported into the new `Metadata` type).
- **Maintain feature parity** with today's `UERC20` (ERC-165, EIP-2612 permit, Permit2 default allowance, creator/graffiti, metadata/tokenURI) and `USUPERC20` (IERC7802 crosschain mint/burn, home-chain-only mint + metadata).
- **Build the core first** (types + base `UERC20` + `USUPERC20` parity + generic factory); new features come after.

**Non-goals**
- Preserving existing deployed addresses (the rewrite changes all creation code → all CREATE2 addresses change; this is a new major version).
- Reusing the existing OpenZeppelin audit for rewritten code (it is invalidated; see §7).

---

## 2. The two architectural axes

| Axis | Problem today | Fix |
|---|---|---|
| Token internals | New feature = new contract on a `BaseUERC20` inheritance branch | Type-driven composition: ERC-20 state split into `Balances` / `Allowances` / `Supply`, behavior added as policy types |
| Factory / params | Each token's ctor reads a **statically-typed** `Parameters` via `getParameters()`, forcing a new struct + interface + factory per feature | One factory; init-code registered once as a blueprint, referenced by `id`; each token decodes its own config from an **opaque `bytes`** payload |

These are independent. The plan addresses both.

---

## 3. Target file tree

```
src/
  types/
    Balances.sol        struct Balances        { mapping(address=>uint256) }      read/write/increase/decrease
    Allowances.sol      struct Allowances      { mapping=>mapping }               read/write/spend
    Supply.sol          type Supply is uint256 (or struct)                        mint/burn (checked)
    Token.sol           struct Token { Balances; Allowances; Supply }             transfer/transferFrom/approve/mint/burn
    Metadata.sol        struct Metadata { name,symbol,decimals + desc/site/img/extraData }  toJSON
    Permit.sol          struct Permit { nonces; cached domainSeparator/chainId }   domainSeparator/hashTypedData/permit  (EIP-712 + EIP-2612, free fns)
    (Permit2 default allowance = a branch in Allowances.read: max allowance when spender == canonical PERMIT2)
  policies/
    FeePolicy.sol       struct FeePolicy   { uint16 bps; address recipient }      split(amount)
    Lock.sol            struct Lock        { uint64 unlockTime; mapping exempt }  enforce(from)
    AccessList.sol      struct AccessList  { mapping(address=>bool) allowed }     check(from,to)
    Vault.sol           struct Vault       { address underlying }                 deposit/withdraw accounting
    MintAuth.sol        struct MintAuth    { address minter }                     onlyMinter
  tokens/                 (one contract per feature; each composes core types + at most one policy)
    UERC20.sol            Token + Metadata + Permit                       (base; parity with current UERC20)
    USUPERC20.sol         base + IERC7802 crosschain mint/burn + homeChainId
    FeeOnTransferUERC20.sol   base + FeePolicy
    TransferLockedUERC20.sol  base + Lock
    PermissionedUERC20.sol    base + AccessList
    WrapperUERC20.sol         base + Vault (deposit/withdraw underlying)
    ReceiptUERC20.sol         base + MintAuth (authorized mint/burn)
  factories/
    TokenFactory.sol      blueprint registry + CREATE2 deployer (register once, deploy by id)
  interfaces/
    ITokenFactory.sol     register(bytes initCode) + createToken(uint256 id, bytes data, bytes32 graffiti) + initData()
    IERC7802.sol          (existing, for USUPERC20)

test/
  types/        Balances.t.sol, Allowances.t.sol, Token.t.sol, Supply.t.sol, Permit.t.sol, Metadata.t.sol
  policies/     FeePolicy.t.sol, Lock.t.sol, AccessList.t.sol, Vault.t.sol, MintAuth.t.sol
  conformance/  ERC20ConformanceTest.sol (abstract), ERC2612ConformanceTest.sol (abstract)
  tokens/       one file per feature, inherits conformance + adds custom-logic tests
  Factory.t.sol
  invariant/    supply==sum(balances) handlers per feature
```

`src/tokens/BaseUERC20.sol`, `src/libraries/UERC20MetadataLibrary.sol`, both `*Factory.sol`, `IUERC20Factory.sol`, `IUSUPERC20Factory.sol` are **removed/replaced**.

---

## 4. Type-driven internals (style per the gist)

- Types in `types/`; functions take the type as the **first parameter** and return it for chaining.
- `using { fn, ... } for T global;` attaches behavior. Library name matches the type.
- Value types where it buys safety/clarity, e.g. `type Supply is uint256` with checked mint/burn; operator overloads only where they read clearly.
- Minimize side effects inside type functions; the feature contract owns events + external-call ordering (checks-effects-interactions).

A feature contract is a thin shell holding one composed storage struct and exposing the **entire** ERC-20 interface explicitly (no hidden parent methods):

```
contract FeeOnTransferUERC20 {
    Token    internal _token;
    Metadata internal _meta;
    Permit   internal _permit;
    FeePolicy internal _fee;

    constructor() { /* decode config from ITokenFactory(msg.sender).initData() */ }

    function transfer(address to, uint256 v) external returns (bool) {
        (uint256 toRecipient, uint256 toReceiver) = _fee.split(v);
        _token.transfer(msg.sender, _fee.recipient, toRecipient);
        _token.transfer(msg.sender, to, toReceiver);
        emit Transfer(msg.sender, _fee.recipient, toRecipient);
        emit Transfer(msg.sender, to, toReceiver);
        return true;
    }
    // balanceOf/allowance/approve/transferFrom/permit/... delegate to the types
}
```

---

## 4a. How features compose (the "no inheritance" ergonomics)

With no inheritance, each feature contract *is* the whole contract: it declares every external function and delegates to the composed types. Features relate to the transfer path in one of three ways:

- **Additive** (wrapper, receipt): add *new* functions (`deposit`/`withdraw`, `mint`/`burn`); the standard ERC-20 surface is untouched. Zero conflict.
- **Guard** (transfer-locked, permissioned): `transfer`/`transferFrom` gain a one-line policy check, then delegate to the same `Token` transfer. Near-zero divergence.
- **Transform** (fee-on-transfer): amount/recipients change, so `transfer`/`transferFrom` reimplement the body (split + two moves + two events). Inherent — an inheritance `_update` override would be equally custom.

```
// guard (permissioned)
function transfer(address to, uint256 v) external returns (bool) {
    _access.check(msg.sender, to);          // policy
    _token.transfer(msg.sender, to, v);     // shared path
    emit Transfer(msg.sender, to, v);
    return true;
}
// transform (fee)
function transfer(address to, uint256 v) external returns (bool) {
    (uint256 fee, uint256 net) = _fee.split(v);
    _token.transfer(msg.sender, _fee.recipient, fee);
    _token.transfer(msg.sender, to, net);
    emit Transfer(msg.sender, _fee.recipient, fee);
    emit Transfer(msg.sender, to, net);
    return true;
}
```

**Where the logic lives (no duplication).** All behavior is in the free functions attached to the types — `balanceOf` = `self.balances.read(a)`, defined once, used by every feature. **Transfer variants are also free functions** (`Token.transfer`, `FeePolicy.feeTransfer`, a guard = `check()` + `Token.transfer`), so even the transfer *logic* is shared and named, not copied. A feature contract is a thin, complete ABI surface that wires the free functions it wants; its single canonical `transfer(address,uint256)` points at its chosen transfer free function.

**Selector rule (why "a collection of transfer functions" is safe):** a contract may declare a signature only once, so each feature has exactly one `transfer(address,uint256)` (no clash). Variants live *across* feature contracts and *as* free functions — never as multiple `transfer`s in one contract. Differently-named external variants would not clash but wallets only call the canonical selector, so variants must be the implementation *behind* it.

**Decision (locked): re-declare the invariant surface per feature (pure type-driven).** Solidity sources external ABI only from a declaration in the contract or from inheritance — free functions can't inject external ABI. Since the logic is already DRY via free functions, the only repetition is ~8–10 trivial one-liners that each visibly delegate to a shared free function, which *is* the design principle (all surface visible at the contract level, nothing behind layers). A shared `ERC20Core` base was considered and rejected: it would save the one-liners but move the invariant surface one layer up, against the intent, for no logic-duplication saving. Stored function-pointers / one-contract-with-a-mode were also rejected (collapses separate auditable features into a mega-contract with runtime branching; storage function pointers are an audit footgun).

## 5. Generic factory (blueprint registry — cheap on L2)

Raw init-code is **never** passed per deploy (avoids L2 calldata cost). Instead it is stored once via SSTORE2 (init-code kept as a contract's runtime), then referenced by `id`. Note: this is the SSTORE2 technique, not the EIP-5202 standard — we do not add the `0xFE71` preamble, since the factory only reads its own pointers and needs no external blueprint discovery.

```
interface ITokenFactory {
    event Registered(uint256 indexed id, address blueprint, bytes32 initCodeHash);
    event TokenCreated(address token, address creator, uint256 indexed id, bytes data);

    function register(bytes calldata initCode) external returns (uint256 id);   // once per implementation
    function initData() external view returns (bytes memory);                   // ctor callback
    function createToken(uint256 id, bytes calldata data, bytes32 graffiti)     // cheap: id + config only
        external returns (address token);
    function getAddress(uint256 id, address creator, bytes32 graffiti, bytes32 dataHash)
        external view returns (address);
}
```

- `register` is permissionless and pays the big calldata/storage cost a **single time** per unique implementation; subsequent deploys carry only `id` + the config blob.
- Factory stores `data` in **transient storage** (`transient` / EIP-1153, solc 0.8.28), exposes it via `initData()`, deploys via `extcodecopy(blueprint) + CREATE2`, then it auto-clears.
- Token ctors take **no args**; they call back `initData()` and decode their own config struct. The factory never knows any feature's struct.
- **Salt / identity:** `salt = keccak256(abi.encode(id, msg.sender, graffiti, keccak256(data)))` — full config in the address. Same inputs → same address; the implementation is bound via `id` (→ a fixed `initCodeHash`). Uses **CREATE2**.

---

### 5a. Deployment mechanism — blueprint vs clone vs direct (decided: blueprint)

The factory needs to turn "an id + config" into a deployed token. Three ways:

| Mechanism | Generic factory (add features w/o redeploy)? | Per-call gas | Constructor/immutables | Result |
|---|---|---|---|---|
| **SSTORE2 registry** ← rec. | yes (register init-code at runtime) | native, none | ✅ | standalone real contract |
| **Clone (EIP-1167)** | yes | +~2.6k delegatecall **every call, forever** | ❌ (needs `initialize`/immutable-args) | proxy → shared logic |
| **Direct `new X()`** | no (factory imports each type) | native, none | ✅ | standalone real contract |

**Decision (locked):** **register-once init-code via SSTORE2 + CREATE2.**

Why it's the fit: the factory is a canonical singleton at a vanity address; making it *generic* means it never has to churn that address to add a feature. Generic + standalone (non-proxy) tokens ⇒ the creation code must be handed in at runtime and stored ⇒ "register-once initcode." Register = `SSTORE2.write`, deploy = `SSTORE2.read` + `CREATE2`. This is the SSTORE2 technique, **not** EIP-5202: we don't add the `0xFE71` preamble/version header, because the factory reads only its own pointers and needs no standardized external blueprint discovery. If external tooling ever needs to recognize these as EIP-5202 blueprints, add the preamble on write and strip it before `CREATE2`.

Why not clones (EIP-1167), for a *token* specifically:
- ~2.6k delegatecall tax on **every** transfer/approve, forever, for every holder.
- no constructor ⇒ can't cache the EIP-712 `DOMAIN_SEPARATOR` as immutable ⇒ messier/gassier Permit2/2612 + fork footgun.
- tokens present as proxies (explorer/analytics/venue handling) and share a single-point-of-failure implementation.
- clones-with-immutable-args fixes only ctor args; tax + proxy nature remain.

Conservative fallback (if "only patterns the team knows cold" wins): plain `new X()` with **explicitly versioned factories** (as Uniswap does for V2/V3/V4). Identical resulting tokens; cost = factory address churn + indexers tracking multiple factories.

## 6. Feature map

| Feature | Policy type | Custom external surface | Conformance suites |
|---|---|---|---|
| UERC20 (base) | — | — | ERC20 + ERC2612 |
| USUPERC20 | — (IERC7802) | crosschainMint/Burn, homeChainId | ERC20 + ERC2612 |
| FeeOnTransfer | FeePolicy | view fee config | ERC20* + ERC2612 |
| TransferLocked | Lock | unlockTime, exempt views | ERC20* + ERC2612 |
| Permissioned | AccessList | allow/deny (admin), isAllowed | ERC20* + ERC2612 |
| Wrapper ✅ | — (immutable underlying) | redeem(amount), redeem(to,amount), redeemFrom, UNDERLYING_TOKEN_ADDRESS, underlyingTotalSupply, underlyingBalance | ERC20 + ERC2612 |
| Receipt | MintAuth | mint/burn (onlyMinter), minter | ERC20 + ERC2612 |

\* Fee/Lock/Permissioned override transfer semantics, so the conformance harness exposes hooks (expected-received amount, allow-list setup) so the standard assertions still apply.

**Wrapper (built).** Redemption model, not deposit/mint — the full supply is minted upfront (like the base UERC20) and the token is a freely-transferable virtual claim on an underlying ERC20, redeemable 1:1 by burning. Implements `IVirtualERC20` (Uniswap liquidity-launcher). Design decisions (locked):
- **Underlying is immutable** at construction (in the config blob) — no owner, no `setAsset`, matching the trustless factory model. Contract is collateralized by transferring the underlying in after deploy.
- **Redemption is first-come-first-served**: `redeem` burns 1:1 and `safeTransfer`s the underlying, reverting if the contract is underfunded. No full-collateralization gate (burn+transfer drop supply and balance equally, so `balance >= supply` is preserved once it holds). `underlyingTotalSupply()`/`underlyingBalance()` are exposed as informational views (per `IVirtualERC20`).
- **Freely transferable** standard ERC20 — the wrapper stays orthogonal to transfer-locking (`LockedUERC20`), which could be composed later.
- **Decimals are bound**: the constructor requires `decimals == underlying.decimals()` so 1:1 raw-unit redemption is 1:1 in value.

---

## 7. Security & audit implications (must-read)

- **Permissionless registry = no provenance guarantee.** Anyone can `register` arbitrary init-code, so "deployed by the factory" no longer implies "is a real UERC20." Indexers/UIs that trust factory provenance are exploitable. Mitigation: emit `initCodeHash` in `Registered`/`TokenCreated`; consumers allowlist known-good code hashes off-chain. (Optionally keep an on-chain set of blessed ids while still allowing arbitrary registration.)
- **Constructor re-entrancy.** Malicious init-code can re-enter `createToken` during construction and clobber transient `data`. Mitigation: `nonReentrant` on `createToken` (or accept and document nesting; transient storage alone is not enough since the inner call overwrites before the outer reads back).
- **Hand-rolled EIP-2612 / EIP-712 / Permit2 (re-expressed, not dropped).** We keep parity with Solady but now own `DOMAIN_SEPARATOR`, nonce handling, chain-id-on-fork recomputation, and the Permit2 default-allowance branch. This is the highest-risk area; it must be conformance-tested and fuzzed against a reference (e.g. OZ `ERC20Permit` + a Permit2 integration test) and ideally formally checked. The canonical Permit2 address (`0x000000000022D473030F116dDEE9F6B43aC78BA3`) must be `cast code`-verified before hardcoding.
- **Re-audit required.** All rewritten contracts invalidate the 06/17/2026 OpenZeppelin audit. Budget a fresh audit for v3.

---

## 8. Resolved decisions

1. **Salt/identity — full config hash.** `salt = keccak256(abi.encode(id, msg.sender, graffiti, keccak256(data)))`; the entire config participates in the address.
2. **CREATE2** (not CREATE3). Address = f(salt, initCodeHash-of-registered-code).
3. **Fully permissionless registration.** No on-chain blessed-id allowlist. Provenance is handled off-chain via the emitted `initCodeHash` (§7).
4. **This is a rewrite, not a parallel line.** Delete the old factories and token contracts; do not keep v2 alongside v3 for its own sake. **Preserve** the `UERC20Metadata` work (struct + `toJSON`) and **maintain feature parity** with today's `UERC20`/`USUPERC20` in the new model.
5. **New-feature specifics deferred.** Wrapper / receipt / fee-on-transfer / transfer-locked / permissioned details (caps, pausing, exact policy shapes) are decided *after* the core is built.
6. **Factory is a permanent generic singleton** via register-once SSTORE2 + CREATE2 (not EIP-5202). See §5a.

---

## 9. Phased execution

- **Phase 0** — Branch `feat/type-driven-v3`; confirm solc 0.8.28 + transient storage; scaffold dirs.
- **Phase 1** — Core types `Balances`/`Allowances`/`Supply`/`Token` + isolated unit tests.
- **Phase 2** — `Metadata` + `Permit` types + tests (port `toJSON`; hand-roll EIP-2612 with conformance vs OZ reference).
- **Phase 3** — `UERC20` base feature + `ERC20ConformanceTest` / `ERC2612ConformanceTest` harness; prove behavioral parity with current `UERC20`.
- **Phase 4** — `TokenFactory` + factory tests (deterministic address, re-entrancy, arbitrary init-code, transient clearing).
- **Phase 5** — Port `USUPERC20` onto the new model.
- **Phase 6** — New features one at a time (FeeOnTransfer → TransferLocked → Permissioned → Wrapper → Receipt), each: policy type + policy unit tests + feature inherits conformance + custom-logic tests.
- **Phase 7** — Invariant/fuzz suites, regenerate docs + gas snapshots, `slither`, `forge coverage`, prepare re-audit package.

---

## 10. Testing strategy (the "test basic ERC-20 for each feature" win)

- **Per-type unit tests** — every `types/` and `policies/` struct tested in isolation (the core type-driven payoff).
- **Conformance harnesses** — `abstract ERC20ConformanceTest` with a single `_deployToken()` hook holds all standard balance/allowance/transfer/transferFrom/approve assertions; `ERC2612ConformanceTest` covers permit (incl. Permit2 default allowance). Every feature's test inherits them → basic ERC-20/permit correctness is guaranteed for free.
- **Per-feature custom tests** — only the bespoke logic (fee math, lock enforcement, access checks, deposit/withdraw, mint auth).
- **Invariants** — `sum(balances) == totalSupply` (and per-feature invariants) under stateful fuzzing.
```
