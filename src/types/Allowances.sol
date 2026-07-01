// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/// @dev Canonical Permit2, identical across chains. Verify with `cast code` before mainnet use.
address constant PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;

/// @notice ERC20 allowance ledger. Permit2 always reads as an infinite allowance and is never
/// decremented on spend (matching Solady semantics).
struct Allowances {
    mapping(address owner => mapping(address spender => uint256 amount)) inner;
}

using {read, write, spend} for Allowances global;

function read(Allowances storage self, address owner, address spender) view returns (uint256) {
    if (spender == PERMIT2) return type(uint256).max;
    return self.inner[owner][spender];
}

function write(Allowances storage self, address owner, address spender, uint256 amount) {
    self.inner[owner][spender] = amount;
}

/// @dev Infinite allowances (explicit max, or Permit2) are not decremented. Reverts on overspend.
function spend(Allowances storage self, address owner, address spender, uint256 amount) {
    uint256 allowed = read(self, owner, spender);
    if (allowed != type(uint256).max) {
        self.inner[owner][spender] = allowed - amount;
    }
}
