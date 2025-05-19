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

    // Core parameters that define token identity
    uint8 internal immutable _decimals;
    string internal _name;
    string internal _symbol;

    // Metadata that may have extended information
    UERC20Metadata public metadata;
    address public creator;

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
}
