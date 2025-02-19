// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {SuperchainERC20} from "./SuperchainERC20.sol";

contract Token is SuperchainERC20 {
    constructor(string memory name, string memory symbol) SuperchainERC20(name, symbol) {}
}
