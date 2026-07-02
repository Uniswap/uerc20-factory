// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/// @notice Transfer-restriction extension: transfers are blocked unless unlocked globally or a party
/// is allowlisted. State only — the composing token owns access control and events.
struct Lockup {
    bool unlocked;
    address owner;
    mapping(address account => bool ok) allowed;
}

using {allowlisted, isAllowlisted, allowlist, unlock, setOwner} for Lockup global;

/// @notice Whether a transfer between `from` and `to` is permitted (true also when globally unlocked).
function allowlisted(Lockup storage self, address from, address to) view returns (bool) {
    return self.unlocked || self.allowed[from] || self.allowed[to];
}

/// @notice Whether `account` is on the allowlist.
function isAllowlisted(Lockup storage self, address account) view returns (bool) {
    return self.allowed[account];
}

function allowlist(Lockup storage self, address account, bool ok) {
    self.allowed[account] = ok;
}

function unlock(Lockup storage self) {
    self.unlocked = true;
}

function setOwner(Lockup storage self, address newOwner) {
    self.owner = newOwner;
}
