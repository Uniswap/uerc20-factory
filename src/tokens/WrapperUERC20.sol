// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Token} from "../types/Token.sol";
import {Metadata} from "../types/Metadata.sol";
import {Permit} from "../types/Permit.sol";
import {UERC20Config, RecipientCannotBeZeroAddress} from "../types/UERC20Config.sol";
import {IUERC20} from "../interfaces/IUERC20.sol";
import {IVirtualERC20} from "../interfaces/IVirtualERC20.sol";
import {ITokenFactory} from "../interfaces/ITokenFactory.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title WrapperUERC20
/// @notice A virtual token redeemable 1:1 for an underlying ERC20. The full supply is minted upfront
/// and the token is freely transferable; anyone can `redeem` by burning their balance to pull the
/// underlying out. Redemption is first-come-first-served — it succeeds while the contract holds
/// enough underlying and reverts otherwise, so the contract need not be fully collateralized to open.
/// Composes the `Token`, `Metadata`, and `Permit` types plus an immutable underlying; the standard
/// ERC20 surface is unchanged and delegates to the free functions, with redemption added on top.
contract WrapperUERC20 is IUERC20, IVirtualERC20 {
    using SafeERC20 for IERC20;

    /// @notice Config: the shared base plus the underlying this token redeems for.
    struct Config {
        UERC20Config base;
        address underlying;
    }

    Token internal _token;
    Permit internal _permit;

    /// @notice The underlying ERC20 this token redeems for (see {UNDERLYING_TOKEN_ADDRESS}).
    address internal immutable underlying;

    /// @inheritdoc IERC20Metadata
    uint8 public immutable decimals;
    /// @inheritdoc IUERC20
    address public immutable creator;
    /// @inheritdoc IUERC20
    bytes32 public immutable graffiti;

    /// @inheritdoc IERC20Metadata
    string public name;
    /// @inheritdoc IERC20Metadata
    string public symbol;
    /// @inheritdoc IUERC20
    Metadata public metadata;

    /// @notice Emitted when `amount` tokens are burned by `from` and the underlying is sent to `to`.
    event Redeemed(address indexed from, address indexed to, uint256 amount);

    error UnderlyingCannotBeZeroAddress();
    error DecimalsMismatch(uint8 expected, uint8 actual);
    error RedeemAmountCannotBeZero();

    constructor() {
        ITokenFactory.DeploymentContext memory ctx = ITokenFactory(msg.sender).deployment();
        Config memory config = abi.decode(ctx.data, (Config));
        UERC20Config memory base = config.base;

        if (config.underlying == address(0)) revert UnderlyingCannotBeZeroAddress();

        // 1:1 raw-unit redemption is only 1:1 in value when the decimals match, so bind them.
        uint8 underlyingDecimals = IERC20Metadata(config.underlying).decimals();
        if (base.decimals != underlyingDecimals) revert DecimalsMismatch(base.decimals, underlyingDecimals);

        // Shared validation, permit-domain caching, and initial mint (+ Transfer event).
        base.initBase(_token, _permit, address(this));
        underlying = config.underlying;

        name = base.name;
        symbol = base.symbol;
        decimals = base.decimals;
        metadata = base.metadata;
        creator = ctx.creator;
        graffiti = ctx.graffiti;
    }

    /// @notice Redeems `amount` of the caller's tokens for the underlying, sent to the caller.
    function redeem(uint256 amount) external {
        _redeem(msg.sender, msg.sender, amount);
    }

    /// @notice Redeems `amount` of the caller's tokens for the underlying, sent to `to`.
    function redeem(address to, uint256 amount) external {
        _redeem(msg.sender, to, amount);
    }

    /// @notice Redeems `amount` of `from`'s tokens for the underlying sent to `to`, spending the
    /// caller's allowance over `from` (mirroring `transferFrom`).
    function redeemFrom(address from, address to, uint256 amount) external {
        _token.spendAllowance(from, msg.sender, amount);
        _redeem(from, to, amount);
    }

    /// @inheritdoc IVirtualERC20
    function UNDERLYING_TOKEN_ADDRESS() external view returns (address) {
        return underlying;
    }

    /// @inheritdoc IVirtualERC20
    function underlyingTotalSupply() external view returns (uint256) {
        return IERC20(underlying).totalSupply();
    }

    /// @notice Underlying balance held by this contract, available for redemption.
    function underlyingBalance() external view returns (uint256) {
        return IERC20(underlying).balanceOf(address(this));
    }

    /// @inheritdoc IUERC20
    function tokenURI() external view returns (string memory) {
        return metadata.toJSON();
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return interfaceId == type(IERC165).interfaceId || interfaceId == type(IERC20).interfaceId
            || interfaceId == type(IERC20Metadata).interfaceId || interfaceId == type(IERC20Permit).interfaceId
            || interfaceId == type(IVirtualERC20).interfaceId;
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

    /// @inheritdoc IERC20Permit
    function nonces(address owner) external view returns (uint256) {
        return _permit.nonces[owner];
    }

    /// @inheritdoc IERC20Permit
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _permit.domainSeparator();
    }

    /// @inheritdoc IERC20
    function approve(address spender, uint256 amount) external returns (bool) {
        _token.approve(msg.sender, spender, amount);
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /// @inheritdoc IERC20Permit
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external
    {
        _permit.verify(owner, spender, value, deadline, v, r, s);
        _token.approve(owner, spender, value);
        emit Approval(owner, spender, value);
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

    /// @notice Burns `amount` from `from` and sends an equal amount of the underlying to `to`.
    /// @dev Checks-effects-interactions: burn (and emit) before the external token transfer. Reverts
    /// if the contract holds too little underlying, so redemption is first-come-first-served.
    function _redeem(address from, address to, uint256 amount) internal {
        if (amount == 0) revert RedeemAmountCannotBeZero();
        if (to == address(0)) revert RecipientCannotBeZeroAddress();

        _token.burn(from, amount);
        emit Transfer(from, address(0), amount);
        emit Redeemed(from, to, amount);

        IERC20(underlying).safeTransfer(to, amount);
    }
}
