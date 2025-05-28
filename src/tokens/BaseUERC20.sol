// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {UERC20Metadata, UERC20MetadataLibrary} from "../libraries/UERC20MetadataLibrary.sol";
import {IUERC20Factory} from "../interfaces/IUERC20Factory.sol";
import {ERC20} from "@solady/src/tokens/ERC20.sol";

/// @title BaseUERC20
/// @notice ERC20 token contract
/// @dev Uses solady for default permit2 approval
/// @dev Implementing contract should initialise global variables and mint any initial supply
abstract contract BaseUERC20 is ERC20 {
    using UERC20MetadataLibrary for UERC20Metadata;

    /// @dev Cached hash of the token name for gas-efficient EIP-712 operations.
    /// This immutable value is computed once during construction and used by the
    /// underlying ERC20 implementation for permit functionality.
    bytes32 internal immutable _nameHash;

    // Core parameters that define token identity
    uint8 internal immutable _decimals;
    string internal _name;
    string internal _symbol;
    // Metadata that may have extended information
    UERC20Metadata public metadata;

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

    function _constantNameHash() internal view override returns (bytes32) {
        return _nameHash;
    }
}
