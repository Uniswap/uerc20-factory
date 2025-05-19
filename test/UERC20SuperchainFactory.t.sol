// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {UERC20SuperchainFactory} from "../src/factories/UERC20SuperchainFactory.sol";
import {UERC20Superchain} from "../src/tokens/UERC20Superchain.sol";
import {UERC20Metadata} from "../src/libraries/UERC20MetadataLibrary.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";
import {IUERC20SuperchainFactory} from "../src/interfaces/IUERC20SuperchainFactory.sol";

contract UERC20SuperchainFactoryTest is Test {
    UERC20SuperchainFactory public factory;
    UERC20Metadata public tokenMetadata;
    address recipient = makeAddr("recipient");
    string name = "Test Token";
    string symbol = "TOKEN";
    uint8 decimals = 18;
    address bob = makeAddr("bob");

    event TokenCreated(address tokenAddress);

    function setUp() public {
        factory = new UERC20SuperchainFactory();
        tokenMetadata = UERC20Metadata({
            description: "A test token",
            website: "https://example.com",
            image: "https://example.com/image.png"
        });
    }

    function test_create_succeeds_withMint() public {
        UERC20Superchain token = UERC20Superchain(
            factory.createToken(
                name, symbol, decimals, 1e18, recipient, abi.encode(block.chainid, address(this), tokenMetadata)
            )
        );

        assert(address(token) != address(0));

        assertEq(token.name(), name);
        assertEq(token.symbol(), symbol);
        assertEq(token.decimals(), decimals);
        assertEq(token.totalSupply(), 1e18);
        assertEq(token.balanceOf(recipient), 1e18);
    }

    function test_create_revertsWithNotCreator() public {
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(IUERC20SuperchainFactory.NotCreator.selector, bob, address(this)));
        factory.createToken(
            name, symbol, decimals, 1e18, recipient, abi.encode(block.chainid, address(this), tokenMetadata)
        );
    }

    function test_create_succeeds_withoutMintOnDifferentChain() public {
        UERC20Superchain token = UERC20Superchain(
            factory.createToken(
                name, symbol, decimals, 1e18, recipient, abi.encode(block.chainid + 1, address(this), tokenMetadata)
            )
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
        UERC20Superchain token = UERC20Superchain(
            factory.createToken(
                name, symbol, decimals, 1e18, recipient, abi.encode(block.chainid + 1, address(this), tokenMetadata)
            )
        ); // the home chain of this token is different than the current chain

        assert(address(token) != address(0));

        assertEq(token.name(), name);
        assertEq(token.symbol(), symbol);
        assertEq(token.decimals(), decimals);

        // no tokens have been minted because the current chain is not the token's home chain
        assertEq(token.totalSupply(), 0);
        assertEq(token.balanceOf(recipient), 0);
    }

    function test_getUERC20Address_succeeds() public {
        // Calculate expected address using getUERC20Address and verify against actual deployment
        address expectedAddress =
            factory.getUERC20SuperchainAddress(name, symbol, decimals, block.chainid, address(this));

        UERC20Superchain token = UERC20Superchain(
            factory.createToken(
                name, symbol, decimals, 1e18, recipient, abi.encode(block.chainid, address(this), tokenMetadata)
            )
        );

        assertEq(address(token), expectedAddress);
    }

    function test_create_succeeds_withEventEmitted() public {
        address tokenAddress = factory.getUERC20SuperchainAddress(name, symbol, decimals, block.chainid, address(this));

        vm.expectEmit(true, true, true, true);
        emit TokenCreated(tokenAddress);
        factory.createToken(
            name, symbol, decimals, 1e18, recipient, abi.encode(block.chainid, address(this), tokenMetadata)
        );
    }

    function test_create_succeeds_withDifferentAddresses() public {
        // Deploy first token
        UERC20Superchain token = UERC20Superchain(
            factory.createToken(
                name, symbol, decimals, 1e18, recipient, abi.encode(block.chainid, address(this), tokenMetadata)
            )
        );

        // Deploy second token with different symbol
        string memory differentSymbol = "TOKEN2";
        address expectedNewAddress =
            factory.getUERC20SuperchainAddress(name, differentSymbol, decimals, block.chainid, address(this));
        UERC20Superchain newToken = UERC20Superchain(
            factory.createToken(
                name,
                differentSymbol,
                decimals,
                1e18,
                recipient,
                abi.encode(block.chainid, address(this), tokenMetadata)
            )
        );

        assertEq(address(newToken), expectedNewAddress);
        assertNotEq(address(newToken), address(token));
    }

    function test_create_revertsWithCreateCollision() public {
        factory.createToken(
            name, symbol, decimals, 1e18, recipient, abi.encode(block.chainid, address(this), tokenMetadata)
        );

        vm.expectRevert();
        factory.createToken(
            name, symbol, decimals, 1e18, recipient, abi.encode(block.chainid, address(this), tokenMetadata)
        );
    }

    function test_create_metadataClearedOnDifferentChain() public {
        UERC20Superchain token = UERC20Superchain(
            factory.createToken(
                name, symbol, decimals, 1e18, recipient, abi.encode(block.chainid + 1, address(this), tokenMetadata)
            )
        );

        (string memory description, string memory website, string memory image) = token.metadata();
        assertEq(description, "");
        assertEq(image, "");
        assertEq(website, "");
    }

    function test_bytecodeSize_uerc20superchainfactory() public {
        vm.snapshotValue("UERC20 Superchain Factory bytecode size", address(factory).code.length);
    }

    function test_bytecodeSize_uerc20superchain() public {
        UERC20Superchain token = UERC20Superchain(
            factory.createToken(
                name, symbol, decimals, 1e18, recipient, abi.encode(block.chainid, address(this), tokenMetadata)
            )
        );
        vm.snapshotValue("UERC20 Superchain bytecode size", address(token).code.length);
    }

    function test_initcodeHash_uerc20superchain() public {
        bytes32 initCodeHash = keccak256(abi.encodePacked(type(UERC20Superchain).creationCode));
        vm.snapshotValue("UERC20 Superchain initcode hash", uint256(initCodeHash));
    }

    /// forge-config: default.isolate = true
    /// forge-config: ci.isolate = true
    function test_create_uerc20superchain_succeeds_withMint_gas() public {
        UERC20Superchain(
            factory.createToken(
                name, symbol, decimals, 1e18, recipient, abi.encode(block.chainid, address(this), tokenMetadata)
            )
        );
        vm.snapshotGasLastCall("deploy new UERC20 Superchain");
    }
}
