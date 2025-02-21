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
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"Description":"',
                            metadata.description,
                            '", "Website":"',
                            metadata.website,
                            '", "Image":"',
                            metadata.image,
                            '", "Creator":"',
                            metadata.creator.toHexString(),
                            '"}'
                        )
                    )
                )
            )
        );
    }
}
