// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {Token} from "../src/Token.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC7802, IERC165} from "@optimism/interfaces/L2/IERC7802.sol";
import {SuperchainERC20} from "../src/SuperchainERC20.sol";

contract TokenTest is Test {
    Token token;
    address SUPERCHAIN_ERC20_BRIDGE = 0x4200000000000000000000000000000000000028;
    address constant PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;
    address recipient = makeAddr("recipient");
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    uint256 amount = 1e18;
    uint256 totalSupply = 5e18;

    uint256 constant INITIAL_BALANCE = 5e18;
    uint256 constant TRANSFER_AMOUNT = 1e18;

    event CrosschainMint(address indexed to, uint256 amount, address indexed sender);
    event CrosschainBurn(address indexed from, uint256 amount, address indexed sender);

    function setUp() public {
        token = new Token("Test", "TEST", 18, totalSupply, recipient, block.chainid);
        deal(address(token), alice, INITIAL_BALANCE);
    }

    function test_crosschainMint_succeeds() public {
        vm.expectEmit(true, false, true, true);
        emit CrosschainMint(bob, amount, SUPERCHAIN_ERC20_BRIDGE);
        vm.startPrank(SUPERCHAIN_ERC20_BRIDGE);
        token.crosschainMint(bob, amount);
        vm.snapshotGasLastCall("crosschainMint: first mint");
        assertEq(token.balanceOf(bob), amount);
        assertEq(token.totalSupply(), totalSupply + amount);
        token.crosschainMint(bob, amount);
        vm.snapshotGasLastCall("crosschainMint: second mint");
        assertEq(token.balanceOf(bob), amount * 2);
    }

    function test_crosschainMint_revertsWithNotSuperchainERC20Bridge() public {
        vm.prank(bob);
        vm.expectRevert(
            abi.encodeWithSelector(SuperchainERC20.NotSuperchainTokenBridge.selector, bob, SUPERCHAIN_ERC20_BRIDGE)
        );
        token.crosschainMint(bob, amount);
        assertEq(token.balanceOf(bob), 0);
        assertEq(token.totalSupply(), totalSupply);
    }

    function test_crosschainBurn_succeeds() public {
        deal(address(token), bob, amount);
        assertEq(token.balanceOf(bob), amount);
        vm.expectEmit(true, false, true, true);
        emit CrosschainBurn(bob, amount, SUPERCHAIN_ERC20_BRIDGE);
        vm.prank(SUPERCHAIN_ERC20_BRIDGE);
        token.crosschainBurn(bob, amount);
        vm.snapshotGasLastCall("crosschainBurn");
        assertEq(token.balanceOf(bob), 0);
    }

    function test_crosschainBurn_revertsWithNotSuperchainERC20Bridge() public {
        deal(address(token), bob, amount);
        assertEq(token.balanceOf(bob), amount);
        vm.prank(bob);
        vm.expectRevert(
            abi.encodeWithSelector(SuperchainERC20.NotSuperchainTokenBridge.selector, bob, SUPERCHAIN_ERC20_BRIDGE)
        );
        token.crosschainBurn(bob, amount);
        assertEq(token.balanceOf(bob), amount);
    }

    function test_supportsInterface() public view {
        assertTrue(bytes4(0x01ffc9a7) == type(IERC165).interfaceId);
        assertTrue(token.supportsInterface(0x01ffc9a7)); // IERC165
        assertTrue(bytes4(0x33331994) == type(IERC7802).interfaceId);
        assertTrue(token.supportsInterface(0x33331994)); // IERC7802
        assertTrue(bytes4(0x36372b07) == type(IERC20).interfaceId);
        assertTrue(token.supportsInterface(0x36372b07)); // IERC20
    }

    function test_permit2CanTransferWithoutAllowance() public {
        vm.startPrank(PERMIT2);
        token.transferFrom(alice, bob, TRANSFER_AMOUNT);
        assertEq(token.balanceOf(bob), TRANSFER_AMOUNT);
        assertEq(token.balanceOf(alice), INITIAL_BALANCE - TRANSFER_AMOUNT);
        vm.stopPrank();
    }

    function test_nonPermit2CannotTransferWithoutAllowance() public {
        vm.startPrank(bob);
        vm.expectRevert();
        token.transferFrom(alice, bob, TRANSFER_AMOUNT);
        vm.stopPrank();
    }

    function test_nonPermit2CanTransferWithAllowance() public {
        vm.prank(alice);
        token.approve(bob, TRANSFER_AMOUNT);

        vm.prank(bob);
        token.transferFrom(alice, bob, TRANSFER_AMOUNT);

        assertEq(token.balanceOf(bob), TRANSFER_AMOUNT);
        assertEq(token.balanceOf(alice), INITIAL_BALANCE - TRANSFER_AMOUNT);
        assertEq(token.allowance(alice, bob), 0);
    }

    function test_permit2InfiniteAllowance() public view {
        assertEq(token.allowance(alice, PERMIT2), type(uint256).max);
    }

    function test_nameSymbolDecimals() public view {
        assertEq(token.name(), "Test");
        assertEq(token.symbol(), "TEST");
        assertEq(token.decimals(), 18);
    }
}
