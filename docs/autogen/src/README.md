# Token Factory

## Overview

The project provides a flexible architecture for deploying ERC20 tokens with different functionality:

### Key Components

- **ITokenFactory**: Base interface for token factories
- **Interfaces**:
  - **IUERC20Factory**: Interface for deploying UERC20 tokens for Ethereum Mainnet usage
  - **IUERC20SuperchainFactory**: Interface for deploying UERC20Superchain tokens that work across the Superchain ecosystem
- **Factories**:
  - **UERC20Factory**: For deploying UERC20 tokens for Ethereum Mainnet usage
  - **UERC20SuperchainFactory**: For deploying UERC20Superchain tokens that work across the Superchain ecosystem
- **Libraries**:

  - **UERC20MetadataLibrary**: Handles encoding of token metadata to JSON format

- **BaseUERC20**: Abstract base token implementation with common functionality
- **Token Implementations**:
  - **UERC20**: Standard ERC-20 tokens for Ethereum Mainnet usage
  - **UERC20Superchain**: ERC-20 tokens implementing IERC7802 for Superchain compatibility

## Token Features

### Common Features (BaseUERC20)

- Standard ERC-20 functionality with EIP-2612 permit support via Solady
- ERC-165 interface support for IERC20, IERC20Permit, and IERC165
- Stores creator address and graffiti (additional data for salt generation)
- Stores optional metadata:
  - **Description**
  - **Website**
  - **Image**
- **tokenURI()**: Returns base64-encoded JSON metadata

### UERC20 (Ethereum Mainnet)

- Standard ERC-20 implementation for Ethereum Mainnet usage
- Includes all BaseUERC20 metadata features
- Simple constructor that gets parameters from factory during deployment

### UERC20Superchain (Superchain)

- Implements `IERC7802` for Superchain compatibility
- Supports cross-chain transfers via the `SuperchainTokenBridge` (0x4200000000000000000000000000000000000028)
- **Home Chain**: The chain where totalSupply is initially minted and metadata is stored
- Ensures the total supply remains constant across all chains
- Metadata (creator, description, website, and image) is stored on the home chain only, so off-chain indexing is required to access them on other chains
- Only mints initial supply when deployed on the home chain

## Deployment Rules

### UERC20 (Ethereum Mainnet)

- The caller (msg.sender) becomes the creator
- The total supply is minted to the specified recipient at deployment time
- The token's address is uniquely determined by its creator, name, symbol, decimals, and graffiti
- **Required validations**:
  - Recipient cannot be zero address
  - Initial supply cannot be zero

### UERC20Superchain (Superchain)

- **On the home chain**: Only the specified creator can deploy the token
- **On other chains**: Anyone can deploy the token permissionlessly at the same address
- The total supply is always minted on the home chain at deployment time
- A UERC20Superchain token can be deployed on any chain at the same address in a permissionless way
- Tokens can move between chains via the Superchain Token Bridge
- The token's address is uniquely determined by its creator, name, symbol, decimals, home chain ID, and graffiti
- **Required validations (home chain only)**:
  - Caller must be the creator
  - Recipient cannot be zero address
  - Initial supply cannot be zero

## Cross-Chain Transfers (UERC20Superchain)

- The `SuperchainTokenBridge` facilitates cross-chain transfers
- **Mechanism:**
  - `crosschainBurn` is called on the source chain, decreasing its local `totalSupply`
  - `crosschainMint` is called on the destination chain, increasing its local `totalSupply`
  - While the `totalSupply` variable changes on individual chains, the aggregate total supply across all chains remains unchanged at the amount initially minted on the home chain
- Both functions are restricted to the SuperchainTokenBridge and emit appropriate events

## Factory Interface

All factories implement the base `ITokenFactory` interface with a common `createToken` function:

```solidity
function createToken(
    string calldata name,
    string calldata symbol,
    uint8 decimals,
    uint256 initialSupply,
    address recipient,
    bytes calldata data,
    bytes32 graffiti
) external returns (address tokenAddress);
```

- **data**: Factory-specific encoded data
  - UERC20Factory: `abi.encode(UERC20Metadata)`
  - UERC20SuperchainFactory: `abi.encode(homeChainId, creator, UERC20Metadata)`
- **graffiti**: Additional data for salt generation to enable address customization

## Extensibility

The architecture is designed to be extensible by allowing new token factories to inherit from the base ITokenFactory interface. This enables developers to create specialized implementations with custom functionality while maintaining a consistent interface for token creation.

## License

MIT

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

## Deployment Addresses

### UERC20Factory

| Network | Address                                    | Commit Hash                              |
| ------- | ------------------------------------------ | ---------------------------------------- |
| Mainnet | 0x0cde87c11b959e5eb0924c1abf5250ee3f9bd1b5 | 9705debfea9e6a641bc04352398f9e549055ac44 |
| Sepolia | 0x0cde87c11b959e5eb0924c1abf5250ee3f9bd1b5 | 9705debfea9e6a641bc04352398f9e549055ac44 |

### USUPERC20Factory

| Network          | Address                                    | Commit Hash                              |
| ---------------- | ------------------------------------------ | ---------------------------------------- |
| Unichain         | 0x24016ed99a69e9b86d16d84351e1661266b7ac6a | 9705debfea9e6a641bc04352398f9e549055ac44 |
| Unichain Sepolia | 0x24016ed99a69e9b86d16d84351e1661266b7ac6a | 9705debfea9e6a641bc04352398f9e549055ac44 |

## Audits

- 3/14 [OpenZeppelin](./docs/The%20Uniswap%20ERC-20%20Token%20Factory%20Audit.pdf)
- 6/3 [OpenZeppelin](./docs/UERC20%20Factory%20Separation%20Diff%20Audit.pdf)
