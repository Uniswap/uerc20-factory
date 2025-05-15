// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ERC20} from "@solady/src/tokens/ERC20.sol";
import {BaseUERC20} from "../tokens/BaseUERC20.sol";
import {IUERC20SuperchainFactory} from "../interfaces/IUERC20SuperchainFactory.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC7802, IERC165} from "@optimism/interfaces/L2/IERC7802.sol";
import {Predeploys} from "@optimism/src/libraries/Predeploys.sol";

/// @title UERC20Superchain
/// @notice ERC20 token contract that is Superchain interop compatible
contract UERC20Superchain is BaseUERC20, IERC7802 {
    /// @dev The address of the Superchain Token Bridge (0x4200000000000000000000000000000000000028)
    address public constant SUPERCHAIN_TOKEN_BRIDGE = Predeploys.SUPERCHAIN_TOKEN_BRIDGE;

    /// @dev The chain where totalSupply is minted and metadata is stored
    uint256 public immutable homeChainId;

    /// @notice Thrown when the caller is not the Superchain Token Bridge
    error NotSuperchainTokenBridge(address sender, address bridge);

    constructor() {
        IUERC20SuperchainFactory.Parameters memory params = IUERC20SuperchainFactory(msg.sender).getParameters();

        _name = params.name;
        _symbol = params.symbol;
        _decimals = params.decimals;
        homeChainId = params.homeChainId;
        creator = params.creator;
        metadata = params.metadata;

        // Mint tokens only on the home chain to ensure the total supply remains consistent across all chains
        if (block.chainid == params.homeChainId) {
            _mint(params.recipient, params.totalSupply);
        }
    }

    /// @notice Reverts if the caller is not the Superchain Token Bridge
    modifier onlySuperchainTokenBridge() {
        if (msg.sender != Predeploys.SUPERCHAIN_TOKEN_BRIDGE) {
            revert NotSuperchainTokenBridge(msg.sender, Predeploys.SUPERCHAIN_TOKEN_BRIDGE);
        }
        _;
    }

    /// @inheritdoc IERC7802
    function crosschainMint(address _to, uint256 _amount) external onlySuperchainTokenBridge {
        _mint(_to, _amount);

        emit CrosschainMint(_to, _amount, msg.sender);
    }

    /// @inheritdoc IERC7802
    function crosschainBurn(address _from, uint256 _amount) external onlySuperchainTokenBridge {
        _burn(_from, _amount);

        emit CrosschainBurn(_from, _amount, msg.sender);
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 _interfaceId) public view virtual returns (bool) {
        return _interfaceId == type(IERC7802).interfaceId || _interfaceId == type(IERC20).interfaceId
            || _interfaceId == type(IERC165).interfaceId;
    }
}
