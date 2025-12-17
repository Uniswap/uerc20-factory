# USUPERC20
[Git Source](https://github.com/Uniswap/token-factory/blob/e3cd6760dd10fd76e7f7442ef3c379f8aa87ea39/src/tokens/USUPERC20.sol)

**Inherits:**
[BaseUERC20](/src/tokens/BaseUERC20.sol/abstract.BaseUERC20.md), IERC7802

**Title:**
USUPERC20

ERC20 token contract that is Superchain interop compatible


## State Variables
### SUPERCHAIN_TOKEN_BRIDGE
The address of the Superchain Token Bridge (0x4200000000000000000000000000000000000028)


```solidity
address public constant SUPERCHAIN_TOKEN_BRIDGE = Predeploys.SUPERCHAIN_TOKEN_BRIDGE
```


### homeChainId
The chain where totalSupply is minted and metadata is stored


```solidity
uint256 public immutable homeChainId
```


## Functions
### constructor


```solidity
constructor() ;
```

### onlySuperchainTokenBridge

Reverts if the caller is not the Superchain Token Bridge


```solidity
modifier onlySuperchainTokenBridge() ;
```

### crosschainMint

Mint tokens through a crosschain transfer.


```solidity
function crosschainMint(address _to, uint256 _amount) external onlySuperchainTokenBridge;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_to`|`address`|    Address to mint tokens to.|
|`_amount`|`uint256`|Amount of tokens to mint.|


### crosschainBurn

Burn tokens through a crosschain transfer.


```solidity
function crosschainBurn(address _from, uint256 _amount) external onlySuperchainTokenBridge;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_from`|`address`|  Address to burn tokens from.|
|`_amount`|`uint256`|Amount of tokens to burn.|


### supportsInterface

Returns true if this contract implements the interface defined by
`interfaceId`. See the corresponding
https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[ERC section]
to learn more about how these ids are created.
This function call must use less than 30 000 gas.


```solidity
function supportsInterface(bytes4 _interfaceId) public view virtual override(BaseUERC20, IERC165) returns (bool);
```

## Errors
### NotSuperchainTokenBridge
Thrown when the caller is not the Superchain Token Bridge


```solidity
error NotSuperchainTokenBridge(address sender, address bridge);
```

### RecipientCannotBeZeroAddress
Thrown when the recipient is the zero address


```solidity
error RecipientCannotBeZeroAddress();
```

