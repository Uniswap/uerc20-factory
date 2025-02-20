// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {ERC20} from "solady/tokens/ERC20.sol";

contract Token is ERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(string memory _tokenName, string memory _tokenSymbol, uint8 _tokenDecimals) {
        _name = _tokenName;
        _symbol = _tokenSymbol;
        _decimals = _tokenDecimals;
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
