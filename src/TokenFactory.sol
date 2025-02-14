// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Token} from "./Token.sol";

contract TokenFactory {
    function create(
        string memory name,
        string memory symbol,
        uint256 totalSupply,
        address recipient,
        uint256 homeChainId
    ) external returns (Token newToken) {
        newToken = new Token(name, symbol, totalSupply, recipient, homeChainId);
    }
}
