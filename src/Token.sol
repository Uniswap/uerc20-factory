// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {ERC20} from "solmate/tokens/ERC20.sol";

contract Token is ERC20 {
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply,
        address _recipient,
        uint256 _homeChainId
    ) ERC20(_name, _symbol, 18) {
        if (block.chainid == _homeChainId) {
            _mint(_recipient, _totalSupply);
        }
    }
}
