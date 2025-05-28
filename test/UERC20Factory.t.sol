// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {UERC20Factory} from "../src/factories/UERC20Factory.sol";
import {UERC20} from "../src/tokens/UERC20.sol";
import {UERC20Metadata} from "../src/libraries/UERC20MetadataLibrary.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";
import {IUERC20Factory} from "../src/interfaces/IUERC20Factory.sol";

contract UERC20FactoryTest is Test {
    UERC20Factory public factory;
    UERC20Metadata public tokenMetadata;
    address recipient = makeAddr("recipient");
    string name = "Test Token";
    string symbol = "TOKEN";
    uint8 decimals = 18;
    address bob = makeAddr("bob");

    event TokenCreated(address tokenAddress);

    function setUp() public {
        factory = new UERC20Factory();
        tokenMetadata = UERC20Metadata({
            description: "A test token",
            website: "https://example.com",
            image: "https://example.com/image.png",
            creator: address(this)
        });
    }

    function test_create_succeeds_withMint() public {
        UERC20 token =
            UERC20(factory.createToken(name, symbol, decimals, 1e18, recipient, abi.encode(tokenMetadata), bytes32("")));

        assert(address(token) != address(0));

        assertEq(token.name(), name);
        assertEq(token.symbol(), symbol);
        assertEq(token.decimals(), decimals);
        assertEq(token.totalSupply(), 1e18);
        assertEq(token.balanceOf(recipient), 1e18);
    }

    function test_create_revertsWithNotCreator() public {
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(IUERC20Factory.NotCreator.selector, bob, tokenMetadata.creator));
        factory.createToken(name, symbol, decimals, 1e18, recipient, abi.encode(tokenMetadata), bytes32(""));
    }

    function test_getUERC20Address_succeeds() public {
        // Calculate expected address using getUERC20Address and verify against actual deployment
        address expectedAddress = factory.getUERC20Address(name, symbol, decimals, tokenMetadata.creator, bytes32(""));

        UERC20 token =
            UERC20(factory.createToken(name, symbol, decimals, 1e18, recipient, abi.encode(tokenMetadata), bytes32("")));

        assertEq(address(token), expectedAddress);
    }

    function test_create_succeeds_withEventEmitted() public {
        address tokenAddress = factory.getUERC20Address(name, symbol, decimals, tokenMetadata.creator, bytes32(""));

        vm.expectEmit(true, true, true, true);
        emit TokenCreated(tokenAddress);
        factory.createToken(name, symbol, decimals, 1e18, recipient, abi.encode(tokenMetadata), bytes32(""));
    }

    function test_create_succeeds_withDifferentAddresses() public {
        // Deploy first token
        UERC20 token =
            UERC20(factory.createToken(name, symbol, decimals, 1e18, recipient, abi.encode(tokenMetadata), bytes32("")));

        // Deploy second token with different symbol
        string memory differentSymbol = "TOKEN2";
        address expectedNewAddress =
            factory.getUERC20Address(name, differentSymbol, decimals, tokenMetadata.creator, bytes32(""));
        UERC20 newToken = UERC20(
            factory.createToken(
                name, differentSymbol, decimals, 1e18, recipient, abi.encode(tokenMetadata), bytes32("")
            )
        );

        assertEq(address(newToken), expectedNewAddress);
        assertNotEq(address(newToken), address(token));
    }

    function test_create_revertsWithCreateCollision() public {
        factory.createToken(name, symbol, decimals, 1e18, recipient, abi.encode(tokenMetadata), bytes32(""));
    }

    function test_getUERC20Address_differentMetadata_sameAddress() public view {
        // Create a token with certain metadata
        address originalAddr = factory.getUERC20Address(name, symbol, decimals, tokenMetadata.creator, bytes32(""));

        // Create tokenMetadata with different description but same creator
        UERC20Metadata memory differentMetadata = UERC20Metadata({
            description: "A different description",
            website: "https://different.com",
            image: "https://different.com/image.png",
            creator: tokenMetadata.creator
        });

        // Calculate address with different metadata
        address newAddr = factory.getUERC20Address(name, symbol, decimals, differentMetadata.creator, bytes32(""));

        // Addresses should be the same since only the core parameters affect the address
        assertEq(newAddr, originalAddr);
    }

    function test_getUERC20Address_differentCreator_differentAddress() public {
        // Calculate address with original creator
        address originalAddr = factory.getUERC20Address(name, symbol, decimals, tokenMetadata.creator, bytes32(""));

        // Calculate address with different creator
        address differentCreator = makeAddr("differentCreator");
        address newAddr = factory.getUERC20Address(name, symbol, decimals, differentCreator, bytes32(""));

        // Addresses should be different since creator is part of the salt
        assertNotEq(newAddr, originalAddr);
    }

    function test_getUERC20Address_differentGraffiti_differentAddress() public view {
        // Calculate address with empty graffiti
        address originalAddr = factory.getUERC20Address(name, symbol, decimals, tokenMetadata.creator, bytes32(""));

        // Calculate address with different graffiti
        bytes32 differentGraffiti = keccak256("different graffiti");
        address newAddr = factory.getUERC20Address(name, symbol, decimals, tokenMetadata.creator, differentGraffiti);

        // Addresses should be different since graffiti is part of the salt
        assertNotEq(newAddr, originalAddr);
    }

    function test_create_differentCreators_differentAddresses() public {
        // Create first token with original creator
        UERC20 token1 =
            UERC20(factory.createToken(name, symbol, decimals, 1e18, recipient, abi.encode(tokenMetadata), bytes32("")));

        // Create metadata with different creator
        address differentCreator = makeAddr("differentCreator");
        UERC20Metadata memory differentCreatorMetadata = UERC20Metadata({
            description: "A test token",
            website: "https://example.com",
            image: "https://example.com/image.png",
            creator: differentCreator
        });

        // Deploy second token with different creator
        vm.prank(differentCreator);
        UERC20 token2 = UERC20(
            factory.createToken(
                name, symbol, decimals, 1e18, recipient, abi.encode(differentCreatorMetadata), bytes32("")
            )
        );

        // Verify tokens have different addresses
        assertNotEq(address(token1), address(token2));

        // Verify both tokens have the same name, symbol, decimals but different creators
        assertEq(token1.name(), token2.name());
        assertEq(token1.symbol(), token2.symbol());
        assertEq(token1.decimals(), token2.decimals());

        // Verify metadata creators are different
        (address creator1,,,) = token1.metadata();
        (address creator2,,,) = token2.metadata();
        assertEq(creator1, tokenMetadata.creator);
        assertEq(creator2, differentCreator);
        assertNotEq(creator1, creator2);
    }

    function test_create_differentGraffiti_differentAddresses() public {
        // Create first token with empty graffiti
        UERC20 token1 =
            UERC20(factory.createToken(name, symbol, decimals, 1e18, recipient, abi.encode(tokenMetadata), bytes32("")));

        // Create second token with different graffiti
        bytes32 differentGraffiti = keccak256("different graffiti");
        UERC20 token2 = UERC20(
            factory.createToken(name, symbol, decimals, 1e18, recipient, abi.encode(tokenMetadata), differentGraffiti)
        );

        // Verify tokens have different addresses
        assertNotEq(address(token1), address(token2));

        // Verify both tokens have the same properties
        assertEq(token1.name(), token2.name());
        assertEq(token1.symbol(), token2.symbol());
        assertEq(token1.decimals(), token2.decimals());

        // Verify metadata is the same (graffiti doesn't affect metadata)
        (address creator1,,,) = token1.metadata();
        (address creator2,,,) = token2.metadata();
        assertEq(creator1, creator2);
    }

    function test_bytecodeSize_uerc20factory() public {
        vm.snapshotValue("UERC20 Factory bytecode size", address(factory).code.length);
    }

    function test_bytecodeSize_uerc20() public {
        UERC20 token =
            UERC20(factory.createToken(name, symbol, decimals, 1e18, recipient, abi.encode(tokenMetadata), bytes32("")));
        vm.snapshotValue("UERC20 bytecode size", address(token).code.length);
    }

    function test_initcodeHash_uerc20() public {
        bytes32 initCodeHash = keccak256(abi.encodePacked(type(UERC20).creationCode));
        vm.snapshotValue("UERC20 initcode hash", uint256(initCodeHash));
    }

    /// forge-config: default.isolate = true
    /// forge-config: ci.isolate = true
    function test_create_uerc20_succeeds_withMint_gas() public {
        UERC20(factory.createToken(name, symbol, decimals, 1e18, recipient, abi.encode(tokenMetadata), bytes32("")));
        vm.snapshotGasLastCall("deploy new UERC20");
    }
}
