// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {Token} from "../../src/types/Token.sol";
import {PERMIT2} from "../../src/types/Allowances.sol";

/// @dev Minimal wrapper exposing the `Token` type's free functions for isolated testing —
/// the core payoff of type-driven design: the state type is tested without a full token contract.
contract TokenHarness {
    Token internal t;

    function mint(address to, uint256 a) external {
        t.mint(to, a);
    }

    function burn(address from, uint256 a) external {
        t.burn(from, a);
    }

    function transfer(address from, address to, uint256 a) external {
        t.transfer(from, to, a);
    }

    function transferFrom(address spender, address from, address to, uint256 a) external {
        t.transferFrom(spender, from, to, a);
    }

    function approve(address owner, address spender, uint256 a) external {
        t.approve(owner, spender, a);
    }

    function totalSupply() external view returns (uint256) {
        return t.totalSupply();
    }

    function balanceOf(address a) external view returns (uint256) {
        return t.balanceOf(a);
    }

    function allowanceOf(address o, address s) external view returns (uint256) {
        return t.allowanceOf(o, s);
    }
}

contract TokenTypeTest is Test {
    TokenHarness internal h;
    address internal alice = makeAddr("alice");
    address internal bob = makeAddr("bob");

    function setUp() public {
        h = new TokenHarness();
    }

    function test_mint_increasesSupplyAndBalance() public {
        h.mint(alice, 100);
        assertEq(h.totalSupply(), 100);
        assertEq(h.balanceOf(alice), 100);
    }

    function test_burn_decreasesSupplyAndBalance() public {
        h.mint(alice, 100);
        h.burn(alice, 40);
        assertEq(h.totalSupply(), 60);
        assertEq(h.balanceOf(alice), 60);
    }

    function test_transfer_movesBalance() public {
        h.mint(alice, 100);
        h.transfer(alice, bob, 30);
        assertEq(h.balanceOf(alice), 70);
        assertEq(h.balanceOf(bob), 30);
    }

    function test_transfer_revertsOnInsufficientBalance() public {
        h.mint(alice, 10);
        vm.expectRevert();
        h.transfer(alice, bob, 11);
    }

    function test_transferFrom_spendsFiniteAllowance() public {
        h.mint(alice, 100);
        h.approve(alice, bob, 50);
        h.transferFrom(bob, alice, bob, 30);
        assertEq(h.allowanceOf(alice, bob), 20);
        assertEq(h.balanceOf(bob), 30);
    }

    function test_transferFrom_revertsOnOverspend() public {
        h.mint(alice, 100);
        h.approve(alice, bob, 20);
        vm.expectRevert();
        h.transferFrom(bob, alice, bob, 21);
    }

    function test_permit2_readsAsInfiniteWithoutApproval() public view {
        assertEq(h.allowanceOf(alice, PERMIT2), type(uint256).max);
    }

    function testFuzz_mintThenTransfer(uint256 minted, uint256 sent) public {
        minted = bound(minted, 1, type(uint128).max);
        sent = bound(sent, 0, minted);
        h.mint(alice, minted);
        h.transfer(alice, bob, sent);
        assertEq(h.balanceOf(alice), minted - sent);
        assertEq(h.balanceOf(bob), sent);
        assertEq(h.totalSupply(), minted);
    }
}
