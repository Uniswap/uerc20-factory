# UERC20MetadataLibrary
[Git Source](https://github.com/Uniswap/token-factory/blob/e3cd6760dd10fd76e7f7442ef3c379f8aa87ea39/src/libraries/UERC20MetadataLibrary.sol)

**Title:**
UERC20MetadataLibrary

Library for generating base64 encoded JSON token metadata

If no fields are provided, returns an empty JSON object.


## Functions
### toJSON

Generates a base64 encoded JSON string of the token metadata


```solidity
function toJSON(UERC20Metadata memory metadata) internal pure returns (string memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`metadata`|`UERC20Metadata`|The token metadata|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`string`|The base64 encoded JSON string|


### displayMetadata

Generates an abi encoded JSON string of the token metadata


```solidity
function displayMetadata(UERC20Metadata memory metadata) private pure returns (bytes memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`metadata`|`UERC20Metadata`|The token metadata|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bytes`|The abi encoded JSON string|


