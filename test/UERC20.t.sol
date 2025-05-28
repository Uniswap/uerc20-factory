// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {UERC20} from "../src/tokens/UERC20.sol";
import {UERC20Factory} from "../src/factories/UERC20Factory.sol";
import {UERC20Metadata} from "../src/libraries/UERC20MetadataLibrary.sol";
import {Base64} from "./libraries/base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract UERC20Test is Test {
    using Base64 for string;
    using Strings for address;

    address constant PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;
    uint256 constant INITIAL_BALANCE = 5e18;
    uint256 constant TRANSFER_AMOUNT = 1e18;
    uint8 constant DECIMALS = 18;

    UERC20 token;
    UERC20Factory factory;
    UERC20Metadata tokenMetadata;

    address recipient = makeAddr("recipient");
    address bob = makeAddr("bob");

    function setUp() public {
        tokenMetadata = UERC20Metadata({
            description: "A test token",
            website: "https://example.com",
            image: "https://example.com/image.png",
            creator: address(this),
            graffiti: bytes32("test")
        });
        factory = new UERC20Factory();
        token =
            UERC20(factory.createToken("Test", "TEST", DECIMALS, INITIAL_BALANCE, recipient, abi.encode(tokenMetadata)));
    }

    function test_uerc20_permit2CanTransferWithoutAllowance() public {
        vm.startPrank(PERMIT2);
        token.transferFrom(recipient, bob, TRANSFER_AMOUNT);
        assertEq(token.balanceOf(bob), TRANSFER_AMOUNT);
        assertEq(token.balanceOf(recipient), INITIAL_BALANCE - TRANSFER_AMOUNT);
        vm.stopPrank();
    }

    function test_uerc20_nonPermit2CannotTransferWithoutAllowance() public {
        vm.startPrank(bob);
        vm.expectRevert();
        token.transferFrom(recipient, bob, TRANSFER_AMOUNT);
        vm.stopPrank();
    }

    function test_uerc20_nonPermit2CanTransferWithAllowance() public {
        vm.prank(recipient);
        token.approve(bob, TRANSFER_AMOUNT);

        vm.prank(bob);
        token.transferFrom(recipient, bob, TRANSFER_AMOUNT);

        assertEq(token.balanceOf(bob), TRANSFER_AMOUNT);
        assertEq(token.balanceOf(recipient), INITIAL_BALANCE - TRANSFER_AMOUNT);
        assertEq(token.allowance(recipient, bob), 0);
    }

    function test_uerc20_permit2InfiniteAllowance() public view {
        assertEq(token.allowance(recipient, PERMIT2), type(uint256).max);
    }

    function test_uerc20_nameSymbolDecimalsTotalSupply() public view {
        assertEq(token.name(), "Test");
        assertEq(token.symbol(), "TEST");
        assertEq(token.decimals(), DECIMALS);
        assertEq(token.totalSupply(), INITIAL_BALANCE);
    }

    function test_uerc20_tokenURI_allFields() public view {
        string memory json = decodeJson(token);

        // Parse JSON to extract individual fields using key paths
        address creator = abi.decode(vm.parseJson(json, ".Creator"), (address));
        bytes32 graffiti = abi.decode(vm.parseJson(json, ".Graffiti"), (bytes32));
        string memory description = abi.decode(vm.parseJson(json, ".Description"), (string));
        string memory website = abi.decode(vm.parseJson(json, ".Website"), (string));
        string memory image = abi.decode(vm.parseJson(json, ".Image"), (string));

        assertEq(creator, address(this));
        assertEq(graffiti, bytes32("test"));
        assertEq(description, "A test token");
        assertEq(website, "https://example.com");
        assertEq(image, "https://example.com/image.png");
    }

    function test_uerc20_tokenURI_maliciousInjectionDetected() public {
        tokenMetadata = UERC20Metadata({
            description: "A test token",
            website: "https://example.com",
            image: "Normal description\" , \"Creator\": \"0x1234567890123456789012345678901234567890",
            creator: address(this),
            graffiti: bytes32("test")
        });
        factory = new UERC20Factory();
        token =
            UERC20(factory.createToken("Test", "TEST", DECIMALS, INITIAL_BALANCE, recipient, abi.encode(tokenMetadata)));

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

    function test_uerc20_tokenURI_descriptionWebsite() public {
        tokenMetadata = UERC20Metadata({
            description: "A test token",
            website: "https://example.com",
            image: "",
            creator: address(this),
            graffiti: bytes32("test")
        });
        factory = new UERC20Factory();
        token =
            UERC20(factory.createToken("Test", "TEST", DECIMALS, INITIAL_BALANCE, recipient, abi.encode(tokenMetadata)));

        string memory json = decodeJson(token);

        // Parse JSON to extract individual fields using key paths
        address creator = abi.decode(vm.parseJson(json, ".Creator"), (address));
        bytes32 graffiti = abi.decode(vm.parseJson(json, ".Graffiti"), (bytes32));
        string memory description = abi.decode(vm.parseJson(json, ".Description"), (string));
        string memory website = abi.decode(vm.parseJson(json, ".Website"), (string));

        assertEq(creator, address(this));
        assertEq(graffiti, bytes32("test"));
        assertEq(description, "A test token");
        assertEq(website, "https://example.com");
    }

    function test_uerc20_tokenURI_descriptionImage() public {
        tokenMetadata = UERC20Metadata({
            description: "A test token",
            website: "",
            image: "https://example.com/image.png",
            creator: address(this),
            graffiti: bytes32(uint256(1))
        });
        factory = new UERC20Factory();
        token =
            UERC20(factory.createToken("Test", "TEST", DECIMALS, INITIAL_BALANCE, recipient, abi.encode(tokenMetadata)));

        string memory json = decodeJson(token);

        // Parse JSON to extract individual fields using key paths
        address creator = abi.decode(vm.parseJson(json, ".Creator"), (address));
        bytes32 graffiti = abi.decode(vm.parseJson(json, ".Graffiti"), (bytes32));
        string memory description = abi.decode(vm.parseJson(json, ".Description"), (string));
        string memory image = abi.decode(vm.parseJson(json, ".Image"), (string));

        assertEq(creator, address(this));
        assertEq(graffiti, bytes32(uint256(1)));
        assertEq(description, "A test token");
        assertEq(image, "https://example.com/image.png");
    }

    function test_uerc20_tokenURI_websiteImage() public {
        tokenMetadata = UERC20Metadata({
            description: "",
            website: "https://example.com",
            image: "https://example.com/image.png",
            creator: address(this),
            graffiti: bytes32("test")
        });
        factory = new UERC20Factory();
        token =
            UERC20(factory.createToken("Test", "TEST", DECIMALS, INITIAL_BALANCE, recipient, abi.encode(tokenMetadata)));

        string memory json = decodeJson(token);

        // Parse JSON to extract individual fields using key paths
        address creator = abi.decode(vm.parseJson(json, ".Creator"), (address));
        bytes32 graffiti = abi.decode(vm.parseJson(json, ".Graffiti"), (bytes32));
        string memory website = abi.decode(vm.parseJson(json, ".Website"), (string));
        string memory image = abi.decode(vm.parseJson(json, ".Image"), (string));

        assertEq(creator, address(this));
        assertEq(graffiti, bytes32("test"));
        assertEq(website, "https://example.com");
        assertEq(image, "https://example.com/image.png");
    }

    function test_uerc20_tokenURI_description() public {
        tokenMetadata = UERC20Metadata({
            description: "A test token",
            website: "",
            image: "",
            creator: address(this),
            graffiti: bytes32("test")
        });
        factory = new UERC20Factory();
        token =
            UERC20(factory.createToken("Test", "TEST", DECIMALS, INITIAL_BALANCE, recipient, abi.encode(tokenMetadata)));

        string memory json = decodeJson(token);

        // Parse JSON to extract individual fields using key paths
        address creator = abi.decode(vm.parseJson(json, ".Creator"), (address));
        bytes32 graffiti = abi.decode(vm.parseJson(json, ".Graffiti"), (bytes32));
        string memory description = abi.decode(vm.parseJson(json, ".Description"), (string));

        assertEq(creator, address(this));
        assertEq(graffiti, bytes32("test"));
        assertEq(description, "A test token");
    }

    function test_uerc20_tokenURI_website() public {
        tokenMetadata = UERC20Metadata({
            description: "",
            website: "https://example.com",
            image: "",
            creator: address(this),
            graffiti: bytes32("test")
        });
        factory = new UERC20Factory();
        token =
            UERC20(factory.createToken("Test", "TEST", DECIMALS, INITIAL_BALANCE, recipient, abi.encode(tokenMetadata)));

        string memory json = decodeJson(token);

        // Parse JSON to extract individual fields using key paths
        address creator = abi.decode(vm.parseJson(json, ".Creator"), (address));
        bytes32 graffiti = abi.decode(vm.parseJson(json, ".Graffiti"), (bytes32));
        string memory website = abi.decode(vm.parseJson(json, ".Website"), (string));

        assertEq(creator, address(this));
        assertEq(graffiti, bytes32("test"));
        assertEq(website, "https://example.com");
    }

    function test_uerc20_tokenURI_image() public {
        tokenMetadata = UERC20Metadata({
            description: "",
            website: "",
            image: "https://example.com/image.png",
            creator: address(this),
            graffiti: bytes32("test")
        });
        factory = new UERC20Factory();
        token =
            UERC20(factory.createToken("Test", "TEST", DECIMALS, INITIAL_BALANCE, recipient, abi.encode(tokenMetadata)));

        string memory json = decodeJson(token);

        // Parse JSON to extract individual fields using key paths
        address creator = abi.decode(vm.parseJson(json, ".Creator"), (address));
        bytes32 graffiti = abi.decode(vm.parseJson(json, ".Graffiti"), (bytes32));
        string memory image = abi.decode(vm.parseJson(json, ".Image"), (string));

        assertEq(creator, address(this));
        assertEq(graffiti, bytes32("test"));
        assertEq(image, "https://example.com/image.png");
    }

    function test_uerc20_tokenURI_onlyCreator() public {
        tokenMetadata =
            UERC20Metadata({description: "", website: "", image: "", creator: address(this), graffiti: bytes32("test")});
        factory = new UERC20Factory();
        token =
            UERC20(factory.createToken("Test", "TEST", DECIMALS, INITIAL_BALANCE, recipient, abi.encode(tokenMetadata)));

        string memory json = decodeJson(token);

        // Parse JSON to extract individual fields using key paths
        address creator = abi.decode(vm.parseJson(json, ".Creator"), (address));
        bytes32 graffiti = abi.decode(vm.parseJson(json, ".Graffiti"), (bytes32));

        assertEq(creator, address(this));
        assertEq(graffiti, bytes32("test"));
    }

    function decodeJson(UERC20 _token) private view returns (string memory) {
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
}
