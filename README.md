# UniswapERC20 Factory

## Overview

Two main contracts:

- **UniswapERC20Factory**: A contract for deploying new ERC-20 tokens with additional metadata.
- **UniswapERC20**: An ERC-20 token implementing IERC7802, allowing seamless movement across chains within the Superchain interop cluster via the Superchain Token Bridge. It also includes additional metadata: creator, description, website, and image.

## UniswapERC20 Features

- Implements `IERC7802` for Superchain compatibility.
- Stores additional metadata:
  - **Creator** (required)
  - **Description** (optional)
  - **Website** (optional)
  - **Image** (optional)
- Description, website, and image are stored on the home chain only, so off-chain indexing is required to access them on other chains.
- Supports cross-chain transfers via the `SuperchainTokenBridge`, ensuring the total supply remains constant across all chains.

### Deployment Rules

- If deploying on the **home chain**, the caller must be the creator.
- The total supply is always minted on the home chain.
- A UniswapERC20 token can be deployed on any chain at the same address in a permissionless way. Tokens can move between chains via the Superchain Token Bridge, which adjusts totalSupply on each chain while ensuring the overall supply remains constant at the amount initially minted on the home chain.
- When deploying on a non-home chain, the following parameters can be empty for easier propagation.
  - Total Supply
  - Recipient
  - Description
  - Website
  - Image
- The token’s address is uniquely determined by its creator, name, symbol, decimals, and home chain ID.

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
forge test
```

### Formatting

```sh
forge fmt
```

