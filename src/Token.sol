// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {SuperchainERC20} from "./SuperchainERC20.sol";

contract Token is SuperchainERC20 {
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply,
        address _recipient,
        uint256 _homeChainId
    ) SuperchainERC20(_name, _symbol) {
        // Mint tokens only on the home chain to ensure the total supply remains consistent across all chains
        if (block.chainid == _homeChainId) {
            _mint(_recipient, _totalSupply);
        }
    }
}
