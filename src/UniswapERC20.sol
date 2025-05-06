// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {UniswapERC20Metadata, UniswapERC20MetadataLibrary} from "./libraries/UniswapERC20Metadata.sol";
import {IUniswapERC20Factory} from "./interfaces/IUniswapERC20Factory.sol";

/// @title UniswapERC20
/// @notice ERC20 token contract
/// @dev Uses solady for default permit2 approval
contract UniswapERC20 {
    using UniswapERC20MetadataLibrary for UniswapERC20Metadata;

    // Core parameters that define token identity
    uint8 private immutable _decimals;
    string private _name;
    string private _symbol;

    // Metadata that may have extended information
    UniswapERC20Metadata public metadata;

    constructor() {
        // Get constructor parameters from factory, and process them
        _fetchAndProcessParameters();
    }

    /// @notice Returns the URI of the token metadata.
    function tokenURI() external view returns (string memory) {
        return metadata.toJSON();
    }

    /// @notice Returns the name of the token.
    function name() public view override returns (string memory) {
        return _name;
    }

    /// @notice Returns the symbol of the token.
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /// @notice Returns the decimals places of the token.
    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function _fetchAndProcessParameters() internal override {
        IUniswapERC20Factory.Parameters memory params = IUniswapERC20Factory(msg.sender).getParameters();

        _name = params.name;
        _symbol = params.symbol;
        _decimals = params.decimals;
        _metadata = params.metadata;

        _mint(params.recipient, params.totalSupply);
    }
}
