// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {SuperchainERC20} from "./base/SuperchainERC20.sol";
import {IUniswapSuperchainERC20Factory} from "./interfaces/IUniswapSuperchainERC20Factory.sol";

/// @title UniswapSuperchainERC20
/// @notice ERC20 token contract that is Superchain interop compatible
contract UniswapSuperchainERC20 is UniswapERC20, SuperchainERC20 {
    uint256 public immutable homeChainId; // The chain where totalSupply is minted and metadata is stored

    function _fetchAndProcessParameters() internal override {
        IUniswapSuperchainERC20Factory.Parameters memory params =
            IUniswapSuperchainERC20Factory(msg.sender).getParameters();

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
