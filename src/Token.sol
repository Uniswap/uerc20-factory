// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {SuperchainERC20} from "./base/SuperchainERC20.sol";
import {TokenMetadata, TokenMetadataLibrary} from "./libraries/TokenMetadata.sol";
import {TokenFactory} from "./TokenFactory.sol";

/// @title Token
/// @notice ERC20 token contract that is Superchain compatible
/// @dev Uses solady for default permit2 approval
contract Token is SuperchainERC20 {
    using TokenMetadataLibrary for TokenMetadata;

    // Core parameters that define token identity
    string private _name;
    string private _symbol;
    uint8 private immutable _decimals;

    // Metadata that may have extended information
    TokenMetadata private _metadata;

    constructor() {
        // Get parameters from the factory that deployed this token
        TokenFactory.Parameters memory params = TokenFactory(msg.sender).getParameters();

        _name = params.name;
        _symbol = params.symbol;
        _decimals = params.decimals;
        _metadata = params.metadata;

        // Mint tokens only on the home chain to ensure the total supply remains consistent across all chains
        if (block.chainid == params.homeChainId) {
            _mint(params.recipient, params.totalSupply);
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
