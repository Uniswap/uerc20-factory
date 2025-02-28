// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {UniswapERC20} from "./UniswapERC20.sol";
import {IUniswapERC20Factory} from "./interfaces/IUniswapERC20Factory.sol";
import {UniswapERC20Metadata} from "./libraries/UniswapERC20Metadata.sol";
import {Create2} from "openzeppelin-contracts/contracts/utils/Create2.sol";

/// @title UniswapERC20Factory
/// @notice Deploys new UniswapERC20 contracts
contract UniswapERC20Factory is IUniswapERC20Factory {
    /// @dev Parameters stored transiently for token initialization
    Parameters private parameters;

    /// @inheritdoc IUniswapERC20Factory
    function getUniswapERC20Address(
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 homeChainId,
        address creator
    ) external view returns (address) {
        bytes32 salt = keccak256(abi.encode(name, symbol, decimals, homeChainId, creator));
        bytes32 initCodeHash = keccak256(abi.encodePacked(type(UniswapERC20).creationCode));
        return Create2.computeAddress(salt, initCodeHash, address(this));
    }

    /// @inheritdoc IUniswapERC20Factory
    function getParameters() external view returns (Parameters memory) {
        return parameters;
    }

    /// @inheritdoc IUniswapERC20Factory
    function create(
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 homeChainId,
        address recipient,
        uint256 totalSupply,
        UniswapERC20Metadata memory metadata
    ) external returns (UniswapERC20 newUniswapERC20) {
        /// Only the creator can deploy a token on the home chain
        if (block.chainid == homeChainId && msg.sender != metadata.creator) {
            revert NotCreator(msg.sender, metadata.creator);
        }

        // Store parameters transiently for token to access during construction
        parameters = Parameters({
            name: name,
            symbol: symbol,
            totalSupply: totalSupply,
            homeChainId: homeChainId,
            recipient: recipient,
            decimals: decimals,
            metadata: metadata
        });

        // Compute salt based on the core parameters that define a token's identity
        bytes32 salt = keccak256(abi.encode(name, symbol, decimals, homeChainId, metadata.creator));

        // Deploy the token with the computed salt
        newUniswapERC20 = new UniswapERC20{salt: salt}();

        // Clear parameters after deployment
        delete parameters;

        emit UniswapERC20Created(address(newUniswapERC20), block.chainid, name, symbol, decimals, homeChainId);
    }
}
