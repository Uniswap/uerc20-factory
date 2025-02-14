// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {TokenFactory} from "../src/TokenFactory.sol";
import {Token} from "../src/Token.sol";

contract TokenFactoryTest is Test {
    TokenFactory public factory;

    function setUp() public {
        factory = new TokenFactory();
    }

    function test_create_succeeds_withMint() public {
        string memory name = "Test Token";
        string memory symbol = "TOKEN";
        uint256 totalSupply = 1e18;
        address recipient = makeAddr("recipient");
        uint256 homeChainId = block.chainid;

        Token tokenAddress = factory.create(name, symbol, totalSupply, recipient, homeChainId);

        assert(address(tokenAddress) != address(0));

        assertEq(tokenAddress.name(), name);
        assertEq(tokenAddress.symbol(), symbol);
        assertEq(tokenAddress.decimals(), 18);
        assertEq(tokenAddress.totalSupply(), totalSupply);
        assertEq(tokenAddress.balanceOf(recipient), totalSupply);
    }

    function test_create_succeeds_withoutMintOnDifferentChain() public {
        string memory name = "Test Token";
        string memory symbol = "TOKEN";
        uint256 totalSupply = 1e18;
        address recipient = makeAddr("recipient");

        // the home chain of this token is different than the current chain
        uint256 homeChainId = block.chainid + 1;

        Token tokenAddress = factory.create(name, symbol, totalSupply, recipient, homeChainId);

        assert(address(tokenAddress) != address(0));

        assertEq(tokenAddress.name(), name);
        assertEq(tokenAddress.symbol(), symbol);
        assertEq(tokenAddress.decimals(), 18);

        // no tokens have been minted because the current chain is not the token's home chain
        assertEq(tokenAddress.totalSupply(), 0);
        assertEq(tokenAddress.balanceOf(recipient), 0);
    }
}
