// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Token} from "./Token.sol";

contract TokenFactory {
    function create(
        string memory name,
        string memory symbol,
        uint8 decimals
    ) external returns (Token newToken) {
        newToken = new Token(name, symbol, decimals);
    }
}
