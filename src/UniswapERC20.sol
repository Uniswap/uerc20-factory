// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {SuperchainERC20} from "./base/SuperchainERC20.sol";
import {UniswapERC20Metadata, UniswapERC20MetadataLibrary} from "./libraries/UniswapERC20Metadata.sol";

/// @title UniswapERC20
/// @notice ERC20 token contract that is Superchain interop compatible
/// @dev Uses solady for default permit2 approval
contract UniswapERC20 is SuperchainERC20 {
    using UniswapERC20MetadataLibrary for UniswapERC20Metadata;

    UniswapERC20Metadata private _metadata;
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint8 _tokenDecimals,
        address _recipient,
        uint256 _totalSupply,
        uint256 _homeChainId,
        UniswapERC20Metadata memory _tokenMetadata
    ) {
        _name = _tokenName;
        _symbol = _tokenSymbol;
        _decimals = _tokenDecimals;
        _metadata = _tokenMetadata;
        // Mint tokens only on the home chain to ensure the total supply remains consistent across all chains
        if (block.chainid == _homeChainId) {
            _mint(_recipient, _totalSupply);
        }
    }

    /// @dev Returns the name of the token.
    function name() public view override returns (string memory) {
        return _name;
    }

    /// @dev Returns the symbol of the token.
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /// @dev Returns the decimals places of the token.
    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    /// @dev Returns the URI of the token metadata.
    function tokenURI() public view returns (string memory) {
        return _metadata.toJSON();
    }
}
