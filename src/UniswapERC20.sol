// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {SuperchainERC20} from "./base/SuperchainERC20.sol";
import {UniswapERC20Metadata, UniswapERC20MetadataLibrary} from "./libraries/UniswapERC20Metadata.sol";
import {IUniswapERC20Factory} from "./interfaces/IUniswapERC20Factory.sol";

/// @title UniswapERC20
/// @notice ERC20 token contract that is Superchain interop compatible
/// @dev Uses solady for default permit2 approval
contract UniswapERC20 is SuperchainERC20 {
    using UniswapERC20MetadataLibrary for UniswapERC20Metadata;

    // Core parameters that define token identity
    uint256 public immutable homeChainId; // The chain where totalSupply is minted and metadata is stored
    address public immutable creator; // The address that created the token
    uint8 private immutable _decimals;
    string private _name;
    string private _symbol;

    // Metadata that may have extended information
    UniswapERC20Metadata public metadata;

    constructor() {
        // Get parameters from the factory that deployed this token
        IUniswapERC20Factory.Parameters memory params = IUniswapERC20Factory(msg.sender).getParameters();

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

    /// @notice Returns the URI of the token metadata.
    function tokenURI() external view returns (string memory) {
        return metadata.toJSON();
    }

    /// @notice Returns the name of the token.
    function name() public view override returns (string memory) {
        return _name;
    }

    /// @notice Returns the symbol of the token.
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /// @notice Returns the decimals places of the token.
    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}
