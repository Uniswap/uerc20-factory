// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {Token} from "../src/Token.sol";
import {TokenMetadata} from "../src/types/TokenMetadata.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC7802, IERC165} from "@optimism/interfaces/L2/IERC7802.sol";
import {SuperchainERC20} from "../src/base/SuperchainERC20.sol";
import {Base64} from "./libraries/base64.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";

contract TokenTest is Test {
    using Base64 for string;
    using Strings for uint256;

    address constant SUPERCHAIN_ERC20_BRIDGE = 0x4200000000000000000000000000000000000028;
    address constant PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;
    uint256 constant INITIAL_BALANCE = 5e18;
    uint256 constant TRANSFER_AMOUNT = 1e18;

    Token token;
    TokenMetadata tokenMetadata;

    address recipient = makeAddr("recipient");
    address bob = makeAddr("bob");

    // struct JsonToken {
    //     string creator;
    //     string description;
    //     string image;
    //     string website;
    // }

    event CrosschainMint(address indexed to, uint256 amount, address indexed sender);
    event CrosschainBurn(address indexed from, uint256 amount, address indexed sender);

    function setUp() public {
        tokenMetadata = TokenMetadata({
            description: "A test token",
            website: "https://example.com",
            image: "https://example.com/image.png",
            creator: address(this)
        });
        token = new Token("Test", "TEST", recipient, INITIAL_BALANCE, block.chainid, 18, tokenMetadata);
    }

    function test_crosschainMint_succeeds() public {
        vm.expectEmit(true, false, true, true);
        emit CrosschainMint(bob, TRANSFER_AMOUNT, SUPERCHAIN_ERC20_BRIDGE);
        vm.startPrank(SUPERCHAIN_ERC20_BRIDGE);
        token.crosschainMint(bob, TRANSFER_AMOUNT);
        vm.snapshotGasLastCall("crosschainMint: first mint");
        assertEq(token.balanceOf(bob), TRANSFER_AMOUNT);
        assertEq(token.totalSupply(), INITIAL_BALANCE + TRANSFER_AMOUNT);
        token.crosschainMint(bob, TRANSFER_AMOUNT);
        vm.snapshotGasLastCall("crosschainMint: second mint");
        assertEq(token.balanceOf(bob), TRANSFER_AMOUNT * 2);
    }

    function test_crosschainMint_revertsWithNotSuperchainERC20Bridge() public {
        vm.prank(bob);
        vm.expectRevert(
            abi.encodeWithSelector(SuperchainERC20.NotSuperchainTokenBridge.selector, bob, SUPERCHAIN_ERC20_BRIDGE)
        );
        token.crosschainMint(bob, TRANSFER_AMOUNT);
        assertEq(token.balanceOf(bob), 0);
        assertEq(token.totalSupply(), INITIAL_BALANCE);
    }

    function test_crosschainBurn_succeeds() public {
        deal(address(token), bob, TRANSFER_AMOUNT);
        assertEq(token.balanceOf(bob), TRANSFER_AMOUNT);
        vm.expectEmit(true, false, true, true);
        emit CrosschainBurn(bob, TRANSFER_AMOUNT, SUPERCHAIN_ERC20_BRIDGE);
        vm.prank(SUPERCHAIN_ERC20_BRIDGE);
        token.crosschainBurn(bob, TRANSFER_AMOUNT);
        vm.snapshotGasLastCall("crosschainBurn");
        assertEq(token.balanceOf(bob), 0);
    }

    function test_crosschainBurn_revertsWithNotSuperchainERC20Bridge() public {
        deal(address(token), bob, TRANSFER_AMOUNT);
        assertEq(token.balanceOf(bob), TRANSFER_AMOUNT);
        vm.prank(bob);
        vm.expectRevert(
            abi.encodeWithSelector(SuperchainERC20.NotSuperchainTokenBridge.selector, bob, SUPERCHAIN_ERC20_BRIDGE)
        );
        token.crosschainBurn(bob, TRANSFER_AMOUNT);
        assertEq(token.balanceOf(bob), TRANSFER_AMOUNT);
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
        token.transferFrom(recipient, bob, TRANSFER_AMOUNT);
        assertEq(token.balanceOf(bob), TRANSFER_AMOUNT);
        assertEq(token.balanceOf(recipient), INITIAL_BALANCE - TRANSFER_AMOUNT);
        vm.stopPrank();
    }

    function test_nonPermit2CannotTransferWithoutAllowance() public {
        vm.startPrank(bob);
        vm.expectRevert();
        token.transferFrom(recipient, bob, TRANSFER_AMOUNT);
        vm.stopPrank();
    }

    function test_nonPermit2CanTransferWithAllowance() public {
        vm.prank(recipient);
        token.approve(bob, TRANSFER_AMOUNT);

        vm.prank(bob);
        token.transferFrom(recipient, bob, TRANSFER_AMOUNT);

        assertEq(token.balanceOf(bob), TRANSFER_AMOUNT);
        assertEq(token.balanceOf(recipient), INITIAL_BALANCE - TRANSFER_AMOUNT);
        assertEq(token.allowance(recipient, bob), 0);
    }

    function test_permit2InfiniteAllowance() public view {
        assertEq(token.allowance(recipient, PERMIT2), type(uint256).max);
    }

    function test_nameSymbolDecimalsTotalSupply() public view {
        assertEq(token.name(), "Test");
        assertEq(token.symbol(), "TEST");
        assertEq(token.decimals(), 18);
        assertEq(token.totalSupply(), INITIAL_BALANCE);
    }

    function test_tokenURI() public view {
        // The prefix length is calculated by converting the string to bytes and finding its length
        uint256 prefixLength = bytes("data:application/json;base64,").length;

        string memory uri = token.tokenURI();
        // Convert the uri to bytes
        bytes memory uriBytes = bytes(uri);

        // Slice the uri to get only the base64-encoded part
        bytes memory base64Part = new bytes(uriBytes.length - prefixLength);

        for (uint256 i = 0; i < base64Part.length; i++) {
            base64Part[i] = uriBytes[i + prefixLength];
        }

        // Decode the base64-encoded part
        // bytes memory decoded = Base64.decode(string(base64Part));
        // string memory json = string(decoded);

        // // Parse JSON to extract individual fields
        // assertEq(jsonToken.creator, addressToString(address(this)));
        // assertEq(jsonToken.description, "A test token");
        // assertEq(jsonToken.website, "https://example.com");
        // assertEq(jsonToken.image, "https://example.com/image.png");
    }

    function addressToString(address addr) internal pure returns (string memory) {
        return (uint256(uint160(addr))).toHexString(20);
    }
}
