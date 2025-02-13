// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {Token} from "../src/Token.sol";

contract TokenTest is Test {
    Token token;
    address public constant SUPERCHAIN_ERC20_BRIDGE = 0x4200000000000000000000000000000000000028;
    address alice = address(0xAAA);
    address bob = address(0xBBB);
    uint256 constant INITIAL_BALANCE = 100e18;

    function setUp() public {
        token = new Token("Test", "TEST");
        deal(address(token), alice, INITIAL_BALANCE);
    }

    function test_crosschainMint_succeeds() public {
        vm.prank(SUPERCHAIN_ERC20_BRIDGE);
        token.crosschainMint(bob, 100);
        assertEq(token.balanceOf(bob), 100);
    }

    function test_crosschainMint_fails() public {
        vm.prank(address(0x123));
        vm.expectRevert(abi.encodeWithSelector(Token.OnlySuperchainERC20Bridge.selector));
        token.crosschainMint(bob, 100);
        assertEq(token.balanceOf(bob), 0);
    }

    function test_crosschainBurn_succeeds() public {
        deal(address(token), bob, 100);
        assertEq(token.balanceOf(bob), 100);
        vm.prank(SUPERCHAIN_ERC20_BRIDGE);
        token.crosschainBurn(bob, 100);
        assertEq(token.balanceOf(bob), 0);
    }

    function test_crosschainBurn_fails() public {
        deal(address(token), bob, 100);
        assertEq(token.balanceOf(bob), 100);
        vm.prank(address(0x123));
        vm.expectRevert(abi.encodeWithSelector(Token.OnlySuperchainERC20Bridge.selector));
        token.crosschainBurn(bob, 100);
        assertEq(token.balanceOf(bob), 100);
    }
}