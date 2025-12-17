# USUPERC20Factory
[Git Source](https://github.com/Uniswap/token-factory/blob/e3cd6760dd10fd76e7f7442ef3c379f8aa87ea39/src/factories/USUPERC20Factory.sol)

**Inherits:**
[IUSUPERC20Factory](/src/interfaces/IUSUPERC20Factory.sol/interface.IUSUPERC20Factory.md)

**Title:**
USUPERC20Factory

Deploys new USUPERC20 contracts


## State Variables
### parameters
Parameters stored transiently for token initialization


```solidity
Parameters private parameters
```


## Functions
### getUSUPERC20Address

Computes the deterministic address for a token based on its core parameters


```solidity
function getUSUPERC20Address(
    string memory name,
    string memory symbol,
    uint8 decimals,
    uint256 homeChainId,
    address creator,
    bytes32 graffiti
) external view returns (address);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`name`|`string`|The name of the token|
|`symbol`|`string`|The symbol of the token|
|`decimals`|`uint8`|The number of decimals the token uses|
|`homeChainId`|`uint256`|The hub chain ID of the token|
|`creator`|`address`|The creator of the token|
|`graffiti`|`bytes32`|Additional data needed to compute the salt|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|The deterministic address of the token|


### getParameters

Gets the parameters for token initialization


```solidity
function getParameters() external view returns (Parameters memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`Parameters`|The parameters structure with all token initialization data|


### createToken

Creates a new token contract


```solidity
function createToken(
    string memory name,
    string memory symbol,
    uint8 decimals,
    uint256 totalSupply,
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
|`totalSupply`|`uint256`||
|`recipient`|`address`|    The recipient of the initial supply.|
|`data`|`bytes`|         Additional factory-specific data required for token creation.|
|`graffiti`|`bytes32`|     Additional data to be included in the token's salt|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`tokenAddress`|`address`|The address of the newly created token.|


