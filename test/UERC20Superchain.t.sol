// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {UERC20Superchain} from "../src/tokens/UERC20Superchain.sol";
import {UERC20SuperchainFactory} from "../src/factories/UERC20SuperchainFactory.sol";
import {UERC20Metadata} from "../src/libraries/UERC20MetadataLibrary.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC7802, IERC165} from "@optimism/interfaces/L2/IERC7802.sol";
import {Base64} from "./libraries/base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract UERC20SuperchainTest is Test {
    using Base64 for string;
    using Strings for address;

    address constant SUPERCHAIN_ERC20_BRIDGE = 0x4200000000000000000000000000000000000028;
    address constant PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;
    uint256 constant INITIAL_BALANCE = 5e18;
    uint256 constant TRANSFER_AMOUNT = 1e18;
    uint8 constant DECIMALS = 18;

    UERC20Superchain token;
    UERC20SuperchainFactory factory;
    UERC20Metadata tokenMetadata;

    address recipient = makeAddr("recipient");
    address bob = makeAddr("bob");

    event CrosschainMint(address indexed to, uint256 amount, address indexed sender);
    event CrosschainBurn(address indexed from, uint256 amount, address indexed sender);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function setUp() public {
        tokenMetadata = UERC20Metadata({
            description: "A test token",
            website: "https://example.com",
            image: "https://example.com/image.png",
            creator: address(this),
            graffiti: bytes32("test")
        });
        factory = new UERC20SuperchainFactory();
        token = UERC20Superchain(
            factory.createToken(
                "Test", "TEST", DECIMALS, INITIAL_BALANCE, recipient, abi.encode(block.chainid, tokenMetadata)
            )
        );
    }

    function test_uerc20superchain_crosschainMint_succeeds() public {
        vm.expectEmit(true, false, true, true);
        emit CrosschainMint(bob, TRANSFER_AMOUNT, SUPERCHAIN_ERC20_BRIDGE);
        vm.startPrank(SUPERCHAIN_ERC20_BRIDGE);
        token.crosschainMint(bob, TRANSFER_AMOUNT);
        assertEq(token.balanceOf(bob), TRANSFER_AMOUNT);
        assertEq(token.totalSupply(), INITIAL_BALANCE + TRANSFER_AMOUNT);
        token.crosschainMint(bob, TRANSFER_AMOUNT);
        assertEq(token.balanceOf(bob), TRANSFER_AMOUNT * 2);
    }

    function test_uerc20superchain_fuzz_crosschainMint_succeeds(address to, uint256 amount) public {
        vm.assume(to != address(0));
        // Prevent overflow
        amount = bound(amount, 0, type(uint256).max - token.totalSupply());

        uint256 totalSupplyBefore = token.totalSupply();
        uint256 toBalanceBefore = token.balanceOf(to);

        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), to, amount);

        vm.expectEmit(true, false, true, true);
        emit CrosschainMint(to, amount, SUPERCHAIN_ERC20_BRIDGE);

        vm.startPrank(SUPERCHAIN_ERC20_BRIDGE);
        token.crosschainMint(to, amount);

        assertEq(token.totalSupply(), totalSupplyBefore + amount);
        assertEq(token.balanceOf(to), toBalanceBefore + amount);
    }

    function test_uerc20superchain_crosschainMint_revertsWithNotSuperchainERC20Bridge() public {
        vm.prank(bob);
        vm.expectRevert(
            abi.encodeWithSelector(UERC20Superchain.NotSuperchainTokenBridge.selector, bob, SUPERCHAIN_ERC20_BRIDGE)
        );
        token.crosschainMint(bob, TRANSFER_AMOUNT);
        assertEq(token.balanceOf(bob), 0);
        assertEq(token.totalSupply(), INITIAL_BALANCE);
    }

    function test_uerc20superchain_fuzz_crosschainMint_revertsWithNotSuperchainERC20Bridge(
        address caller,
        address to,
        uint256 amount
    ) public {
        vm.assume(caller != SUPERCHAIN_ERC20_BRIDGE);

        vm.expectRevert(
            abi.encodeWithSelector(UERC20Superchain.NotSuperchainTokenBridge.selector, caller, SUPERCHAIN_ERC20_BRIDGE)
        );

        vm.prank(caller);
        token.crosschainMint(to, amount);
    }

    function test_uerc20superchain_crosschainBurn_succeeds() public {
        deal(address(token), bob, TRANSFER_AMOUNT);
        assertEq(token.balanceOf(bob), TRANSFER_AMOUNT);
        vm.expectEmit(true, false, true, true);
        emit CrosschainBurn(bob, TRANSFER_AMOUNT, SUPERCHAIN_ERC20_BRIDGE);
        vm.prank(SUPERCHAIN_ERC20_BRIDGE);
        token.crosschainBurn(bob, TRANSFER_AMOUNT);
        assertEq(token.balanceOf(bob), 0);
    }

    function test_uerc20superchain_fuzz_crosschainBurn_succeeds(uint256 amount) public {
        amount = bound(amount, 0, token.totalSupply());

        uint256 totalSupplyBefore = token.totalSupply();
        uint256 recipientBalanceBefore = token.balanceOf(recipient);

        vm.expectEmit(true, true, false, true);
        emit Transfer(recipient, address(0), amount);

        vm.expectEmit(true, false, true, true);
        emit CrosschainBurn(recipient, amount, SUPERCHAIN_ERC20_BRIDGE);

        vm.startPrank(SUPERCHAIN_ERC20_BRIDGE);
        token.crosschainBurn(recipient, amount);

        assertEq(token.totalSupply(), totalSupplyBefore - amount);
        assertEq(token.balanceOf(recipient), recipientBalanceBefore - amount);
    }

    function test_uerc20superchain_crosschainBurn_revertsWithNotSuperchainERC20Bridge() public {
        deal(address(token), bob, TRANSFER_AMOUNT);
        assertEq(token.balanceOf(bob), TRANSFER_AMOUNT);
        vm.prank(bob);
        vm.expectRevert(
            abi.encodeWithSelector(UERC20Superchain.NotSuperchainTokenBridge.selector, bob, SUPERCHAIN_ERC20_BRIDGE)
        );
        token.crosschainBurn(bob, TRANSFER_AMOUNT);
        assertEq(token.balanceOf(bob), TRANSFER_AMOUNT);
    }

    function test_uerc20superchain_fuzz_crosschainBurn_revertsWithNotSuperchainERC20Bridge(
        address caller,
        address from,
        uint256 amount
    ) public {
        vm.assume(caller != SUPERCHAIN_ERC20_BRIDGE);

        vm.expectRevert(
            abi.encodeWithSelector(UERC20Superchain.NotSuperchainTokenBridge.selector, caller, SUPERCHAIN_ERC20_BRIDGE)
        );

        vm.prank(caller);
        token.crosschainBurn(from, amount);
    }

    function test_uerc20superchain_supportsInterface() public view {
        assertTrue(bytes4(0x01ffc9a7) == type(IERC165).interfaceId);
        assertTrue(token.supportsInterface(0x01ffc9a7)); // IERC165
        assertTrue(bytes4(0x33331994) == type(IERC7802).interfaceId);
        assertTrue(token.supportsInterface(0x33331994)); // IERC7802
        assertTrue(bytes4(0x36372b07) == type(IERC20).interfaceId);
        assertTrue(token.supportsInterface(0x36372b07)); // IERC20
    }

    function test_uerc20superchain_fuzz_supportsInterface(bytes4 interfaceId) public view {
        vm.assume(interfaceId != type(IERC165).interfaceId);
        vm.assume(interfaceId != type(IERC7802).interfaceId);
        vm.assume(interfaceId != type(IERC20).interfaceId);
        assertFalse(token.supportsInterface(interfaceId));
    }

    function test_uerc20superchain_permit2CanTransferWithoutAllowance() public {
        vm.startPrank(PERMIT2);
        token.transferFrom(recipient, bob, TRANSFER_AMOUNT);
        assertEq(token.balanceOf(bob), TRANSFER_AMOUNT);
        assertEq(token.balanceOf(recipient), INITIAL_BALANCE - TRANSFER_AMOUNT);
        vm.stopPrank();
    }

    function test_uerc20superchain_nonPermit2CannotTransferWithoutAllowance() public {
        vm.startPrank(bob);
        vm.expectRevert();
        token.transferFrom(recipient, bob, TRANSFER_AMOUNT);
        vm.stopPrank();
    }

    function test_uerc20superchain_nonPermit2CanTransferWithAllowance() public {
        vm.prank(recipient);
        token.approve(bob, TRANSFER_AMOUNT);

        vm.prank(bob);
        token.transferFrom(recipient, bob, TRANSFER_AMOUNT);

        assertEq(token.balanceOf(bob), TRANSFER_AMOUNT);
        assertEq(token.balanceOf(recipient), INITIAL_BALANCE - TRANSFER_AMOUNT);
        assertEq(token.allowance(recipient, bob), 0);
    }

    function test_uerc20superchain_permit2InfiniteAllowance() public view {
        assertEq(token.allowance(recipient, PERMIT2), type(uint256).max);
    }

    function test_uerc20superchain_nameSymbolDecimalsTotalSupply() public view {
        assertEq(token.name(), "Test");
        assertEq(token.symbol(), "TEST");
        assertEq(token.decimals(), DECIMALS);
        assertEq(token.totalSupply(), INITIAL_BALANCE);
    }

    function test_uerc20superchain_tokenURI_allFields() public view {
        string memory json = decodeJson(token);

        // Parse JSON to extract individual fields using key paths
        address creator = abi.decode(vm.parseJson(json, ".Creator"), (address));
        bytes32 graffiti = abi.decode(vm.parseJson(json, ".Graffiti"), (bytes32));
        string memory description = abi.decode(vm.parseJson(json, ".Description"), (string));
        string memory website = abi.decode(vm.parseJson(json, ".Website"), (string));
        string memory image = abi.decode(vm.parseJson(json, ".Image"), (string));

        assertEq(creator, address(this));
        assertEq(description, "A test token");
        assertEq(website, "https://example.com");
        assertEq(image, "https://example.com/image.png");
        assertEq(graffiti, bytes32("test"));
    }

    function test_uerc20superchain_tokenURI_maliciousInjectionDetected() public {
        tokenMetadata = UERC20Metadata({
            description: "A test token",
            website: "https://example.com",
            image: "Normal description\" , \"Creator\": \"0x1234567890123456789012345678901234567890",
            creator: address(this),
            graffiti: bytes32("test")
        });
        factory = new UERC20SuperchainFactory();
        token = UERC20Superchain(
            factory.createToken(
                "Test", "TEST", DECIMALS, INITIAL_BALANCE, recipient, abi.encode(block.chainid, tokenMetadata)
            )
        );

        string memory json = decodeJson(token);

        // Parse JSON to extract individual fields using key paths
        address creator = abi.decode(vm.parseJson(json, ".Creator"), (address));
        bytes32 graffiti = abi.decode(vm.parseJson(json, ".Graffiti"), (bytes32));
        string memory description = abi.decode(vm.parseJson(json, ".Description"), (string));
        string memory website = abi.decode(vm.parseJson(json, ".Website"), (string));
        string memory image = abi.decode(vm.parseJson(json, ".Image"), (string));

        // detects correct creator, not the malicious one
        assertEq(creator, address(this));
        assertEq(graffiti, bytes32("test"));
        assertEq(description, "A test token");
        assertEq(website, "https://example.com");
        assertEq(image, "Normal description\" , \"Creator\": \"0x1234567890123456789012345678901234567890");
    }

    function test_uerc20superchain_tokenURI_descriptionWebsite() public {
        tokenMetadata = UERC20Metadata({
            description: "A test token",
            website: "https://example.com",
            image: "",
            creator: address(this),
            graffiti: bytes32("test")
        });
        factory = new UERC20SuperchainFactory();
        token = UERC20Superchain(
            factory.createToken(
                "Test", "TEST", DECIMALS, INITIAL_BALANCE, recipient, abi.encode(block.chainid, tokenMetadata)
            )
        );

        string memory json = decodeJson(token);

        // Parse JSON to extract individual fields using key paths
        address creator = abi.decode(vm.parseJson(json, ".Creator"), (address));
        bytes32 graffiti = abi.decode(vm.parseJson(json, ".Graffiti"), (bytes32));
        string memory description = abi.decode(vm.parseJson(json, ".Description"), (string));
        string memory website = abi.decode(vm.parseJson(json, ".Website"), (string));

        assertEq(creator, address(this));
        assertEq(description, "A test token");
        assertEq(website, "https://example.com");
        assertEq(graffiti, bytes32("test"));
    }

    function test_uerc20superchain_tokenURI_descriptionImage() public {
        tokenMetadata = UERC20Metadata({
            description: "A test token",
            website: "",
            image: "https://example.com/image.png",
            creator: address(this),
            graffiti: bytes32("test")
        });
        factory = new UERC20SuperchainFactory();
        token = UERC20Superchain(
            factory.createToken(
                "Test", "TEST", DECIMALS, INITIAL_BALANCE, recipient, abi.encode(block.chainid, tokenMetadata)
            )
        );

        string memory json = decodeJson(token);

        // Parse JSON to extract individual fields using key paths
        address creator = abi.decode(vm.parseJson(json, ".Creator"), (address));
        bytes32 graffiti = abi.decode(vm.parseJson(json, ".Graffiti"), (bytes32));
        string memory description = abi.decode(vm.parseJson(json, ".Description"), (string));
        string memory image = abi.decode(vm.parseJson(json, ".Image"), (string));

        assertEq(creator, address(this));
        assertEq(description, "A test token");
        assertEq(image, "https://example.com/image.png");
        assertEq(graffiti, bytes32("test"));
    }

    function test_uerc20superchain_tokenURI_websiteImage() public {
        tokenMetadata = UERC20Metadata({
            description: "",
            website: "https://example.com",
            image: "https://example.com/image.png",
            creator: address(this),
            graffiti: bytes32("test")
        });
        factory = new UERC20SuperchainFactory();
        token = UERC20Superchain(
            factory.createToken(
                "Test", "TEST", DECIMALS, INITIAL_BALANCE, recipient, abi.encode(block.chainid, tokenMetadata)
            )
        );

        string memory json = decodeJson(token);

        // Parse JSON to extract individual fields using key paths
        address creator = abi.decode(vm.parseJson(json, ".Creator"), (address));
        bytes32 graffiti = abi.decode(vm.parseJson(json, ".Graffiti"), (bytes32));
        string memory website = abi.decode(vm.parseJson(json, ".Website"), (string));
        string memory image = abi.decode(vm.parseJson(json, ".Image"), (string));

        assertEq(creator, address(this));
        assertEq(website, "https://example.com");
        assertEq(image, "https://example.com/image.png");
        assertEq(graffiti, bytes32("test"));
    }

    function test_uerc20superchain_tokenURI_description() public {
        tokenMetadata = UERC20Metadata({
            description: "A test token",
            website: "",
            image: "",
            creator: address(this),
            graffiti: bytes32("test")
        });
        factory = new UERC20SuperchainFactory();
        token = UERC20Superchain(
            factory.createToken(
                "Test", "TEST", DECIMALS, INITIAL_BALANCE, recipient, abi.encode(block.chainid, tokenMetadata)
            )
        );

        string memory json = decodeJson(token);

        // Parse JSON to extract individual fields using key paths
        address creator = abi.decode(vm.parseJson(json, ".Creator"), (address));
        bytes32 graffiti = abi.decode(vm.parseJson(json, ".Graffiti"), (bytes32));
        string memory description = abi.decode(vm.parseJson(json, ".Description"), (string));

        assertEq(creator, address(this));
        assertEq(description, "A test token");
        assertEq(graffiti, bytes32("test"));
    }

    function test_uerc20superchain_tokenURI_website() public {
        tokenMetadata = UERC20Metadata({
            description: "",
            website: "https://example.com",
            image: "",
            creator: address(this),
            graffiti: bytes32("test")
        });
        factory = new UERC20SuperchainFactory();
        token = UERC20Superchain(
            factory.createToken(
                "Test", "TEST", DECIMALS, INITIAL_BALANCE, recipient, abi.encode(block.chainid, tokenMetadata)
            )
        );

        string memory json = decodeJson(token);

        // Parse JSON to extract individual fields using key paths
        address creator = abi.decode(vm.parseJson(json, ".Creator"), (address));
        bytes32 graffiti = abi.decode(vm.parseJson(json, ".Graffiti"), (bytes32));
        string memory website = abi.decode(vm.parseJson(json, ".Website"), (string));

        assertEq(creator, address(this));
        assertEq(website, "https://example.com");
        assertEq(graffiti, bytes32("test"));
    }

    function test_uerc20superchain_tokenURI_image() public {
        tokenMetadata = UERC20Metadata({
            description: "",
            website: "",
            image: "https://example.com/image.png",
            creator: address(this),
            graffiti: bytes32("test")
        });
        factory = new UERC20SuperchainFactory();
        token = UERC20Superchain(
            factory.createToken(
                "Test", "TEST", DECIMALS, INITIAL_BALANCE, recipient, abi.encode(block.chainid, tokenMetadata)
            )
        );

        string memory json = decodeJson(token);

        // Parse JSON to extract individual fields using key paths
        address creator = abi.decode(vm.parseJson(json, ".Creator"), (address));
        bytes32 graffiti = abi.decode(vm.parseJson(json, ".Graffiti"), (bytes32));
        string memory image = abi.decode(vm.parseJson(json, ".Image"), (string));

        assertEq(creator, address(this));
        assertEq(image, "https://example.com/image.png");
        assertEq(graffiti, bytes32("test"));
    }

    function test_uerc20superchain_tokenURI_onlyCreator() public {
        tokenMetadata =
            UERC20Metadata({description: "", website: "", image: "", creator: address(this), graffiti: bytes32("test")});
        factory = new UERC20SuperchainFactory();
        token = UERC20Superchain(
            factory.createToken(
                "Test", "TEST", DECIMALS, INITIAL_BALANCE, recipient, abi.encode(block.chainid, tokenMetadata)
            )
        );

        string memory json = decodeJson(token);

        // Parse JSON to extract individual fields using key paths
        address creator = abi.decode(vm.parseJson(json, ".Creator"), (address));
        bytes32 graffiti = abi.decode(vm.parseJson(json, ".Graffiti"), (bytes32));

        assertEq(creator, address(this));
        assertEq(graffiti, bytes32("test"));
    }

    function decodeJson(UERC20Superchain _token) private view returns (string memory) {
        // The prefix length is calculated by converting the string to bytes and finding its length
        uint256 prefixLength = bytes("data:application/json;base64,").length;

        string memory uri = _token.tokenURI();
        // Convert the uri to bytes
        bytes memory uriBytes = bytes(uri);

        // Slice the uri to get only the base64-encoded part
        bytes memory base64Part = new bytes(uriBytes.length - prefixLength);

        for (uint256 i = 0; i < base64Part.length; i++) {
            base64Part[i] = uriBytes[i + prefixLength];
        }

        // Decode the base64-encoded part
        bytes memory decoded = Base64.decode(string(base64Part));
        string memory json = string(decoded);

        return json;
    }

    /// forge-config: default.isolate = true
    /// forge-config: ci.isolate = true
    function test_uerc20superchain_crosschainMint_succeeds_gas() public {
        vm.startPrank(SUPERCHAIN_ERC20_BRIDGE);
        token.crosschainMint(bob, TRANSFER_AMOUNT);
        vm.snapshotGasLastCall("crosschainMint: first mint");
        token.crosschainMint(bob, TRANSFER_AMOUNT);
        vm.snapshotGasLastCall("crosschainMint: second mint");
    }

    /// forge-config: default.isolate = true
    /// forge-config: ci.isolate = true
    function test_uerc20superchain_crosschainBurn_succeeds_gas() public {
        deal(address(token), bob, TRANSFER_AMOUNT);
        vm.prank(SUPERCHAIN_ERC20_BRIDGE);
        token.crosschainBurn(bob, TRANSFER_AMOUNT);
        vm.snapshotGasLastCall("crosschainBurn");
    }
}
