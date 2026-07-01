// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Token} from "../types/Token.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title UERC20
/// @notice Base fungible token. A thin, fully-explicit ABI surface that wires the standard ERC20
/// interface to the composed `Token` type — no inheritance of behavior, all logic visible here.
/// @dev SLICE SCOPE: EIP-2612 permit, Permit2 signature flow, ERC-165, metadata/tokenURI, and the
/// factory `initData()` construction callback are intentionally deferred to the next increment.
/// The constructor takes explicit params here so the type-driven wiring can be tested in isolation.
contract UERC20 is IERC20 {
    /// @dev The full token state (supply + balance/allowance ledgers), composed rather than inherited.
    Token internal _token;

    uint8 public immutable decimals;
    address public immutable creator;
    bytes32 public immutable graffiti;

    string public name;
    string public symbol;

    error RecipientCannotBeZeroAddress();
    error TotalSupplyCannotBeZero();

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 totalSupply_,
        address recipient,
        address creator_,
        bytes32 graffiti_
    ) {
        if (recipient == address(0)) revert RecipientCannotBeZeroAddress();
        if (totalSupply_ == 0) revert TotalSupplyCannotBeZero();

        name = name_;
        symbol = symbol_;
        decimals = decimals_;
        creator = creator_;
        graffiti = graffiti_;

        _token.mint(recipient, totalSupply_);
        emit Transfer(address(0), recipient, totalSupply_);
    }

    /// @inheritdoc IERC20
    function totalSupply() external view returns (uint256) {
        return _token.totalSupply();
    }

    /// @inheritdoc IERC20
    function balanceOf(address account) external view returns (uint256) {
        return _token.balanceOf(account);
    }

    /// @inheritdoc IERC20
    function allowance(address owner, address spender) external view returns (uint256) {
        return _token.allowanceOf(owner, spender);
    }

    /// @inheritdoc IERC20
    function approve(address spender, uint256 amount) external returns (bool) {
        _token.approve(msg.sender, spender, amount);
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /// @inheritdoc IERC20
    function transfer(address to, uint256 amount) external returns (bool) {
        _token.transfer(msg.sender, to, amount);
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    /// @inheritdoc IERC20
    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        _token.transferFrom(msg.sender, from, to, amount);
        emit Transfer(from, to, amount);
        return true;
    }
}
