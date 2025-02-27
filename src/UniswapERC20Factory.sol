// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {UniswapERC20} from "./UniswapERC20.sol";
import {UniswapERC20Metadata} from "./libraries/UniswapERC20Metadata.sol";
import {Create2} from "openzeppelin-contracts/contracts/utils/Create2.sol";

/// @title UniswapERC20Factory
/// @notice Deploys new UniswapERC20 contracts
contract UniswapERC20Factory {
    /// @notice Parameters struct to be used by the UniswapERC20 during construction
    struct Parameters {
        string name;
        string symbol;
        address recipient;
        uint256 totalSupply;
        uint256 homeChainId;
        uint8 decimals;
        UniswapERC20Metadata metadata;
    }

    /// @dev Parameters stored transiently for token initialization
    Parameters public parameters;

    /// @notice Emitted when a new UniswapERC20 token is created
    event UniswapERC20Created(
        address indexed tokenAddress,
        uint256 indexed chainId,
        string name,
        string symbol,
        uint8 decimals,
        uint256 homeChainId
    );

    /// @notice Thrown when the caller is not the creator in the initial deployment of a token
    error NotCreator(address sender, address creator);

    /// @notice Computes the deterministic address for a token based on its core parameters
    /// @param name The name of the token
    /// @param symbol The symbol of the token
    /// @param decimals The number of decimals the token uses
    /// @param homeChainId The hub chain ID of the token
    /// @param metadata The token metadata
    /// @return The deterministic address of the token
    function getTokenAddress(
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 homeChainId,
        UniswapERC20Metadata memory metadata
    ) public view returns (address) {
        bytes32 salt = keccak256(abi.encode(name, symbol, decimals, homeChainId, metadata));
        bytes32 initCodeHash = keccak256(abi.encodePacked(type(UniswapERC20).creationCode));
        return Create2.computeAddress(salt, initCodeHash, address(this));
    }

    /// @notice Gets the parameters for token initialization
    /// @return The parameters structure with all token initialization data
    function getParameters() external view returns (Parameters memory) {
        return parameters;
    }

    /// @notice Deploys a new Token contract
    /// @param name The name of the token
    /// @param symbol The symbol of the token
    /// @param decimals The number of decimals the token uses
    /// @param totalSupply The total supply of the token
    /// @param recipient The address to mint the total supply to
    /// @param homeChainId The hub chain ID of the token where the total supply is originally minted
    /// @param tokenMetadata The token metadata
    /// @return newUniswapERC20 The address of the newly deployed Token contract
    function create(
        string memory name,
        string memory symbol,
        uint8 decimals,
        address recipient,
        uint256 totalSupply,
        uint256 homeChainId,
        UniswapERC20Metadata memory tokenMetadata
    ) external returns (UniswapERC20 newUniswapERC20) {
        /// Only the creator can deploy a token on the home chain
        if (block.chainid == homeChainId && msg.sender != tokenMetadata.creator) {
            revert NotCreator(msg.sender, tokenMetadata.creator);
        }

        // Store parameters transiently for token to access during construction
        parameters = Parameters({
            name: name,
            symbol: symbol,
            recipient: recipient,
            totalSupply: totalSupply,
            homeChainId: homeChainId,
            decimals: decimals,
            metadata: tokenMetadata
        });

        // Compute salt based on the core parameters that define a token's identity
        bytes32 salt = keccak256(abi.encode(name, symbol, decimals, homeChainId, tokenMetadata));

        // Deploy the token with the computed salt
        newUniswapERC20 = new UniswapERC20{salt: salt}();

        // Clear parameters after deployment
        delete parameters;

        emit UniswapERC20Created(address(newUniswapERC20), block.chainid, name, symbol, decimals, homeChainId);
    }
}
