// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/// @notice Transfer-restriction extension: all transfers are blocked unless the lock has been globally
/// unlocked, or one of the parties is on the allowlist. State only — the composing token owns access
/// control (who may mutate this) and event emission.
struct Lockup {
    bool unlocked;
    address owner;
    mapping(address account => bool ok) allowed;
}

using {allowlisted, isAllowlisted, allowlist, unlock, setOwner} for Lockup global;

/// @notice Whether a transfer between `from` and `to` is currently permitted.
/// @dev Returns true if the lock is globally unlocked, OR either party is on the allowlist — so a
/// true result does not by itself imply either address is allowlisted.
function allowlisted(Lockup storage self, address from, address to) view returns (bool) {
    return self.unlocked || self.allowed[from] || self.allowed[to];
}

/// @notice Whether `account` is on the allowlist.
function isAllowlisted(Lockup storage self, address account) view returns (bool) {
    return self.allowed[account];
}

/// @notice Sets `account`'s allowlist status.
function allowlist(Lockup storage self, address account, bool ok) {
    self.allowed[account] = ok;
}

/// @notice Unlocks transfers globally; all transfers are permitted thereafter.
function unlock(Lockup storage self) {
    self.unlocked = true;
}

/// @notice Sets the owner permitted to manage the lock.
function setOwner(Lockup storage self, address newOwner) {
    self.owner = newOwner;
}
