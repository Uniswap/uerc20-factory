// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Token} from "../types/Token.sol";
import {Metadata} from "../types/Metadata.sol";
import {Permit} from "../types/Permit.sol";
import {UERC20Config} from "../types/UERC20Config.sol";
import {Lockup} from "../extensions/Lockup.sol";
import {IUERC20} from "../interfaces/IUERC20.sol";
import {ITokenFactory} from "../interfaces/ITokenFactory.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/// @title LockedUERC20
/// @notice UERC20 whose transfers are blocked unless the owner allowlists a party (as sender or
/// recipient) or unlocks transfers globally. The initial mint is exempt. Composes the `Token`,
/// `Metadata`, `Permit`, and `Lockup` types; the transfer path is gated, the rest wires unchanged.
contract LockedUERC20 is IUERC20 {
    /// @notice Config: the shared base plus this token's owner.
    struct Config {
        UERC20Config base;
        address owner;
    }

    Token internal _token;
    Permit internal _permit;
    Lockup internal _lockup;

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
        UERC20Config memory base = config.base;

        if (base.recipient == address(0)) revert RecipientCannotBeZeroAddress();
        if (base.totalSupply == 0) revert TotalSupplyCannotBeZero();
        if (config.owner == address(0)) revert OwnerCannotBeZeroAddress();

        name = base.name;
        symbol = base.symbol;
        decimals = base.decimals;
        metadata = base.metadata;
        creator = ctx.creator;
        graffiti = ctx.graffiti;

        _permit.init(base.name, address(this));
        _lockup.setOwner(config.owner);

        // Mint is not a transfer, so it is not gated by the lock.
        _token.mint(base.recipient, base.totalSupply);
        emit Transfer(address(0), base.recipient, base.totalSupply);
    }

    /// @notice Adds or removes `account` from the transfer allowlist.
    function allowlist(address account, bool allowed) external onlyOwner {
        _lockup.allowlist(account, allowed);
        emit Allowlisted(account, allowed);
    }

    /// @notice Unlocks transfers globally.
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

    /// @notice The owner permitted to manage the lock.
    function owner() external view returns (address) {
        return _lockup.owner;
    }

    /// @notice Whether transfers have been unlocked globally.
    function unlocked() external view returns (bool) {
        return _lockup.unlocked;
    }

    /// @notice Whether `account` is on the transfer allowlist.
    function isAllowlisted(address account) external view returns (bool) {
        return _lockup.isAllowlisted(account);
    }

    /// @inheritdoc IUERC20
    function tokenURI() external view returns (string memory) {
        return metadata.toJSON();
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return interfaceId == type(IERC165).interfaceId || interfaceId == type(IERC20).interfaceId
            || interfaceId == type(IERC20Metadata).interfaceId || interfaceId == type(IERC20Permit).interfaceId;
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

    /// @inheritdoc IERC20Permit
    function nonces(address owner_) external view returns (uint256) {
        return _permit.nonces[owner_];
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
    function permit(address owner_, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external
    {
        _permit.verify(owner_, spender, value, deadline, v, r, s);
        _token.approve(owner_, spender, value);
        emit Approval(owner_, spender, value);
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
