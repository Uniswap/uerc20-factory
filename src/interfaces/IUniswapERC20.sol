// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {UniswapERC20Metadata} from "../libraries/UniswapERC20Metadata.sol";

/// @title IUniswapERC20
/// @notice Interface for the UniswapERC20 contract
interface IUniswapERC20 {
    /// @notice Returns the home chain ID of the token
    function homeChainId() external view returns (uint256);

    /// @notice Returns the URI of the token metadata.
    function tokenURI() external view returns (string memory);
}
