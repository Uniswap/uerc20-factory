// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Balances} from "./Balances.sol";
import {Allowances} from "./Allowances.sol";

/// @notice Core fungible-token state: total supply plus the balance and allowance ledgers. Supply is
/// folded in so the `sum(balances) == supply` invariant is maintained in one place.
struct Token {
    uint256 supply;
    Balances balances;
    Allowances allowances;
}

using {totalSupply, balanceOf, allowanceOf, approve, transfer, transferFrom, mint, burn} for Token global;

function totalSupply(Token storage self) view returns (uint256) {
    return self.supply;
}

function balanceOf(Token storage self, address account) view returns (uint256) {
    return self.balances.read(account);
}

function allowanceOf(Token storage self, address owner, address spender) view returns (uint256) {
    return self.allowances.read(owner, spender);
}

function approve(Token storage self, address owner, address spender, uint256 amount) {
    self.allowances.write(owner, spender, amount);
}

function transfer(Token storage self, address from, address to, uint256 amount) {
    self.balances.decrease(from, amount);
    self.balances.increase(to, amount);
}

function transferFrom(Token storage self, address spender, address from, address to, uint256 amount) {
    self.allowances.spend(from, spender, amount);
    self.balances.decrease(from, amount);
    self.balances.increase(to, amount);
}

function mint(Token storage self, address to, uint256 amount) {
    self.supply += amount;
    self.balances.increase(to, amount);
}

function burn(Token storage self, address from, uint256 amount) {
    self.balances.decrease(from, amount);
    self.supply -= amount;
}
