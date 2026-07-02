// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/// @notice Optional token metadata. `extraData` is stored on-chain but not rendered in the JSON.
struct Metadata {
    string description;
    string website;
    string image;
    bytes extraData;
}

using {toJSON} for Metadata global;

/// @notice Base64-encoded JSON data URI of the metadata; empty fields are omitted.
function toJSON(Metadata memory self) pure returns (string memory) {
    return string(abi.encodePacked("data:application/json;base64,", Base64.encode(_displayMetadata(self))));
}

function _displayMetadata(Metadata memory self) pure returns (bytes memory) {
    bytes memory json = abi.encodePacked("{");
    bool hasField;

    if (bytes(self.description).length > 0) {
        json = abi.encodePacked(json, '"description":"', Strings.escapeJSON(self.description), '"');
        hasField = true;
    }
    if (bytes(self.website).length > 0) {
        if (hasField) json = abi.encodePacked(json, ", ");
        json = abi.encodePacked(json, '"website":"', Strings.escapeJSON(self.website), '"');
        hasField = true;
    }
    if (bytes(self.image).length > 0) {
        if (hasField) json = abi.encodePacked(json, ", ");
        json = abi.encodePacked(json, '"image":"', Strings.escapeJSON(self.image), '"');
    }

    return abi.encodePacked(json, "}");
}
