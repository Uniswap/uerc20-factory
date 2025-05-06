// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {UniswapSuperchainERC20Factory} from "../src/UniswapSuperchainERC20Factory.sol";
import {UniswapSuperchainERC20} from "../src/UniswapSuperchainERC20.sol";
import {UniswapERC20Metadata} from "../src/libraries/UniswapERC20Metadata.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";
import {IUniswapSuperchainERC20Factory} from "../src/interfaces/IUniswapSuperchainERC20Factory.sol";

contract UniswapSuperchainERC20FactoryTest is Test {
    UniswapSuperchainERC20Factory public factory;
    UniswapERC20Metadata public tokenMetadata;
    address recipient = makeAddr("recipient");
    string name = "Test Token";
    string symbol = "TOKEN";
    uint8 decimals = 18;
    address bob = makeAddr("bob");

    event TokenCreated(address tokenAddress);

    function setUp() public {
        factory = new UniswapSuperchainERC20Factory();
        tokenMetadata = UniswapERC20Metadata({
            description: "A test token",
            website: "https://example.com",
            image: "https://example.com/image.png",
            creator: address(this)
        });
    }

    /// forge-config: default.isolate = true
    function test_create_succeeds_withMint() public {
        UniswapSuperchainERC20 token = UniswapSuperchainERC20(
            factory.createToken(name, symbol, decimals, 1e18, recipient, abi.encode(block.chainid, tokenMetadata))
        );
        vm.snapshotGasLastCall("deploy new token");

        assert(address(token) != address(0));

        assertEq(token.name(), name);
        assertEq(token.symbol(), symbol);
        assertEq(token.decimals(), decimals);
        assertEq(token.totalSupply(), 1e18);
        assertEq(token.balanceOf(recipient), 1e18);
    }

    function test_create_revertsWithNotCreator() public {
        vm.prank(bob);
        vm.expectRevert(
            abi.encodeWithSelector(IUniswapSuperchainERC20Factory.NotCreator.selector, bob, tokenMetadata.creator)
        );
        factory.createToken(name, symbol, decimals, 1e18, recipient, abi.encode(block.chainid, tokenMetadata));
    }

    function test_create_succeeds_withoutMintOnDifferentChain() public {
        UniswapSuperchainERC20 token = UniswapSuperchainERC20(
            factory.createToken(name, symbol, decimals, 1e18, recipient, abi.encode(block.chainid + 1, tokenMetadata))
        ); // the home chain of this token is different than the current chain

        assert(address(token) != address(0));

        assertEq(token.name(), name);
        assertEq(token.symbol(), symbol);
        assertEq(token.decimals(), decimals);

        // no tokens have been minted because the current chain is not the token's home chain
        assertEq(token.totalSupply(), 0);
        assertEq(token.balanceOf(recipient), 0);
    }

    function test_create_succeeds_withoutMintOnDifferentChainAndNotCreator() public {
        vm.prank(bob);
        UniswapSuperchainERC20 token = UniswapSuperchainERC20(
            factory.createToken(name, symbol, decimals, 1e18, recipient, abi.encode(block.chainid + 1, tokenMetadata))
        ); // the home chain of this token is different than the current chain

        assert(address(token) != address(0));

        assertEq(token.name(), name);
        assertEq(token.symbol(), symbol);
        assertEq(token.decimals(), decimals);

        // no tokens have been minted because the current chain is not the token's home chain
        assertEq(token.totalSupply(), 0);
        assertEq(token.balanceOf(recipient), 0);
    }

    function test_getUniswapERC20Address_succeeds() public {
        // Calculate expected address using getUniswapERC20Address and verify against actual deployment
        address expectedAddress =
            factory.getUniswapERC20Address(name, symbol, decimals, block.chainid, tokenMetadata.creator);

        UniswapSuperchainERC20 token = UniswapSuperchainERC20(
            factory.createToken(name, symbol, decimals, 1e18, recipient, abi.encode(block.chainid, tokenMetadata))
        );

        assertEq(address(token), expectedAddress);
    }

    function test_create_succeeds_withEventEmitted() public {
        address tokenAddress =
            factory.getUniswapERC20Address(name, symbol, decimals, block.chainid, tokenMetadata.creator);

        vm.expectEmit(true, true, true, true);
        emit TokenCreated(tokenAddress);
        factory.createToken(name, symbol, decimals, 1e18, recipient, abi.encode(block.chainid, tokenMetadata));
    }

    function test_create_succeeds_withDifferentAddresses() public {
        // Deploy first token
        UniswapSuperchainERC20 token = UniswapSuperchainERC20(
            factory.createToken(name, symbol, decimals, 1e18, recipient, abi.encode(block.chainid, tokenMetadata))
        );

        // Deploy second token with different symbol
        string memory differentSymbol = "TOKEN2";
        address expectedNewAddress =
            factory.getUniswapERC20Address(name, differentSymbol, decimals, block.chainid, tokenMetadata.creator);
        UniswapSuperchainERC20 newToken = UniswapSuperchainERC20(
            factory.createToken(
                name, differentSymbol, decimals, 1e18, recipient, abi.encode(block.chainid, tokenMetadata)
            )
        );

        assertEq(address(newToken), expectedNewAddress);
        assertNotEq(address(newToken), address(token));
    }

    function test_create_revertsWithCreateCollision() public {
        factory.createToken(name, symbol, decimals, 1e18, recipient, abi.encode(block.chainid, tokenMetadata));

        vm.expectRevert();
        factory.createToken(name, symbol, decimals, 1e18, recipient, abi.encode(block.chainid, tokenMetadata));
    }

    function test_create_metadataClearedOnDifferentChain() public {
        UniswapSuperchainERC20 token = UniswapSuperchainERC20(
            factory.createToken(name, symbol, decimals, 1e18, recipient, abi.encode(block.chainid + 1, tokenMetadata))
        );

        (address creator, string memory description, string memory website, string memory image) = token.metadata();
        assertEq(creator, tokenMetadata.creator);
        assertEq(description, "");
        assertEq(image, "");
        assertEq(website, "");
    }

    function test_getUniswapERC20Address_differentMetadata_sameAddress() public view {
        // Create a token with certain metadata
        address originalAddr =
            factory.getUniswapERC20Address(name, symbol, decimals, block.chainid, tokenMetadata.creator);

        // Create tokenMetadata with different description but same creator
        UniswapERC20Metadata memory differentMetadata = UniswapERC20Metadata({
            description: "A different description",
            website: "https://different.com",
            image: "https://different.com/image.png",
            creator: tokenMetadata.creator
        });

        // Calculate address with different metadata
        address newAddr =
            factory.getUniswapERC20Address(name, symbol, decimals, block.chainid, differentMetadata.creator);

        // Addresses should be the same since only the core parameters affect the address
        assertEq(newAddr, originalAddr);
    }

    function test_bytecodeSize_factory() public {
        vm.snapshotValue("TokenFactory bytecode size", address(factory).code.length);
    }

    function test_bytecodeSize_token() public {
        UniswapSuperchainERC20 token = UniswapSuperchainERC20(
            factory.createToken(name, symbol, decimals, 1e18, recipient, abi.encode(block.chainid, tokenMetadata))
        );
        vm.snapshotValue("Token bytecode size", address(token).code.length);
    }

    function test_initcodeHash_token() public {
        bytes32 initCodeHash = keccak256(abi.encodePacked(type(UniswapSuperchainERC20).creationCode));
        vm.snapshotValue("Token initcode hash", uint256(initCodeHash));
    }
}
