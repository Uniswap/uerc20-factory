// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {SuperchainERC20} from "./base/SuperchainERC20.sol";
import {TokenFactory} from "./TokenFactory.sol";

import {TokenMetadata} from "./types/TokenMetadata.sol";
import {Base64} from "openzeppelin-contracts/contracts/utils/Base64.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";

contract Token is SuperchainERC20 {
    using Strings for uint256;

    TokenMetadata private _metadata;
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        address _recipient,
        uint256 _totalSupply,
        uint256 _homeChainId,
        uint8 _tokenDecimals,
        TokenMetadata memory _tokenMetadata
    ) {
        _name = _tokenName;
        _symbol = _tokenSymbol;
        _decimals = _tokenDecimals;
        _metadata = _tokenMetadata;
        // Mint tokens only on the home chain to ensure the total supply remains consistent across all chains
        if (block.chainid == _homeChainId) {
            _mint(_recipient, _totalSupply);
        }
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function tokenURI() public view returns (string memory) {
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"Name":"',
                            name(),
                            '", "Symbol":"',
                            symbol(),
                            '", "Description":"',
                            _metadata.description,
                            '", "Website":"',
                            _metadata.website,
                            '", "Image":"',
                            _metadata.image,
                            '", "Creator":"',
                            addressToString(_metadata.creator),
                            '"}'
                        )
                    )
                )
            )
        );
    }

    function addressToString(address addr) internal pure returns (string memory) {
        return (uint256(uint160(addr))).toHexString(20);
    }
}
