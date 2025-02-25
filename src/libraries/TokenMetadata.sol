// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Base64} from "openzeppelin-contracts/contracts/utils/Base64.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";

struct TokenMetadata {
    address creator;
    string description;
    string website;
    string image;
}

library TokenMetadataLibrary {
    using Strings for address;

    function toJSON(TokenMetadata memory metadata) public pure returns (string memory) {
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(displayMetadata(metadata))));
    }

    function displayMetadata(TokenMetadata memory metadata) private pure returns (bytes memory) {
        bytes memory json = abi.encodePacked('{"Creator":"', metadata.creator.toChecksumHexString(), '"');

        if (bytes(metadata.description).length > 0) {
            json = abi.encodePacked(json, ', "Description":"', metadata.description, '"');
        }
        if (bytes(metadata.website).length > 0) {
            json = abi.encodePacked(json, ', "Website":"', metadata.website, '"');
        }
        if (bytes(metadata.image).length > 0) {
            json = abi.encodePacked(json, ', "Image":"', metadata.image, '"');
        }

        return abi.encodePacked(json, "}");
    }
}
