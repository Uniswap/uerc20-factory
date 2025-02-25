// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Base64} from "openzeppelin-contracts/contracts/utils/Base64.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";

struct TokenMetadata {
    string description;
    string website;
    string image;
    address creator;
}

library TokenMetadataLibrary {
    using Strings for address;

    function toJSON(TokenMetadata memory metadata) public pure returns (string memory) {
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(formatJSON(metadata)))));
    }

    function formatJSON(TokenMetadata memory metadata) private pure returns (string memory) {
        string memory json = string.concat('{"Creator":"', metadata.creator.toChecksumHexString(), '"');

        if (bytes(metadata.description).length > 0) {
            json = string.concat(json, ', "Description":"', metadata.description, '"');
        }
        if (bytes(metadata.website).length > 0) {
            json = string.concat(json, ', "Website":"', metadata.website, '"');
        }
        if (bytes(metadata.image).length > 0) {
            json = string.concat(json, ', "Image":"', metadata.image, '"');
        }

        return string.concat(json, "}");
    }
}
