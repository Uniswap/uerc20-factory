// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/// @notice Account balance ledger. Low-level storage type with no policy or events;
/// the composing token owns validation and event emission.
struct Balances {
    mapping(address account => uint256 amount) inner;
}

using {read, increase, decrease} for Balances global;

/// @notice Returns the balance of `account`.
function read(Balances storage self, address account) view returns (uint256) {
    return self.inner[account];
}

/// @notice Credits `amount` to `account`.
function increase(Balances storage self, address account, uint256 amount) {
    self.inner[account] += amount;
}

/// @notice Debits `amount` from `account`. Reverts (checked arithmetic) if the balance is insufficient.
function decrease(Balances storage self, address account, uint256 amount) {
    self.inner[account] -= amount;
}
