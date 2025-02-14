// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {Token} from "../src/Token.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC7802, IERC165} from "../interfaces/IERC7802.sol";

contract TokenTest is Test {
    event CrosschainMint(address indexed to, uint256 amount, address indexed sender);
    event CrosschainBurn(address indexed from, uint256 amount, address indexed sender);

    Token token;
    address SUPERCHAIN_ERC20_BRIDGE = 0x4200000000000000000000000000000000000028;
    address bob = makeAddr("BOB");

    function setUp() public {
        token = new Token("Test", "TEST");
    }

    function test_crosschainMint_succeeds() public {
        vm.expectEmit(true, false, true, true);
        emit CrosschainMint(bob, 100, SUPERCHAIN_ERC20_BRIDGE);
        vm.startPrank(SUPERCHAIN_ERC20_BRIDGE);
        token.crosschainMint(bob, 100);
        vm.snapshotGasLastCall("crosschainMint - first");
        assertEq(token.balanceOf(bob), 100);
        assertEq(token.totalSupply(), 100);
        token.crosschainMint(bob, 100);
        vm.snapshotGasLastCall("crosschainMint - second");
        assertEq(token.balanceOf(bob), 200);
    }

    function test_fuzz_crosschainMint_succeeds(uint256 mintAmount) public {
        vm.prank(SUPERCHAIN_ERC20_BRIDGE);
        token.crosschainMint(bob, mintAmount);
        assertEq(token.balanceOf(bob), mintAmount);
        assertEq(token.totalSupply(), mintAmount);
    }

    function test_crosschainMint_revertsWithOnlySuperchainERC20Bridge() public {
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(Token.OnlySuperchainERC20Bridge.selector, bob, SUPERCHAIN_ERC20_BRIDGE));
        token.crosschainMint(bob, 100);
        assertEq(token.balanceOf(bob), 0);
        assertEq(token.totalSupply(), 0);
    }

    function test_crosschainBurn_succeeds() public {
        deal(address(token), bob, 100);
        assertEq(token.balanceOf(bob), 100);
        vm.expectEmit(true, false, true, true);
        emit CrosschainBurn(bob, 100, SUPERCHAIN_ERC20_BRIDGE);
        vm.prank(SUPERCHAIN_ERC20_BRIDGE);
        token.crosschainBurn(bob, 100);
        vm.snapshotGasLastCall("crosschainBurn");
        assertEq(token.balanceOf(bob), 0);
    }

    function test_fuzz_crosschainBurn_succeeds(uint256 burnAmount) public {
        deal(address(token), bob, burnAmount);
        assertEq(token.balanceOf(bob), burnAmount);
        vm.prank(SUPERCHAIN_ERC20_BRIDGE);
        token.crosschainBurn(bob, burnAmount);
        assertEq(token.balanceOf(bob), 0);
    }

    function test_crosschainBurn_revertsWithOnlySuperchainERC20Bridge() public {
        deal(address(token), bob, 100);
        assertEq(token.balanceOf(bob), 100);
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(Token.OnlySuperchainERC20Bridge.selector, bob, SUPERCHAIN_ERC20_BRIDGE));
        token.crosschainBurn(bob, 100);
        assertEq(token.balanceOf(bob), 100);
    }

    function test_supportsInterface() public view {
        assertTrue(bytes4(0x01ffc9a7) == type(IERC165).interfaceId);
        assertTrue(token.supportsInterface(0x01ffc9a7)); // IERC165
        assertTrue(bytes4(0x33331994) == type(IERC7802).interfaceId);
        assertTrue(token.supportsInterface(0x33331994)); // IERC165
        assertTrue(bytes4(0x36372b07) == type(IERC20).interfaceId);
        assertTrue(token.supportsInterface(0x36372b07)); // IERC20
    }
}
