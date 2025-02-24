// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {SuperchainERC20} from "./SuperchainERC20.sol";

contract Token is SuperchainERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint8 _tokenDecimals,
        uint256 _totalSupply,
        address _recipient,
        uint256 _homeChainId
    ) {
        _name = _tokenName;
        _symbol = _tokenSymbol;
        _decimals = _tokenDecimals;
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
}
