// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {ERC20} from "solmate/tokens/ERC20.sol";

contract Token is ERC20 {
    constructor(string memory name, string memory symbol, uint256 totalSupply, address recipient, uint256 homeChainId)
        ERC20(name, symbol, 18)
    {
        if (block.chainid == homeChainId) {
            _mint(recipient, totalSupply);
        }
    }
}
