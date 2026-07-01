// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice Minimal interface for a virtual token that can be redeemed for an underlying ERC20.
/// @dev Matches Uniswap liquidity-launcher's `IVirtualERC20`: a token exposing the address of the
/// asset it wraps plus the standard ERC20 `transfer`, so integrators can treat it as a placeholder
/// for the underlying.
interface IVirtualERC20 is IERC20 {
    /// @notice The underlying ERC20 that holders can redeem this token for.
    // solhint-disable-next-line func-name-mixedcase
    function UNDERLYING_TOKEN_ADDRESS() external view returns (address);

    /// @notice The total supply of the underlying ERC20.
    function underlyingTotalSupply() external view returns (uint256);
}
