// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Balances} from "./Balances.sol";
import {Allowances} from "./Allowances.sol";

/// @notice The core fungible-token state: total supply plus the balance and allowance ledgers.
/// All standard ERC20 money movement is expressed here as free functions; feature contracts
/// compose this type and wire their external ABI to it. Supply is folded in (rather than a
/// separate type) so the `sum(balances) == supply` invariant is maintained in one place.
struct Token {
    uint256 supply;
    Balances balances;
    Allowances allowances;
}

using {totalSupply, balanceOf, allowanceOf, approve, transfer, transferFrom, mint, burn} for Token global;

/// @notice Returns the total supply.
function totalSupply(Token storage self) view returns (uint256) {
    return self.supply;
}

/// @notice Returns the balance of `account`.
function balanceOf(Token storage self, address account) view returns (uint256) {
    return self.balances.read(account);
}

/// @notice Returns the effective allowance from `owner` to `spender`.
function allowanceOf(Token storage self, address owner, address spender) view returns (uint256) {
    return self.allowances.read(owner, spender);
}

/// @notice Sets `owner`'s allowance to `spender`.
function approve(Token storage self, address owner, address spender, uint256 amount) {
    self.allowances.write(owner, spender, amount);
}

/// @notice Moves `amount` from `from` to `to`. Reverts on insufficient balance.
function transfer(Token storage self, address from, address to, uint256 amount) {
    self.balances.decrease(from, amount);
    self.balances.increase(to, amount);
}

/// @notice Spends `spender`'s allowance then moves `amount` from `from` to `to`.
function transferFrom(Token storage self, address spender, address from, address to, uint256 amount) {
    self.allowances.spend(from, spender, amount);
    self.balances.decrease(from, amount);
    self.balances.increase(to, amount);
}

/// @notice Mints `amount` to `to`, increasing total supply.
function mint(Token storage self, address to, uint256 amount) {
    self.supply += amount;
    self.balances.increase(to, amount);
}

/// @notice Burns `amount` from `from`, decreasing total supply. Reverts on insufficient balance.
function burn(Token storage self, address from, uint256 amount) {
    self.balances.decrease(from, amount);
    self.supply -= amount;
}
