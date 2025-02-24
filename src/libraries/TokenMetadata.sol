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
        bool hasDescription = bytes(metadata.description).length > 0;
        bool hasWebsite = bytes(metadata.website).length > 0;
        bool hasImage = bytes(metadata.image).length > 0;

        if (hasDescription && hasWebsite && hasImage) {
            return displayAllFields(metadata);
        } else if (hasDescription && hasWebsite) {
            return displayWithDescriptionAndWebsite(metadata);
        } else if (hasDescription && hasImage) {
            return displayWithDescriptionAndImage(metadata);
        } else if (hasWebsite && hasImage) {
            return displayWithWebsiteAndImage(metadata);
        } else if (hasDescription) {
            return displayWithDescription(metadata);
        } else if (hasWebsite) {
            return displayWithWebsite(metadata);
        } else if (hasImage) {
            return displayWithImage(metadata);
        } else {
            return displayOnlyCreator(metadata);
        }
    }

    function displayAllFields(TokenMetadata memory metadata) private pure returns (string memory) {
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
                            metadata.creator.toChecksumHexString(),
                            '"}'
                        )
                    )
                )
            )
        );
    }

    function displayWithDescriptionAndWebsite(TokenMetadata memory metadata) private pure returns (string memory) {
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
                            '", "Creator":"',
                            metadata.creator.toChecksumHexString(),
                            '"}'
                        )
                    )
                )
            )
        );
    }

    function displayWithDescriptionAndImage(TokenMetadata memory metadata) private pure returns (string memory) {
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"Description":"',
                            metadata.description,
                            '", "Image":"',
                            metadata.image,
                            '", "Creator":"',
                            metadata.creator.toChecksumHexString(),
                            '"}'
                        )
                    )
                )
            )
        );
    }

    function displayWithWebsiteAndImage(TokenMetadata memory metadata) private pure returns (string memory) {
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"Website":"',
                            metadata.website,
                            '", "Image":"',
                            metadata.image,
                            '", "Creator":"',
                            metadata.creator.toChecksumHexString(),
                            '"}'
                        )
                    )
                )
            )
        );
    }

    function displayWithDescription(TokenMetadata memory metadata) private pure returns (string memory) {
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"Description":"',
                            metadata.description,
                            '", "Creator":"',
                            metadata.creator.toChecksumHexString(),
                            '"}'
                        )
                    )
                )
            )
        );
    }

    function displayWithImage(TokenMetadata memory metadata) private pure returns (string memory) {
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"Image":"', metadata.image, '", "Creator":"', metadata.creator.toChecksumHexString(), '"}'
                        )
                    )
                )
            )
        );
    }

    function displayWithWebsite(TokenMetadata memory metadata) private pure returns (string memory) {
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"Website":"',
                            metadata.website,
                            '", "Creator":"',
                            metadata.creator.toChecksumHexString(),
                            '"}'
                        )
                    )
                )
            )
        );
    }

    function displayOnlyCreator(TokenMetadata memory metadata) private pure returns (string memory) {
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(bytes(abi.encodePacked('{"Creator":"', metadata.creator.toChecksumHexString(), '"}')))
            )
        );
    }
}
