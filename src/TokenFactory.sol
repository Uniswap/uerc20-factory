// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Token} from "./Token.sol";
import {TokenMetadata} from "./libraries/TokenMetadata.sol";

contract TokenFactory {
    bytes32 internal constant SALT = bytes32(uint256(1));

    event TokenCreated(
        address indexed tokenAddress,
        uint256 indexed chainId,
        string name,
        string symbol,
        uint8 decimals,
        uint256 homeChainId
    );

    error NotCreator(address sender, address creator);

    function create(
        string memory name,
        string memory symbol,
        address recipient,
        uint256 totalSupply,
        uint256 homeChainId,
        uint8 decimals,
        TokenMetadata memory tokenMetadata
    ) external returns (Token newToken) {
        if (block.chainid == homeChainId) {
            if (msg.sender != tokenMetadata.creator) {
                revert NotCreator(msg.sender, tokenMetadata.creator);
            }
        }
        newToken = new Token{salt: SALT}(name, symbol, recipient, totalSupply, homeChainId, decimals, tokenMetadata);
        emit TokenCreated(address(newToken), block.chainid, name, symbol, decimals, homeChainId);
    }
}
