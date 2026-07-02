// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {Metadata} from "../../src/types/Metadata.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

/// @notice Isolated tests for the `Metadata` type's JSON rendering (logic ported verbatim from the
/// former UERC20MetadataLibrary).
contract MetadataTest is Test {
    function testToJSON_ValidMetadata() public pure {
        Metadata memory metadata = Metadata({
            description: "Test Token",
            website: "https://example.com",
            image: "https://example.com/image.png",
            extraData: hex"1234"
        });

        string memory expectedJson =
            '{"description":"Test Token", "website":"https://example.com", "image":"https://example.com/image.png"}';
        string memory expected =
            string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(expectedJson))));

        assertEq(metadata.toJSON(), expected);
    }

    function testToJSON_EmptyMetadata() public pure {
        Metadata memory metadata = Metadata({description: "", website: "", image: "", extraData: ""});

        string memory expected = string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes("{}"))));

        assertEq(metadata.toJSON(), expected);
    }

    function testToJSON_PartialMetadata() public pure {
        Metadata memory metadata = Metadata({description: "Test Token", website: "", image: "", extraData: hex"1234"});

        string memory expected = string(
            abi.encodePacked("data:application/json;base64,", Base64.encode(bytes('{"description":"Test Token"}')))
        );

        assertEq(metadata.toJSON(), expected);
    }
}
