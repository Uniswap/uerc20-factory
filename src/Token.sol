// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {SuperchainERC20} from "./base/SuperchainERC20.sol";
import {TokenMetadata, TokenMetadataLibrary} from "./libraries/TokenMetadata.sol";

contract Token is SuperchainERC20 {
    using TokenMetadataLibrary for TokenMetadata;

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
        return _metadata.toJSON();
    }
}
