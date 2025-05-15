// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {UERC20} from "../tokens/UERC20.sol";
import {IUERC20Factory} from "../interfaces/IUERC20Factory.sol";
import {ITokenFactory} from "../interfaces/ITokenFactory.sol";
import {UERC20Metadata} from "../libraries/UERC20Metadata.sol";
import {Create2} from "openzeppelin-contracts/contracts/utils/Create2.sol";

/// @title UERC20Factory
/// @notice Deploys new UERC20 contracts
contract UERC20Factory is IUERC20Factory {
    /// @dev Parameters stored transiently for token initialization
    Parameters private parameters;

    /// @inheritdoc IUERC20Factory
    function getUERC20Address(string memory name, string memory symbol, uint8 decimals, address creator)
        external
        view
        returns (address)
    {
        bytes32 salt = keccak256(abi.encode(name, symbol, decimals, creator));
        bytes32 initCodeHash = keccak256(abi.encodePacked(type(UERC20).creationCode));
        return Create2.computeAddress(salt, initCodeHash, address(this));
    }

    /// @inheritdoc IUERC20Factory
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
        bytes calldata data
    ) external returns (address tokenAddress) {
        UERC20Metadata memory metadata = abi.decode(data, (UERC20Metadata));

        // Store parameters transiently for token to access during construction
        parameters = Parameters({
            name: name,
            symbol: symbol,
            totalSupply: totalSupply,
            recipient: recipient,
            decimals: decimals,
            metadata: metadata
        });

        // Compute salt based on the core parameters that define a token's identity
        bytes32 salt = keccak256(abi.encode(name, symbol, decimals, msg.sender));

        // Deploy the token with the computed salt
        tokenAddress = address(new UERC20{salt: salt}());

        // Clear parameters after deployment
        delete parameters;

        emit TokenCreated(tokenAddress);
    }
}
