// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/// @notice Account balance ledger.
struct Balances {
    mapping(address account => uint256 amount) inner;
}

using {read, increase, decrease} for Balances global;

function read(Balances storage self, address account) view returns (uint256) {
    return self.inner[account];
}

function increase(Balances storage self, address account, uint256 amount) {
    self.inner[account] += amount;
}

/// @dev Reverts on insufficient balance (checked arithmetic).
function decrease(Balances storage self, address account, uint256 amount) {
    self.inner[account] -= amount;
}
