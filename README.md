# UERC20

Smart contracts for deploying ERC-20 tokens through a single, generic factory. Tokens are built with a type-driven design: shared, independently tested building blocks are composed into standalone token contracts, rather than assembled through deep contract inheritance.

## Table of Contents

- [Overview](#overview)
- [Design](#design)
- [Architecture](#architecture)
- [Usage](#usage)
- [Building a new token type](#building-a-new-token-type)
- [Installation](#installation)
- [Repository Structure](#repository-structure)
- [License](#license)

## Overview

A single `TokenFactory` deploys every token type. A token implementation's creation code is registered once as a blueprint; tokens are then deployed by blueprint `id` using CREATE2, so each token's address is deterministic and can be computed before deployment. The factory is generic — it passes an opaque, token-defined config blob that the token decodes itself — so new token types are added by registration alone, without changing or redeploying the factory.

The repository ships:

- `UERC20`: a standard ERC-20 with EIP-2612 permit, a default infinite allowance to Permit2, token metadata, ERC-165 interface detection, and creator attribution.
- `LockedUERC20`: a transfer-restricted ERC-20 whose transfers are blocked unless an owner allowlists a party (as sender or recipient) or unlocks transfers globally.

Token metadata includes an optional description, website, image, and a generic `extraData` field. `extraData` is opaque, application-defined data stored on-chain; it is not included in the rendered `tokenURI` JSON.

## Design

Token behavior is expressed as small value types with attached functions — balances, allowances, supply, and metadata — plus optional behavioral extensions (for example, a transfer-restriction policy). Each token is a **standalone contract** that wires a thin, fully explicit ABI surface to these shared types.

This approach is deliberate:

- **Transparency.** A token's complete behavior is visible in its own source. There is no inherited logic hidden in parent contracts and no override resolution to reason about.
- **Reuse without inheritance.** The same building blocks are shared across token types by composition, not by extending a base contract, avoiding deep inheritance hierarchies.
- **Testability.** Each type is unit-tested in isolation, and every token reuses a shared ERC-20 conformance suite, so standard behavior is verified uniformly while token-specific logic is tested on its own.
- **Extensibility.** New token types compose the existing types in a new contract and register its creation code with the factory. The factory and existing tokens are untouched.

## Architecture

- **Types** (`src/types`) — composable state with attached free functions: `Balances`, `Allowances`, `Token` (supply + ledgers), and `Metadata`. `UERC20Config` is the shared base configuration every token accepts.
- **Extensions** (`src/extensions`) — optional behavioral policies a token can compose, such as `Lockup` (transfer restrictions).
- **Tokens** (`src/tokens`) — standalone contracts implementing `IUERC20`, each composing the types (and any extension) it needs.
- **Factory** (`src/factories/TokenFactory.sol`) — the generic blueprint registry and deployer.
- **Interfaces** (`src/interfaces`) — `IUERC20` (the common token ABI: ERC-20 + metadata + `tokenURI` + creator attribution) and `ITokenFactory`.

## Usage

Deploying a token is two steps: register a token implementation's creation code once, then deploy instances by `id`.

```solidity
// 1. Register a token implementation (once per implementation).
uint256 id = factory.register(type(UERC20).creationCode);

// 2. Encode the token's config and deploy. Callers build the config with named
//    struct literals, so fields cannot be mis-ordered.
bytes memory data = abi.encode(
    UERC20Config({
        name: "Example",
        symbol: "EXMPL",
        decimals: 18,
        totalSupply: 1_000_000e18,
        recipient: recipient,
        metadata: Metadata({description: "", website: "", image: "", extraData: ""})
    })
);

address token = factory.createToken(id, data, graffiti);
```

The token address is derived from the blueprint `id`, the caller, the `graffiti`, and the config, and can be predicted before deployment:

```solidity
address predicted = factory.getAddress(id, caller, graffiti, keccak256(data));
```

During construction the token reads its config back from the factory via `deployment()` and decodes it. The `Registered` and `TokenCreated` events include the implementation's `initCodeHash`, which integrators can use to recognize known token implementations off-chain.

A token that nests the base config (such as `LockedUERC20`) is deployed the same way, with its own config type:

```solidity
bytes memory data = abi.encode(
    LockedUERC20.Config({base: baseConfig, owner: owner})
);
```

## Building a new token type

A new token type is a standalone contract that:

1. implements `IUERC20`;
2. composes the shared `Token` type (and `Metadata`, and any extension) it needs, wiring each external function to the underlying free functions;
3. reads its config from the factory in its constructor (`ITokenFactory(msg.sender).deployment()`) and decodes its own config struct — nesting `UERC20Config` for the shared fields.

Its creation code is then registered with the factory (`register(type(NewToken).creationCode)`) and deployed by `id`. Because the factory only handles opaque config, no factory change is required. Reusing the shared ERC-20 conformance suite gives standard-behavior coverage for free; only the token-specific logic needs new tests.

## Installation

```bash
forge install
forge build
forge test
```

To format Solidity files:

```bash
forge fmt
```

## Repository Structure

Contracts are in `src/`, tests in `test/`, and gas snapshots in `snapshots/`.

```markdown
src/
----factories/
| TokenFactory.sol
----interfaces/
| ITokenFactory.sol
| IUERC20.sol
----types/
| Balances.sol
| Allowances.sol
| Token.sol
| Metadata.sol
| UERC20Config.sol
----extensions/
| Lockup.sol
----tokens/
| UERC20.sol
| LockedUERC20.sol
test/
----types/
----extensions/
----conformance/
----tokens/
----factories/
```

## License

The contracts are covered under the MIT License (`MIT`), see [LICENSE](./LICENSE).
