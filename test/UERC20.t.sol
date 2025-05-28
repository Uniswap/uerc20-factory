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

    struct JsonTokenAllFields {
        address creator;
        string description;
        string image;
        string website;
    }

    struct JsonTokenDescriptionWebsite {
        address creator;
        string description;
        string website;
    }

    struct JsonTokenDescriptionImage {
        address creator;
        string description;
        string image;
    }

    struct JsonTokenWebsiteImage {
        address creator;
        string image;
        string website;
    }

    struct JsonTokenDescription {
        address creator;
        string description;
    }

    struct JsonTokenWebsite {
        address creator;
        string website;
    }

    struct JsonTokenImage {
        address creator;
        string image;
    }

    struct JsonTokenCreator {
        address creator;
    }

    function setUp() public {
        tokenMetadata = UERC20Metadata({
            description: "A test token",
            website: "https://example.com",
            image: "https://example.com/image.png",
            creator: address(this)
        });
        factory = new UERC20Factory();
        token = UERC20(
            factory.createToken(
                "Test", "TEST", DECIMALS, INITIAL_BALANCE, recipient, abi.encode(tokenMetadata), bytes32("test")
            )
        );
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
        bytes memory data = decode(token);
        JsonTokenAllFields memory jsonToken = abi.decode(data, (JsonTokenAllFields));

        // Parse JSON to extract individual fields
        assertEq(jsonToken.creator, address(this));
        assertEq(jsonToken.description, "A test token");
        assertEq(jsonToken.website, "https://example.com");
        assertEq(jsonToken.image, "https://example.com/image.png");
    }

    function test_uerc20_tokenURI_maliciousInjectionDetected() public {
        tokenMetadata = UERC20Metadata({
            description: "A test token",
            website: "https://example.com",
            image: "Normal description\" , \"Creator\": \"0x1234567890123456789012345678901234567890",
            creator: address(this)
        });
        factory = new UERC20Factory();
        token = UERC20(
            factory.createToken(
                "Test", "TEST", DECIMALS, INITIAL_BALANCE, recipient, abi.encode(tokenMetadata), bytes32("test")
            )
        );

        bytes memory data = decode(token);
        JsonTokenAllFields memory jsonToken = abi.decode(data, (JsonTokenAllFields));

        // Parse JSON to extract individual fields
        assertEq(jsonToken.creator, address(this)); // detects correct creator, not the malicious one
        assertEq(jsonToken.description, "A test token");
        assertEq(jsonToken.website, "https://example.com");
        assertEq(jsonToken.image, "Normal description\" , \"Creator\": \"0x1234567890123456789012345678901234567890");
    }

    function test_uerc20_tokenURI_descriptionWebsite() public {
        tokenMetadata = UERC20Metadata({
            description: "A test token",
            website: "https://example.com",
            image: "",
            creator: address(this)
        });
        factory = new UERC20Factory();
        token = UERC20(
            factory.createToken(
                "Test", "TEST", DECIMALS, INITIAL_BALANCE, recipient, abi.encode(tokenMetadata), bytes32("test")
            )
        );

        bytes memory data = decode(token);
        JsonTokenDescriptionWebsite memory jsonToken = abi.decode(data, (JsonTokenDescriptionWebsite));

        // Parse JSON to extract individual fields
        assertEq(jsonToken.creator, address(this));
        assertEq(jsonToken.description, "A test token");
        assertEq(jsonToken.website, "https://example.com");
    }

    function test_uerc20_tokenURI_descriptionImage() public {
        tokenMetadata = UERC20Metadata({
            description: "A test token",
            website: "",
            image: "https://example.com/image.png",
            creator: address(this)
        });
        factory = new UERC20Factory();
        token = UERC20(
            factory.createToken(
                "Test", "TEST", DECIMALS, INITIAL_BALANCE, recipient, abi.encode(tokenMetadata), bytes32("test")
            )
        );

        bytes memory data = decode(token);
        JsonTokenDescriptionImage memory jsonToken = abi.decode(data, (JsonTokenDescriptionImage));

        // Parse JSON to extract individual fields
        assertEq(jsonToken.creator, address(this));
        assertEq(jsonToken.description, "A test token");
        assertEq(jsonToken.image, "https://example.com/image.png");
    }

    function test_uerc20_tokenURI_websiteImage() public {
        tokenMetadata = UERC20Metadata({
            description: "",
            website: "https://example.com",
            image: "https://example.com/image.png",
            creator: address(this)
        });
        factory = new UERC20Factory();
        token = UERC20(
            factory.createToken(
                "Test", "TEST", DECIMALS, INITIAL_BALANCE, recipient, abi.encode(tokenMetadata), bytes32("test")
            )
        );

        bytes memory data = decode(token);
        JsonTokenWebsiteImage memory jsonToken = abi.decode(data, (JsonTokenWebsiteImage));

        // Parse JSON to extract individual fields
        assertEq(jsonToken.creator, address(this));
        assertEq(jsonToken.website, "https://example.com");
        assertEq(jsonToken.image, "https://example.com/image.png");
    }

    function test_uerc20_tokenURI_description() public {
        tokenMetadata = UERC20Metadata({description: "A test token", website: "", image: "", creator: address(this)});
        factory = new UERC20Factory();
        token = UERC20(
            factory.createToken(
                "Test", "TEST", DECIMALS, INITIAL_BALANCE, recipient, abi.encode(tokenMetadata), bytes32("test")
            )
        );

        bytes memory data = decode(token);
        JsonTokenDescription memory jsonToken = abi.decode(data, (JsonTokenDescription));

        // Parse JSON to extract individual fields
        assertEq(jsonToken.creator, address(this));
        assertEq(jsonToken.description, "A test token");
    }

    function test_uerc20_tokenURI_website() public {
        tokenMetadata =
            UERC20Metadata({description: "", website: "https://example.com", image: "", creator: address(this)});
        factory = new UERC20Factory();
        token = UERC20(
            factory.createToken(
                "Test", "TEST", DECIMALS, INITIAL_BALANCE, recipient, abi.encode(tokenMetadata), bytes32("test")
            )
        );

        bytes memory data = decode(token);
        JsonTokenWebsite memory jsonToken = abi.decode(data, (JsonTokenWebsite));

        // Parse JSON to extract individual fields
        assertEq(jsonToken.creator, address(this));
        assertEq(jsonToken.website, "https://example.com");
    }

    function test_uerc20_tokenURI_image() public {
        tokenMetadata = UERC20Metadata({
            description: "",
            website: "",
            image: "https://example.com/image.png",
            creator: address(this)
        });
        factory = new UERC20Factory();
        token = UERC20(
            factory.createToken(
                "Test", "TEST", DECIMALS, INITIAL_BALANCE, recipient, abi.encode(tokenMetadata), bytes32("test")
            )
        );

        bytes memory data = decode(token);
        JsonTokenImage memory jsonToken = abi.decode(data, (JsonTokenImage));

        // Parse JSON to extract individual fields
        assertEq(jsonToken.creator, address(this));
        assertEq(jsonToken.image, "https://example.com/image.png");
    }

    function test_uerc20_tokenURI_onlyCreator() public {
        tokenMetadata = UERC20Metadata({description: "", website: "", image: "", creator: address(this)});
        factory = new UERC20Factory();
        token = UERC20(
            factory.createToken(
                "Test", "TEST", DECIMALS, INITIAL_BALANCE, recipient, abi.encode(tokenMetadata), bytes32("test")
            )
        );

        bytes memory data = decode(token);
        JsonTokenCreator memory jsonToken = abi.decode(data, (JsonTokenCreator));

        // Parse JSON to extract individual fields
        assertEq(jsonToken.creator, address(this));
    }

    function decode(UERC20 _token) private view returns (bytes memory) {
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

        // decode json
        return vm.parseJson(json);
    }
}
