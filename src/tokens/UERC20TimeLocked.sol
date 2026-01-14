// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IUERC20TimeLockedFactory} from "../interfaces/IUERC20TimeLockedFactory.sol";
import {BaseUERC20} from "./BaseUERC20.sol";

/// @title UERC20TimeLocked
/// @notice ERC20 token contract with time-locked transfers
contract UERC20TimeLocked is BaseUERC20 {
    /// @notice The block number at which the token will be fully transferable
    uint256 public immutable releaseBlock;

    /// @notice The address that can allowlist transfers before the release block
    address public operator;
    /// @dev Mapping of addresses that are allowed to transfer the token before the release block
    mapping(address => bool) public allowed;

    /// @dev Error for when a transfer is not allowed
    error TimeLocked();
    /// @dev Error for when the caller is not the operator
    error NotOperator();
    /// @dev Event for when the operator is set
    event OperatorSet(address indexed operator);
    /// @dev Event for when a transfer is allowed or disallowed
    event TransferAllowed(address indexed from, bool isAllowed);

    constructor() {
        IUERC20TimeLockedFactory.Parameters memory params = IUERC20TimeLockedFactory(msg.sender).getParameters();

        _name = params.name;
        _nameHash = keccak256(bytes(_name));
        _symbol = params.symbol;
        _decimals = params.decimals;
        releaseBlock = params.releaseBlock;
        operator = params.operator;
        creator = params.creator;
        graffiti = params.graffiti;
        metadata = params.metadata;

        _mint(params.recipient, params.totalSupply);

        emit OperatorSet(operator);
    }

    modifier isTransferAllowed(address _from) {
        if (block.number < releaseBlock) {
            if (!allowed[_from]) {
                revert TimeLocked();
            }
        }
        _;
    }

    /// @notice Sets the operator
    /// @param _operator The new operator
    function setOperator(address _operator) public {
        if (msg.sender != operator) {
            revert NotOperator();
        }
        operator = _operator;
        emit OperatorSet(_operator);
    }

    /// @notice Allows or disallows a transfer from a specific address
    /// @param to The address to allow or disallow
    /// @param isAllowed Whether to allow the transfer
    function allowTransfer(address to, bool isAllowed) public {
        if (msg.sender != operator) {
            revert NotOperator();
        }
        allowed[to] = isAllowed;
        emit TransferAllowed(to, isAllowed);
    }

    /// @dev Only allows transfers after the release block or if the sender is allowed
    function transfer(address to, uint256 amount) public override isTransferAllowed(msg.sender) returns (bool) {
        return super.transfer(to, amount);
    }

    /// @dev Only allows transfers after the release block or if the sender is allowed
    function transferFrom(address from, address to, uint256 amount)
        public
        override
        isTransferAllowed(from)
        returns (bool)
    {
        return super.transferFrom(from, to, amount);
    }
}
