# BaseUERC20
[Git Source](https://github.com/Uniswap/token-factory/blob/e3cd6760dd10fd76e7f7442ef3c379f8aa87ea39/src/tokens/BaseUERC20.sol)

**Inherits:**
ERC20, IERC165

**Title:**
BaseUERC20

ERC20 token contract

Uses solady for default permit2 approval

Implementing contract should initialise global variables and mint any initial supply


## State Variables
### _nameHash
Cached hash of the token name for gas-efficient EIP-712 operations.
This immutable value is computed once during construction and used by the
underlying ERC20 implementation for permit functionality.


```solidity
bytes32 internal immutable _nameHash
```


### graffiti

```solidity
bytes32 public immutable graffiti
```


### creator

```solidity
address public immutable creator
```


### _decimals

```solidity
uint8 internal immutable _decimals
```


### _name

```solidity
string internal _name
```


### _symbol

```solidity
string internal _symbol
```


### metadata

```solidity
UERC20Metadata public metadata
```


## Functions
### tokenURI

Returns the URI of the token metadata.


```solidity
function tokenURI() external view returns (string memory);
```

### name

Returns the name of the token.


```solidity
function name() public view override returns (string memory);
```

### symbol

Returns the symbol of the token.


```solidity
function symbol() public view override returns (string memory);
```

### decimals

Returns the decimals places of the token.


```solidity
function decimals() public view override returns (uint8);
```

### supportsInterface

Returns true if this contract implements the interface defined by
`interfaceId`. See the corresponding
https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[ERC section]
to learn more about how these ids are created.
This function call must use less than 30 000 gas.


```solidity
function supportsInterface(bytes4 _interfaceId) public view virtual returns (bool);
```

### _constantNameHash

For more performance, override to return the constant value
of `keccak256(bytes(name()))` if `name()` will never change.


```solidity
function _constantNameHash() internal view override returns (bytes32);
```

