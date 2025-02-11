// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {TokenFactory} from "../src/TokenFactory.sol";
import {Token} from "../src/Token.sol";

contract TokenFactoryTest is Test {
    TokenFactory public factory;

    function setUp() public {
        factory = new TokenFactory();
    }

    function test_create_succeeds() public {
        string memory name = "Test Token";
        string memory symbol = "TOKEN";
        Token tokenAddress = factory.create(name, symbol);

        assert(address(tokenAddress) != address(0));
        assertEq(tokenAddress.name(), name);
        assertEq(tokenAddress.symbol(), symbol);
        assertEq(tokenAddress.decimals(), 18);
    }
}
