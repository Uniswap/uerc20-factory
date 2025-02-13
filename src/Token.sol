// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {ERC20} from "solmate/tokens/ERC20.sol";

contract Token is ERC20 {
    address constant PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;

    constructor(string memory name, string memory symbol) ERC20(name, symbol, 18) {}

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        if (msg.sender == PERMIT2) {
            balanceOf[from] -= amount;
            unchecked {
                balanceOf[to] += amount;
            }
            emit Transfer(from, to, amount);
            return true;
        }
        return super.transferFrom(from, to, amount);
    }
}
