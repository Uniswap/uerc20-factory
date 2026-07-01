// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Token} from "../types/Token.sol";
import {Lockup} from "../extensions/Lockup.sol";
import {ITokenFactory} from "../interfaces/ITokenFactory.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title LockedUERC20
/// @notice Transfer-restricted token. All transfers are blocked unless the owner has allowlisted
/// one of the parties, or the owner has unlocked transfers globally. The initial mint is exempt.
/// @dev A "guard" feature: it composes the base `Token` type plus a `Lockup` extension, gating only
/// `transfer`/`transferFrom`; the rest of the ERC20 surface delegates to the same shared free
/// functions. The contract owns access control (`onlyOwner`) and events; the extension owns state.
/// Deployed by a `TokenFactory` via the generic blueprint path — no factory change was needed to add it.
contract LockedUERC20 is IERC20 {
    /// @notice Token-defined config, ABI-encoded into the factory's `data` blob by the caller.
    struct Config {
        string name;
        string symbol;
        uint8 decimals;
        uint256 totalSupply;
        address recipient;
        address owner;
    }

    Token internal _token;
    Lockup internal _lockup;

    uint8 public immutable decimals;
    address public immutable creator;
    bytes32 public immutable graffiti;

    string public name;
    string public symbol;

    event Allowlisted(address indexed account, bool allowed);
    event Unlocked();
    event OwnerChanged(address indexed owner);

    error RecipientCannotBeZeroAddress();
    error TotalSupplyCannotBeZero();
    error OwnerCannotBeZeroAddress();
    error NotOwner(address caller);
    error TransferLocked(address from, address to);

    modifier onlyOwner() {
        if (msg.sender != _lockup.owner) revert NotOwner(msg.sender);
        _;
    }

    constructor() {
        ITokenFactory.DeploymentContext memory ctx = ITokenFactory(msg.sender).deployment();
        Config memory config = abi.decode(ctx.data, (Config));

        if (config.recipient == address(0)) revert RecipientCannotBeZeroAddress();
        if (config.totalSupply == 0) revert TotalSupplyCannotBeZero();
        if (config.owner == address(0)) revert OwnerCannotBeZeroAddress();

        name = config.name;
        symbol = config.symbol;
        decimals = config.decimals;
        creator = ctx.creator;
        graffiti = ctx.graffiti;

        _lockup.setOwner(config.owner);

        // Mint is not a transfer, so it is not gated by the lock.
        _token.mint(config.recipient, config.totalSupply);
        emit Transfer(address(0), config.recipient, config.totalSupply);
    }

    // -------------------------------------------------------------------------
    // Owner controls
    // -------------------------------------------------------------------------

    /// @notice Adds or removes `account` from the transfer allowlist.
    function allowlist(address account, bool allowed) external onlyOwner {
        _lockup.allowlist(account, allowed);
        emit Allowlisted(account, allowed);
    }

    /// @notice Unlocks transfers globally; all transfers are permitted thereafter.
    function unlock() external onlyOwner {
        _lockup.unlock();
        emit Unlocked();
    }

    /// @notice Transfers owner control to `newOwner`.
    function setOwner(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert OwnerCannotBeZeroAddress();
        _lockup.setOwner(newOwner);
        emit OwnerChanged(newOwner);
    }

    // -------------------------------------------------------------------------
    // Views
    // -------------------------------------------------------------------------

    function owner() external view returns (address) {
        return _lockup.owner;
    }

    function unlocked() external view returns (bool) {
        return _lockup.unlocked;
    }

    function isAllowlisted(address account) external view returns (bool) {
        return _lockup.isAllowlisted(account);
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
    function allowance(address owner_, address spender) external view returns (uint256) {
        return _token.allowanceOf(owner_, spender);
    }

    /// @inheritdoc IERC20
    function approve(address spender, uint256 amount) external returns (bool) {
        _token.approve(msg.sender, spender, amount);
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /// @inheritdoc IERC20
    function transfer(address to, uint256 amount) external returns (bool) {
        if (!_lockup.allowlisted(msg.sender, to)) revert TransferLocked(msg.sender, to);
        _token.transfer(msg.sender, to, amount);
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    /// @inheritdoc IERC20
    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        if (!_lockup.allowlisted(from, to)) revert TransferLocked(from, to);
        _token.transferFrom(msg.sender, from, to, amount);
        emit Transfer(from, to, amount);
        return true;
    }
}
