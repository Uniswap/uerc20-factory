// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {SuperchainERC20} from "./base/SuperchainERC20.sol";
import {IUERC20SuperchainFactory} from "./interfaces/IUERC20SuperchainFactory.sol";

/// @title UERC20Superchain
/// @notice ERC20 token contract that is Superchain interop compatible
contract UERC20Superchain is UERC20, SuperchainERC20 {
    uint256 public immutable homeChainId; // The chain where totalSupply is minted and metadata is stored

    // Override _initialize function in UERC20 to additionally fetch homeChainId
    // Mint total supply conditionally if the current chain is the home chain
    function _initialize() internal override {
        IUERC20SuperchainFactory.Parameters memory params = IUERC20SuperchainFactory(msg.sender).getParameters();

        homeChainId = params.homeChainId;
        _name = params.name;
        _symbol = params.symbol;
        _decimals = params.decimals;
        _metadata = params.metadata;

        // Mint tokens only on the home chain to ensure the total supply remains consistent across all chains
        if (block.chainid == params.homeChainId) {
            _mint(params.recipient, params.totalSupply);
        }
    }
}
