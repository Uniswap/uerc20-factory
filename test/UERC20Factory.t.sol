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
        UERC20 token = UERC20(factory.createToken(name, symbol, decimals, 1e18, recipient, abi.encode(tokenMetadata)));

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
        factory.createToken(name, symbol, decimals, 1e18, recipient, abi.encode(tokenMetadata));
    }

    function test_getUERC20Address_succeeds() public {
        // Calculate expected address using getUERC20Address and verify against actual deployment
        address expectedAddress = factory.getUERC20Address(name, symbol, decimals, tokenMetadata.creator);

        UERC20 token = UERC20(factory.createToken(name, symbol, decimals, 1e18, recipient, abi.encode(tokenMetadata)));

        assertEq(address(token), expectedAddress);
    }

    function test_create_succeeds_withEventEmitted() public {
        address tokenAddress = factory.getUERC20Address(name, symbol, decimals, tokenMetadata.creator);

        vm.expectEmit(true, true, true, true);
        emit TokenCreated(tokenAddress);
        factory.createToken(name, symbol, decimals, 1e18, recipient, abi.encode(tokenMetadata));
    }

    function test_create_succeeds_withDifferentAddresses() public {
        // Deploy first token
        UERC20 token = UERC20(factory.createToken(name, symbol, decimals, 1e18, recipient, abi.encode(tokenMetadata)));

        // Deploy second token with different symbol
        string memory differentSymbol = "TOKEN2";
        address expectedNewAddress = factory.getUERC20Address(name, differentSymbol, decimals, tokenMetadata.creator);
        UERC20 newToken =
            UERC20(factory.createToken(name, differentSymbol, decimals, 1e18, recipient, abi.encode(tokenMetadata)));

        assertEq(address(newToken), expectedNewAddress);
        assertNotEq(address(newToken), address(token));
    }

    function test_create_revertsWithCreateCollision() public {
        factory.createToken(name, symbol, decimals, 1e18, recipient, abi.encode(tokenMetadata));

        vm.expectRevert();
        factory.createToken(name, symbol, decimals, 1e18, recipient, abi.encode(tokenMetadata));
    }

    function test_getUERC20Address_differentMetadata_sameAddress() public view {
        // Create a token with certain metadata
        address originalAddr = factory.getUERC20Address(name, symbol, decimals, tokenMetadata.creator);

        // Create tokenMetadata with different description but same creator
        UERC20Metadata memory differentMetadata = UERC20Metadata({
            description: "A different description",
            website: "https://different.com",
            image: "https://different.com/image.png",
            creator: tokenMetadata.creator
        });

        // Calculate address with different metadata
        address newAddr = factory.getUERC20Address(name, symbol, decimals, differentMetadata.creator);

        // Addresses should be the same since only the core parameters affect the address
        assertEq(newAddr, originalAddr);
    }

    function test_bytecodeSize_uerc20factory() public {
        vm.snapshotValue("UERC20 Factory bytecode size", address(factory).code.length);
    }

    function test_bytecodeSize_uerc20() public {
        UERC20 token = UERC20(factory.createToken(name, symbol, decimals, 1e18, recipient, abi.encode(tokenMetadata)));
        vm.snapshotValue("UERC20 bytecode size", address(token).code.length);
    }

    function test_initcodeHash_uerc20() public {
        bytes32 initCodeHash = keccak256(abi.encodePacked(type(UERC20).creationCode));
        vm.snapshotValue("UERC20 initcode hash", uint256(initCodeHash));
    }

    /// forge-config: default.isolate = true
    /// forge-config: ci.isolate = true
    function test_create_uerc20_succeeds_withMint_gas() public {
        UERC20(factory.createToken(name, symbol, decimals, 1e18, recipient, abi.encode(tokenMetadata)));
        vm.snapshotGasLastCall("deploy new UERC20");
    }
}
