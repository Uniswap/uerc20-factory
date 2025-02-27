// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Token} from "./Token.sol";
import {TokenMetadata} from "./libraries/TokenMetadata.sol";

/// @title TokenFactory
/// @notice Deploys new Token contracts
contract TokenFactory {
    /// @dev The salt used to deploy new Token contracts with CREATE2
    bytes32 internal constant SALT = bytes32(uint256(1));

    /// @notice Emitted when a new Token contract is deployed
    event TokenCreated(
        address indexed tokenAddress,
        uint256 indexed chainId,
        string name,
        string symbol,
        uint8 decimals,
        uint256 homeChainId
    );

    /// @notice Thrown when the caller is not the creator in the initial deployment of a token
    error NotCreator(address sender, address creator);

    /// @notice Deploys a new Token contract
    /// @param name The name of the token
    /// @param symbol The symbol of the token
    /// @param decimals The number of decimals the token uses
    /// @param totalSupply The total supply of the token
    /// @param recipient The address to mint the total supply to
    /// @param homeChainId The hub chain ID of the token where the total supply is originally minted
    /// @return newToken The address of the newly deployed Token contract
    function create(
        string memory name,
        string memory symbol,
        address recipient,
        uint256 totalSupply,
        uint256 homeChainId,
        uint8 decimals,
        TokenMetadata memory tokenMetadata
    ) external returns (Token newToken) {
        /// Only the creator can deploy a token on the home chain
        if (block.chainid == homeChainId && msg.sender != tokenMetadata.creator) {
            revert NotCreator(msg.sender, tokenMetadata.creator);
        }
        newToken = new Token{salt: SALT}(name, symbol, recipient, totalSupply, homeChainId, decimals, tokenMetadata);
        emit TokenCreated(address(newToken), block.chainid, name, symbol, decimals, homeChainId);
    }
}
