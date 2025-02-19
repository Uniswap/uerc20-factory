// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

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

        Token token = factory.create(name, symbol);
        vm.snapshotGasLastCall("deploy new token");

        assert(address(token) != address(0));
        assertEq(token.name(), name);
        assertEq(token.symbol(), symbol);
        assertEq(token.decimals(), 18);
    }

    function test_bytecodeSize_factory() public {
        vm.snapshotValue("TokenFactory bytecode size", address(factory).code.length);
    }

    function test_bytecodeSize_token() public {
        string memory name = "Test Token";
        string memory symbol = "TOKEN";

        Token token = factory.create(name, symbol);
        vm.snapshotValue("Token bytecode size", address(token).code.length);
    }
}
