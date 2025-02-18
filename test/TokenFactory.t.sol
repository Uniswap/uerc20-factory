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

        Token token = factory.create(name, symbol, totalSupply, recipient, homeChainId);

        assert(address(token) != address(0));

        assertEq(token.name(), name);
        assertEq(token.symbol(), symbol);
        assertEq(token.decimals(), 18);
        assertEq(token.totalSupply(), totalSupply);
        assertEq(token.balanceOf(recipient), totalSupply);
    }

    function test_create_succeeds_withoutMintOnDifferentChain() public {
        string memory name = "Test Token";
        string memory symbol = "TOKEN";
        uint256 totalSupply = 1e18;
        address recipient = makeAddr("recipient");

        // the home chain of this token is different than the current chain
        uint256 homeChainId = block.chainid + 1;

        Token token = factory.create(name, symbol, totalSupply, recipient, homeChainId);

        assert(address(token) != address(0));

        assertEq(token.name(), name);
        assertEq(token.symbol(), symbol);
        assertEq(token.decimals(), 18);

        // no tokens have been minted because the current chain is not the token's home chain
        assertEq(token.totalSupply(), 0);
        assertEq(token.balanceOf(recipient), 0);
    }
}
