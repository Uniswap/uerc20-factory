// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Token} from "../types/Token.sol";
import {Metadata} from "../types/Metadata.sol";
import {UERC20Config} from "../types/UERC20Config.sol";
import {IUERC20} from "../interfaces/IUERC20.sol";
import {ITokenFactory} from "../interfaces/ITokenFactory.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/// @title UERC20
/// @notice Base UERC20 token, deployed by a TokenFactory. A thin ABI surface wiring the standard
/// interface to the composed `Token` type; all money logic lives in that type's free functions.
/// @dev EIP-2612 permit is not yet implemented (so IERC20Permit is not advertised).
contract UERC20 is IUERC20 {
    Token internal _token;

    uint8 public immutable decimals;
    address public immutable creator;
    bytes32 public immutable graffiti;

    string public name;
    string public symbol;
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
            || interfaceId == type(IERC20Metadata).interfaceId;
    }

    function totalSupply() external view returns (uint256) {
        return _token.totalSupply();
    }

    function balanceOf(address account) external view returns (uint256) {
        return _token.balanceOf(account);
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return _token.allowanceOf(owner, spender);
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _token.approve(msg.sender, spender, amount);
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _token.transfer(msg.sender, to, amount);
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        _token.transferFrom(msg.sender, from, to, amount);
        emit Transfer(from, to, amount);
        return true;
    }
}
