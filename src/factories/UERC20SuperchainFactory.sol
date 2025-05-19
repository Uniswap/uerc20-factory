// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {UERC20Superchain} from "../tokens/UERC20Superchain.sol";
import {IUERC20SuperchainFactory} from "../interfaces/IUERC20SuperchainFactory.sol";
import {ITokenFactory} from "../interfaces/ITokenFactory.sol";
import {UERC20Metadata} from "../libraries/UERC20MetadataLibrary.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";

/// @title UERC20SuperchainFactory
/// @notice Deploys new UERC20Superchain contracts
contract UERC20SuperchainFactory is IUERC20SuperchainFactory {
    /// @dev Parameters stored transiently for token initialization
    Parameters private parameters;

    /// @inheritdoc IUERC20SuperchainFactory
    function getUERC20SuperchainAddress(
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 homeChainId,
        address creator
    ) external view returns (address) {
        bytes32 salt = keccak256(abi.encode(name, symbol, decimals, homeChainId, creator));
        bytes32 initCodeHash = keccak256(abi.encodePacked(type(UERC20Superchain).creationCode));
        return Create2.computeAddress(salt, initCodeHash, address(this));
    }

    /// @inheritdoc IUERC20SuperchainFactory
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
        (uint256 homeChainId, address creator, UERC20Metadata memory metadata) =
            abi.decode(data, (uint256, address, UERC20Metadata));

        // Only the creator can deploy a token on the home chain
        if (block.chainid == homeChainId && msg.sender != creator) {
            revert NotCreator(msg.sender, creator);
        }

        // Clear metadata if the token is not on the home chain
        // Metadata is only stored on the home chain
        if (block.chainid != homeChainId) {
            metadata.description = "";
            metadata.website = "";
            metadata.image = "";
        }

        // Store parameters transiently for token to access during construction
        parameters = Parameters({
            name: name,
            symbol: symbol,
            totalSupply: totalSupply,
            homeChainId: homeChainId,
            creator: creator,
            recipient: recipient,
            decimals: decimals,
            metadata: metadata
        });

        // Compute salt based on the core parameters that define a token's identity
        bytes32 salt = keccak256(abi.encode(name, symbol, decimals, homeChainId, creator));

        // Deploy the token with the computed salt
        tokenAddress = address(new UERC20Superchain{salt: salt}());

        // Clear parameters after deployment
        delete parameters;

        emit TokenCreated(tokenAddress);
    }
}
