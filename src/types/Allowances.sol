// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/// @dev Canonical Permit2 address, identical across all chains.
/// Source: Uniswap Permit2 canonical deployment. MUST be `cast code`-verified before mainnet use.
address constant PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;

/// @notice ERC20 allowance ledger with Permit2 default (infinite) allowance, matching Solady semantics:
/// the canonical Permit2 contract always reads as having a `type(uint256).max` allowance and never
/// consumes it on `spend`.
struct Allowances {
    mapping(address owner => mapping(address spender => uint256 amount)) inner;
}

using {read, write, spend} for Allowances global;

/// @notice Returns the effective allowance `owner` has granted `spender`.
/// Permit2 always reads as infinite regardless of stored value.
function read(Allowances storage self, address owner, address spender) view returns (uint256) {
    if (spender == PERMIT2) return type(uint256).max;
    return self.inner[owner][spender];
}

/// @notice Sets the stored allowance from `owner` to `spender`.
function write(Allowances storage self, address owner, address spender, uint256 amount) {
    self.inner[owner][spender] = amount;
}

/// @notice Consumes `amount` of `spender`'s allowance from `owner`. Infinite allowances
/// (explicit max, or Permit2) are not decremented. Reverts (checked arithmetic) on overspend.
function spend(Allowances storage self, address owner, address spender, uint256 amount) {
    uint256 allowed = read(self, owner, spender);
    if (allowed != type(uint256).max) {
        self.inner[owner][spender] = allowed - amount;
    }
}
