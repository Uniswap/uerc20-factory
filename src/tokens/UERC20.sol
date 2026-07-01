// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Token} from "../types/Token.sol";
import {ITokenFactory} from "../interfaces/ITokenFactory.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title UERC20
/// @notice Base fungible token. A thin, fully-explicit ABI surface that wires the standard ERC20
/// interface to the composed `Token` type — no inheritance of behavior, all logic visible here.
/// @dev Deployed by a `TokenFactory`: the no-arg constructor reads its config back from the factory
/// via `deployment()` and decodes its own `Config`, so the factory stays generic.
/// SLICE SCOPE: EIP-2612 permit, Permit2 signature flow, ERC-165, and metadata/tokenURI are still
/// deferred to a later increment.
contract UERC20 is IERC20 {
    /// @notice Token-defined config, ABI-encoded into the factory's `data` blob by the caller.
    struct Config {
        string name;
        string symbol;
        uint8 decimals;
        uint256 totalSupply;
        address recipient;
    }

    /// @dev The full token state (supply + balance/allowance ledgers), composed rather than inherited.
    Token internal _token;

    uint8 public immutable decimals;
    address public immutable creator;
    bytes32 public immutable graffiti;

    string public name;
    string public symbol;

    error RecipientCannotBeZeroAddress();
    error TotalSupplyCannotBeZero();

    constructor() {
        ITokenFactory.DeploymentContext memory ctx = ITokenFactory(msg.sender).deployment();
        Config memory config = abi.decode(ctx.data, (Config));

        if (config.recipient == address(0)) revert RecipientCannotBeZeroAddress();
        if (config.totalSupply == 0) revert TotalSupplyCannotBeZero();

        name = config.name;
        symbol = config.symbol;
        decimals = config.decimals;
        creator = ctx.creator;
        graffiti = ctx.graffiti;

        _token.mint(config.recipient, config.totalSupply);
        emit Transfer(address(0), config.recipient, config.totalSupply);
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
