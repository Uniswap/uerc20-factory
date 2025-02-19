// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Token} from "./Token.sol";

contract TokenFactory {
    bytes32 internal constant SALT = bytes32(uint256(1));

    event TokenCreated(
        address indexed tokenAddress, uint256 indexed chainId, string name, string symbol, uint256 homeChainId
    );

    function create(
        string memory name,
        string memory symbol,
        uint256 totalSupply,
        address recipient,
        uint256 homeChainId
    ) external returns (Token newToken) {
        newToken = new Token{salt: SALT}(name, symbol, totalSupply, recipient, homeChainId);
        emit TokenCreated(address(newToken), block.chainid, name, symbol, homeChainId);
    }
}
