// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Token} from "./Token.sol";
import {Permit} from "./Permit.sol";
import {Metadata} from "./Metadata.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice Reverts when the initial-supply recipient is the zero address.
error RecipientCannotBeZeroAddress();
/// @notice Reverts when the configured total supply is zero.
error TotalSupplyCannotBeZero();

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

using {initBase} for UERC20Config global;

/// @notice Validates the shared config, caches the EIP-712 domain, and performs the initial mint.
/// @dev Every feature constructor calls this so the base-token setup — and its invariants — lives in
/// one place. The mint and its `Transfer` event are kept atomic here. The caller passes its own
/// address for the permit domain and still assigns its own identity fields (which, being immutable,
/// must be set in the constructor) plus any feature-specific setup.
/// @param self The decoded base config.
/// @param token The composing token's core state.
/// @param permit The composing token's permit state.
/// @param verifyingContract The composing token's own address (EIP-712 domain).
function initBase(UERC20Config memory self, Token storage token, Permit storage permit, address verifyingContract) {
    if (self.recipient == address(0)) revert RecipientCannotBeZeroAddress();
    if (self.totalSupply == 0) revert TotalSupplyCannotBeZero();

    permit.init(self.name, verifyingContract);
    token.mint(self.recipient, self.totalSupply);
    emit IERC20.Transfer(address(0), self.recipient, self.totalSupply);
}
