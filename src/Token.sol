// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {IERC7802, IERC165} from "../interfaces/IERC7802.sol";

contract Token is ERC20, IERC7802 {
    address public constant SUPERCHAIN_ERC20_BRIDGE = 0x4200000000000000000000000000000000000028;

    error OnlySuperchainERC20Bridge(address sender, address bridge);

    modifier onlySuperchainERC20Bridge() {
        if (msg.sender != SUPERCHAIN_ERC20_BRIDGE) revert OnlySuperchainERC20Bridge(msg.sender, SUPERCHAIN_ERC20_BRIDGE);
        _;
    }

    constructor(string memory name, string memory symbol) ERC20(name, symbol, 18) {}

    /// @inheritdoc IERC7802
    function crosschainMint(address _to, uint256 _amount) external onlySuperchainERC20Bridge {
        _mint(_to, _amount);

        emit CrosschainMint(_to, _amount, msg.sender);
    }

    /// @inheritdoc IERC7802
    function crosschainBurn(address _from, uint256 _amount) external onlySuperchainERC20Bridge {
        _burn(_from, _amount);

        emit CrosschainBurn(_from, _amount, msg.sender);
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return interfaceId == type(IERC7802).interfaceId || interfaceId == type(IERC165).interfaceId;
    }
}
