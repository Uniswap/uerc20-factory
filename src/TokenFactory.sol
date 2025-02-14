// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Token} from "./Token.sol";

contract TokenFactory {
    bytes32 internal constant SALT = bytes32(uint256(1));

    function create(
        string memory name,
        string memory symbol,
        uint256 totalSupply,
        address recipient,
        uint256 homeChainId
    ) external returns (Token newToken) {
        newToken = new Token{salt: SALT}(name, symbol, totalSupply, recipient, homeChainId);
    }
}
