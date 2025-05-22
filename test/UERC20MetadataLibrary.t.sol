// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {UERC20MetadataLibrary, UERC20Metadata} from "../src/libraries/UERC20MetadataLibrary.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

contract UERC20MetadataLibraryTest is Test {
    using UERC20MetadataLibrary for UERC20Metadata;

    function testToJSON_ValidMetadata() public pure {
        UERC20Metadata memory metadata = UERC20Metadata({
            creator: address(0x1234),
            description: "Test Token",
            website: "https://example.com",
            image: "https://example.com/image.png"
        });

        string memory result = metadata.toJSON();

        // Expected JSON with all fields
        string memory expectedJson =
            '{"Creator":"0x0000000000000000000000000000000000001234", "Description":"Test Token", "Website":"https://example.com", "Image":"https://example.com/image.png"}';
        string memory expectedBase64 = Base64.encode(bytes(expectedJson));
        string memory expected = string(abi.encodePacked("data:application/json;base64,", expectedBase64));

        assertEq(result, expected);
    }

    function testToJSON_EmptyMetadata() public pure {
        UERC20Metadata memory metadata = UERC20Metadata({creator: address(0), description: "", website: "", image: ""});

        string memory result = metadata.toJSON();

        // Expected JSON for empty metadata
        string memory expectedJson = "{}";
        string memory expectedBase64 = Base64.encode(bytes(expectedJson));
        string memory expected = string(abi.encodePacked("data:application/json;base64,", expectedBase64));

        assertEq(result, expected);
    }

    function testToJSON_PartialMetadata() public pure {
        UERC20Metadata memory metadata =
            UERC20Metadata({creator: address(0x1234), description: "Test Token", website: "", image: ""});

        string memory result = metadata.toJSON();

        // Expected JSON with only creator and description fields
        string memory expectedJson =
            '{"Creator":"0x0000000000000000000000000000000000001234", "Description":"Test Token"}';
        string memory expectedBase64 = Base64.encode(bytes(expectedJson));
        string memory expected = string(abi.encodePacked("data:application/json;base64,", expectedBase64));

        assertEq(result, expected);
    }
}
