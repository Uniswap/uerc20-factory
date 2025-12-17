# IUERC20Factory
[Git Source](https://github.com/Uniswap/token-factory/blob/e3cd6760dd10fd76e7f7442ef3c379f8aa87ea39/src/interfaces/IUERC20Factory.sol)

**Inherits:**
[ITokenFactory](/src/interfaces/ITokenFactory.sol/interface.ITokenFactory.md)

**Title:**
IUERC20Factory

Interface for the IUERC20Factory contract


## Functions
### getUERC20Address

Computes the deterministic address for a token based on its core parameters


```solidity
function getUERC20Address(
    string memory name,
    string memory symbol,
    uint8 decimals,
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


## Structs
### Parameters
Parameters struct to be used by the UERC20 during construction


```solidity
struct Parameters {
    uint256 totalSupply;
    bytes32 graffiti;
    address recipient;
    address creator;
    uint8 decimals;
    string name;
    string symbol;
    UERC20Metadata metadata;
}
```

