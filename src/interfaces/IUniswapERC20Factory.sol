// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {UniswapERC20Metadata} from "../libraries/UniswapERC20Metadata.sol";
import {UniswapERC20} from "../UniswapERC20.sol";

/// @title IUniswapERC20Factory
/// @notice Interface for the UniswapERC20Factory contract
interface IUniswapERC20Factory {
    /// @notice Parameters struct to be used by the UniswapERC20 during construction
    struct Parameters {
        string name;
        string symbol;
        uint256 totalSupply;
        uint256 homeChainId;
        address recipient;
        uint8 decimals;
        address factory;
        UniswapERC20Metadata metadata;
    }

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
    /// @param creator The creator of the token
    /// @return The deterministic address of the token
    function getUniswapERC20Address(
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 homeChainId,
        address creator
    ) external view returns (address);

    /// @notice Gets the parameters for token initialization
    /// @return The parameters structure with all token initialization data
    function getParameters() external view returns (Parameters memory);

    /// @notice Deploys a new UniswapERC20 contract
    /// @param name The name of the token
    /// @param symbol The symbol of the token
    /// @param decimals The number of decimals the token uses
    /// @param homeChainId The hub chain ID of the token where the total supply is originally minted
    /// @param totalSupply The total supply of the token
    /// @param recipient The address to mint the total supply to
    /// @param metadata The token metadata
    /// @return The newly deployed Token contract
    function create(
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 homeChainId,
        address recipient,
        uint256 totalSupply,
        UniswapERC20Metadata memory metadata
    ) external returns (UniswapERC20);
}
