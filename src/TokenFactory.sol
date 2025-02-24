// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Token} from "./Token.sol";

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
        uint8 decimals,
        uint256 totalSupply,
        address recipient,
        uint256 homeChainId
    ) external returns (Token newToken) {
        newToken = new Token{salt: SALT}(name, symbol, decimals, totalSupply, recipient, homeChainId);
        emit TokenCreated(address(newToken), block.chainid, name, symbol, decimals, homeChainId);
    }
}
