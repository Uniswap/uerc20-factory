# Token Factory

## Overview

The project provides a flexible architecture for deploying ERC20 tokens with different functionality:

### Key Components

- **ITokenFactory**: Base interface for token factories
- **Factories**:
  - **UERC20Factory**: For deploying UERC20 tokens for Ethereum Mainnet usage
  - **UERC20SuperchainFactory**: For deploying UERC20Superchain tokens that work across the Superchain ecosystem

- **BaseUERC20**: Abstract base token implementation with common functionality
- **Token Implementations**:
  - **UERC20**: Standard ERC-20 tokens for Ethereum Mainnet usage
  - **UERC20Superchain**: ERC-20 tokens implementing IERC7802 for Superchain compatibility

## Token Features

### Common Features (BaseUERC20)
- Stores additional metadata:
  - **Creator** (required)
  - **Description** (optional)
  - **Website** (optional)
  - **Image** (optional)

### UERC20 (Ethereum Mainnet)
- Standard ERC-20 implementation for Ethereum Mainnet usage
- Includes all BaseUERC20 metadata features

### UERC20Superchain (Superchain)
- Implements `IERC7802` for Superchain compatibility
- Supports cross-chain transfers via the `SuperchainTokenBridge`
- Ensures the total supply remains constant across all chains
- Metadata (creator, description, website, and image) is stored on the home chain only, so off-chain indexing is required to access them on other chains

## Deployment Rules

### UERC20 (Ethereum Mainnet)
- The caller must be the creator
- The total supply is minted at deployment time
- The token's address is uniquely determined by its creator, name, symbol, and decimals

### UERC20Superchain (Superchain)
- If deploying on the **home chain**, the caller must be the creator
- The total supply is always minted on the home chain at deployment time
- A UERC20Superchain token can be deployed on any chain at the same address in a permissionless way
- Tokens can move between chains via the Superchain Token Bridge
- The token's address is uniquely determined by its creator, name, symbol, decimals, and home chain ID

## Cross-Chain Transfers (UERC20Superchain)

- The `SuperchainTokenBridge` facilitates cross-chain transfers
- **Mechanism:**
  - `crossChainBurn` is called on the source chain, decreasing its local `totalSupply`
  - `crossChainMint` is called on the destination chain, increasing its local `totalSupply`
  - While the `totalSupply` variable changes on individual chains, the aggregate total supply across all chains remains unchanged at the amount initially minted on the home chain

## Extensibility

The architecture is designed to be extensible by allowing new token factories to inherit from the base ITokenFactory interface. This enables developers to create specialized implementations with custom functionality while maintaining a consistent interface for token creation.

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

