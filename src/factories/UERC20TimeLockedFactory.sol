// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {UERC20TimeLocked} from "../tokens/UERC20TimeLocked.sol";
import {IUERC20TimeLockedFactory} from "../interfaces/IUERC20TimeLockedFactory.sol";
import {ITokenFactory} from "../interfaces/ITokenFactory.sol";
import {UERC20Metadata} from "../libraries/UERC20MetadataLibrary.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";

/// @title UERC20Factory
/// @notice Deploys new UERC20 contracts
contract UERC20TimeLockedFactory is IUERC20TimeLockedFactory {
    /// @dev Parameters stored transiently for token initialization
    Parameters private parameters;

    /// @notice Thrown when the operator is the zero address
    error OperatorCannotBeZeroAddress();

    /// @inheritdoc IUERC20TimeLockedFactory
    function getUERC20TimelockedAddress(
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 releaseBlock,
        address operator,
        address creator,
        bytes32 graffiti
    ) external view returns (address) {
        bytes32 salt = keccak256(abi.encode(name, symbol, decimals, releaseBlock, operator, creator, graffiti));
        bytes32 initCodeHash = keccak256(abi.encodePacked(type(UERC20TimeLocked).creationCode));
        return Create2.computeAddress(salt, initCodeHash, address(this));
    }

    /// @inheritdoc IUERC20TimeLockedFactory
    function getParameters() external view returns (Parameters memory) {
        return parameters;
    }

    /// @inheritdoc ITokenFactory
    function createToken(
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 totalSupply,
        address recipient,
        bytes calldata data,
        bytes32 graffiti
    ) external returns (address tokenAddress) {
        (uint256 releaseBlock, address operator, UERC20Metadata memory metadata) =
            abi.decode(data, (uint256, address, UERC20Metadata));

        if (operator == address(0)) {
            revert OperatorCannotBeZeroAddress();
        }
        if (recipient == address(0)) {
            revert RecipientCannotBeZeroAddress();
        }
        if (totalSupply == 0) {
            revert TotalSupplyCannotBeZero();
        }

        // Store parameters transiently for token to access during construction
        parameters = Parameters({
            name: name,
            symbol: symbol,
            totalSupply: totalSupply,
            recipient: recipient,
            decimals: decimals,
            releaseBlock: releaseBlock,
            operator: operator,
            creator: msg.sender,
            metadata: metadata,
            graffiti: graffiti
        });

        // Compute salt based on the core parameters that define a token's identity
        bytes32 salt = keccak256(abi.encode(name, symbol, decimals, releaseBlock, operator, msg.sender, graffiti));

        // Deploy the token with the computed salt
        tokenAddress = address(new UERC20TimeLocked{salt: salt}());

        // Clear parameters after deployment
        delete parameters;

        emit TokenCreated(tokenAddress);
    }
}
