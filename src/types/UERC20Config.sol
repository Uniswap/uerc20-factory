// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Metadata} from "./Metadata.sol";

/// @notice Shared base config for every UERC20. Feature tokens nest it, e.g.
/// `struct Config { UERC20Config base; address owner; }`.
struct UERC20Config {
    string name;
    string symbol;
    uint8 decimals;
    uint256 totalSupply;
    address recipient;
    Metadata metadata;
}
