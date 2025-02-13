// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {Token} from "../src/Token.sol";

contract TokenTest is Test {
    Token token;
    address constant PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;
    address alice = address(0xAAA);
    address bob = address(0xBBB);
    uint256 constant INITIAL_BALANCE = 100e18;
    uint256 constant TRANSFER_AMOUNT = 50e18;

    function setUp() public {
        token = new Token("Test", "TEST");
        deal(address(token), alice, INITIAL_BALANCE);
    }

    function testPermit2CanTransferWithoutAllowance() public {
        vm.startPrank(PERMIT2);
        token.transferFrom(alice, bob, TRANSFER_AMOUNT);
        assertEq(token.balanceOf(bob), TRANSFER_AMOUNT);
        assertEq(token.balanceOf(alice), INITIAL_BALANCE - TRANSFER_AMOUNT);
        vm.stopPrank();
    }

    function testNonPermit2CannotTransferWithoutAllowance() public {
        vm.startPrank(bob);
        vm.expectRevert();
        token.transferFrom(alice, bob, TRANSFER_AMOUNT);
        vm.stopPrank();
    }

    function testNonPermit2CanTransferWithAllowance() public {
        vm.prank(alice);
        token.approve(bob, TRANSFER_AMOUNT);
        
        vm.prank(bob);
        token.transferFrom(alice, bob, TRANSFER_AMOUNT);
        
        assertEq(token.balanceOf(bob), TRANSFER_AMOUNT);
        assertEq(token.balanceOf(alice), INITIAL_BALANCE - TRANSFER_AMOUNT);
        assertEq(token.allowance(alice, bob), 0);
    }
} 