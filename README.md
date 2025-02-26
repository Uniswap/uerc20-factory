# Token Factory

## Overview

Two main contracts:

- **TokenFactory**: A contract for deploying new ERC-20 tokens with additional metadata.
- **Token**: An ERC-20 token implementing IERC7802, allowing seamless movement across chains within the Superchain interop cluster via the Superchain Token Bridge. It also includes additional metadata: creator, description, website, and image.

## Token Features

- Implements `IERC7802` for Superchain compatibility.
- Stores additional metadata:
  - **Creator** (required)
  - **Description** (optional)
  - **Website** (optional)
  - **Image** (optional)
- Supports cross-chain transfers via the `SuperchainTokenBridge`, ensuring the total supply remains constant across all chains.

## Token Creation

When deploying a new token, the following parameters must be provided:

- **Name**
- **Symbol**
- **Recipient** (address where `totalSupply` will be minted)
- **Total Supply**
- **Home Chain ID**
- **Decimals**
- **Creator**
- **Description** (optional)
- **Website** (optional)
- **Image** (optional)

### Deployment Rules

- If deploying on the **home chain**, the caller must be the creator.
- The total supply is always minted on the home chain.
- A token can be deployed on any chain at the same address in a permissionless way. Tokens can move between chains via the Superchain Token Bridge, which adjusts totalSupply on each chain while ensuring the overall supply remains constant at the amount initially minted on the home chain.

## Cross-Chain Transfers

- The `SuperchainTokenBridge` facilitates cross-chain transfers.
- **Mechanism:**
  - `crossChainBurn` is called on the source chain.
  - `crossChainMint` is called on the destination chain.
  - The total supply across all chains remains unchanged.

## Usage

### Compile and Run Tests

```sh
forge install
forge build
forge test --isolate
```

### Formatting

```sh
forge fmt
```

