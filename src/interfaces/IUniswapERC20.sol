// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {UniswapERC20Metadata} from "../libraries/UniswapERC20Metadata.sol";
import {IERC7802} from "@optimism/interfaces/L2/IERC7802.sol";

/// @title IUniswapERC20
/// @notice Interface for the UniswapERC20 contract
interface IUniswapERC20 is IERC7802 {
    /// @notice Returns the home chain ID of the token
    function homeChainId() external view returns (uint256);

    /// @notice Returns the metadata of the token which includes creator, description, website, and image
    function metadata() external view returns (UniswapERC20Metadata memory);

    /// @notice Returns the URI of the token metadata.
    function tokenURI() external view returns (string memory);

    /// @notice Returns the name of the token.
    function name() external view returns (string memory);

    /// @notice Returns the symbol of the token.
    function symbol() external view returns (string memory);

    /// @notice Returns the decimals places of the token.
    function decimals() external view returns (uint8);
}
