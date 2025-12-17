# ITokenFactory
[Git Source](https://github.com/Uniswap/token-factory/blob/e3cd6760dd10fd76e7f7442ef3c379f8aa87ea39/src/interfaces/ITokenFactory.sol)

**Title:**
ITokenFactory

Generic interface for a token factory.


## Functions
### createToken

Creates a new token contract


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
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`name`|`string`|         The ERC20-style name of the token.|
|`symbol`|`string`|       The ERC20-style symbol of the token.|
|`decimals`|`uint8`|     The number of decimal places for the token.|
|`initialSupply`|`uint256`|The initial supply to mint upon creation.|
|`recipient`|`address`|    The recipient of the initial supply.|
|`data`|`bytes`|         Additional factory-specific data required for token creation.|
|`graffiti`|`bytes32`|     Additional data to be included in the token's salt|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`tokenAddress`|`address`|The address of the newly created token.|


## Events
### TokenCreated
Emitted when a new token is created


```solidity
event TokenCreated(address tokenAddress);
```

## Errors
### RecipientCannotBeZeroAddress
Thrown when the recipient is the zero address


```solidity
error RecipientCannotBeZeroAddress();
```

### TotalSupplyCannotBeZero
Thrown when the initial supply is zero


```solidity
error TotalSupplyCannotBeZero();
```

