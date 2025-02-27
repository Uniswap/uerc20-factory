// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {UniswapERC20Factory} from "../src/UniswapERC20Factory.sol";
import {UniswapERC20} from "../src/UniswapERC20.sol";
import {UniswapERC20Metadata} from "../src/libraries/UniswapERC20Metadata.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";

contract UniswapERC20FactoryTest is Test {
    UniswapERC20Factory public factory;
    UniswapERC20Metadata public tokenMetadata;
    address recipient = makeAddr("recipient");
    string name = "Test Token";
    string symbol = "TOKEN";
    uint8 decimals = 18;

    event UniswapERC20Created(
        address indexed tokenAddress,
        uint256 indexed chainId,
        string name,
        string symbol,
        uint8 decimals,
        uint256 homeChainId
    );

    function setUp() public {
        factory = new UniswapERC20Factory();
        tokenMetadata = UniswapERC20Metadata({
            description: "A test token",
            website: "https://example.com",
            image: "https://example.com/image.png",
            creator: address(this)
        });
    }

    /// forge-config: default.isolate = true
    function test_create_succeeds_withMint() public {
        UniswapERC20 token = factory.create(name, symbol, decimals, recipient, 1e18, block.chainid, tokenMetadata);
        vm.snapshotGasLastCall("deploy new token");

        assert(address(token) != address(0));

        assertEq(token.name(), name);
        assertEq(token.symbol(), symbol);
        assertEq(token.decimals(), decimals);
        assertEq(token.totalSupply(), 1e18);
        assertEq(token.balanceOf(recipient), 1e18);
    }

    function test_create_succeeds_withoutMintOnDifferentChain() public {
        UniswapERC20 token = factory.create(name, symbol, decimals, recipient, 1e18, block.chainid + 1, tokenMetadata); // the home chain of this token is different than the current chain

        assert(address(token) != address(0));

        assertEq(token.name(), name);
        assertEq(token.symbol(), symbol);
        assertEq(token.decimals(), decimals);

        // no tokens have been minted because the current chain is not the token's home chain
        assertEq(token.totalSupply(), 0);
        assertEq(token.balanceOf(recipient), 0);
    }

    function test_getTokenAddress_succeeds() public {
        // Calculate expected address using getTokenAddress and verify against actual deployment
        address expectedAddress = factory.getTokenAddress(name, symbol, decimals, block.chainid, tokenMetadata);

        UniswapERC20 token = factory.create(name, symbol, decimals, recipient, 1e18, block.chainid, tokenMetadata);

        assertEq(address(token), expectedAddress);
    }

    function test_create_succeeds_withEventEmitted() public {
        address tokenAddress = factory.getTokenAddress(name, symbol, decimals, block.chainid, tokenMetadata);

        vm.expectEmit(true, true, true, true);
        emit UniswapERC20Created(tokenAddress, block.chainid, name, symbol, decimals, block.chainid);
        factory.create(name, symbol, decimals, recipient, 1e18, block.chainid, tokenMetadata);
    }

    function test_create_succeeds_withDifferentAddresses() public {
        // Deploy first token
        UniswapERC20 token = factory.create(name, symbol, decimals, recipient, 1e18, block.chainid, tokenMetadata);

        // Deploy second token with different symbol
        string memory differentSymbol = "TOKEN2";
        address expectedNewAddress =
            factory.getTokenAddress(name, differentSymbol, decimals, block.chainid, tokenMetadata);
        UniswapERC20 newToken = factory.create(name, differentSymbol, decimals, recipient, 1e18, block.chainid, tokenMetadata);

        assertEq(address(newToken), expectedNewAddress);
        assertNotEq(address(newToken), address(token));
    }

    function test_create_revertsWithCreateCollision() public {
        factory.create(name, symbol, decimals, recipient, 1e18, block.chainid, tokenMetadata);

        vm.expectRevert();
        factory.create(name, symbol, decimals, recipient, 1e18, block.chainid, tokenMetadata);
    }

    // function test_differentMetadata_sameAddress() public {
    //     // Create a token with certain metadata
    //     address originalAddr = factory.getTokenAddress(name, symbol, decimals, block.chainid, tokenMetadata);
    //     UniswapERC20 originalToken = factory.create(name, symbol, decimals, recipient, 1e18, block.chainid, tokenMetadata);

    //     // Create tokenMetadata with different description but same creator
    //     UniswapERC20Metadata memory differentMetadata = UniswapERC20Metadata({
    //         description: "A different description",
    //         website: "https://different.com",
    //         image: "https://different.com/image.png",
    //         creator: tokenMetadata.creator
    //     });

    //     // Calculate address with different metadata
    //     address newAddr = factory.getTokenAddress(name, symbol, decimals, block.chainid, differentMetadata);

    //     // Addresses should be the same since only the core parameters affect the address
    //     assertEq(newAddr, originalAddr);
    // }

    function test_bytecodeSize_factory() public {
        vm.snapshotValue("TokenFactory bytecode size", address(factory).code.length);
    }

    function test_bytecodeSize_token() public {
        UniswapERC20 token = factory.create(name, symbol, decimals, recipient, 1e18, block.chainid, tokenMetadata);
        vm.snapshotValue("Token bytecode size", address(token).code.length);
    }
}
