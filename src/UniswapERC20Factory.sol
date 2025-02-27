// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {UniswapERC20} from "./UniswapERC20.sol";
import {UniswapERC20Metadata} from "./libraries/UniswapERC20Metadata.sol";

/// @title UniswapERC20Factory
/// @notice Deploys new UniswapERC20 contracts
contract UniswapERC20Factory {
    /// @dev The salt used to deploy new UniswapERC20 contracts with CREATE2
    bytes32 internal constant SALT = bytes32(uint256(1));

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

    /// @notice Deploys a new UniswapERC20
    /// @param name The name of the token
    /// @param symbol The symbol of the token
    /// @param decimals The number of decimals the token uses
    /// @param totalSupply The total supply of the token
    /// @param recipient The address to mint the total supply to
    /// @param homeChainId The hub chain ID of the token where the total supply is originally minted
    /// @param metadata The metadata of the token
    /// @return newUniswapERC20 The address of the newly deployed UniswapERC20 contract
    function create(
        string memory name,
        string memory symbol,
        uint8 decimals,
        address recipient,
        uint256 totalSupply,
        uint256 homeChainId,
        UniswapERC20Metadata memory metadata
    ) external returns (UniswapERC20 newUniswapERC20) {
        /// Only the creator can deploy a token on the home chain
        if (block.chainid == homeChainId && msg.sender != metadata.creator) {
            revert NotCreator(msg.sender, metadata.creator);
        }
        newUniswapERC20 =
            new UniswapERC20{salt: SALT}(name, symbol, decimals, recipient, totalSupply, homeChainId, metadata);
        emit UniswapERC20Created(address(newUniswapERC20), block.chainid, name, symbol, decimals, homeChainId);
    }
}
