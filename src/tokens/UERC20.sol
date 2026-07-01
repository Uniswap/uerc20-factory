// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Token} from "../types/Token.sol";
import {Metadata} from "../types/Metadata.sol";
import {Permit} from "../types/Permit.sol";
import {UERC20Config} from "../types/UERC20Config.sol";
import {IUERC20} from "../interfaces/IUERC20.sol";
import {ITokenFactory} from "../interfaces/ITokenFactory.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/// @title UERC20
/// @notice Base UERC20 token, deployed by a TokenFactory. A thin ABI surface wiring the standard
/// interface to the composed `Token`, `Metadata`, and `Permit` types; the logic lives in those types.
contract UERC20 is IUERC20 {
    Token internal _token;
    Permit internal _permit;

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

    error RecipientCannotBeZeroAddress();
    error TotalSupplyCannotBeZero();

    constructor() {
        ITokenFactory.DeploymentContext memory ctx = ITokenFactory(msg.sender).deployment();
        UERC20Config memory config = abi.decode(ctx.data, (UERC20Config));

        if (config.recipient == address(0)) revert RecipientCannotBeZeroAddress();
        if (config.totalSupply == 0) revert TotalSupplyCannotBeZero();

        name = config.name;
        symbol = config.symbol;
        decimals = config.decimals;
        metadata = config.metadata;
        creator = ctx.creator;
        graffiti = ctx.graffiti;

        _permit.init(config.name, address(this));
        _token.mint(config.recipient, config.totalSupply);
        emit Transfer(address(0), config.recipient, config.totalSupply);
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
}
