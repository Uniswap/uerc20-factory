// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {TokenFactory} from "../src/TokenFactory.sol";
import {Token} from "../src/Token.sol";
import {TokenMetadata} from "../src/libraries/TokenMetadata.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";

contract TokenFactoryTest is Test {
    bytes32 constant SALT = bytes32(uint256(1));
    TokenFactory public factory;
    TokenMetadata public tokenMetadata;
    address recipient = makeAddr("recipient");
    string name = "Test Token";
    string symbol = "TOKEN";
    uint8 decimals = 18;

    event TokenCreated(
        address indexed tokenAddress,
        uint256 indexed chainId,
        string name,
        string symbol,
        uint8 decimals,
        uint256 homeChainId
    );

    function setUp() public {
        factory = new TokenFactory();
        tokenMetadata = TokenMetadata({
            description: "A test token",
            website: "https://example.com",
            image: "https://example.com/image.png",
            creator: address(this)
        });
    }

    /// forge-config: default.isolate = true
    function test_create_succeeds_withMint() public {
        Token token = factory.create(name, symbol, recipient, 1e18, block.chainid, decimals, tokenMetadata);
        vm.snapshotGasLastCall("deploy new token");

        assert(address(token) != address(0));

        assertEq(token.name(), name);
        assertEq(token.symbol(), symbol);
        assertEq(token.decimals(), decimals);
        assertEq(token.totalSupply(), 1e18);
        assertEq(token.balanceOf(recipient), 1e18);
    }

    function test_create_succeeds_withoutMintOnDifferentChain() public {
        Token token = factory.create(name, symbol, recipient, 1e18, block.chainid + 1, decimals, tokenMetadata); // the home chain of this token is different than the current chain

        assert(address(token) != address(0));

        assertEq(token.name(), name);
        assertEq(token.symbol(), symbol);
        assertEq(token.decimals(), decimals);

        // no tokens have been minted because the current chain is not the token's home chain
        assertEq(token.totalSupply(), 0);
        assertEq(token.balanceOf(recipient), 0);
    }

    function test_create_succeeds_withEventEmitted() public {
        bytes32 initCodeHash = keccak256(
            abi.encodePacked(
                type(Token).creationCode,
                abi.encode(name, symbol, recipient, 1e18, block.chainid, decimals, tokenMetadata)
            )
        );

        address tokenAddress = Create2.computeAddress(SALT, initCodeHash, address(factory));

        vm.expectEmit(true, true, true, true);
        emit TokenCreated(tokenAddress, block.chainid, name, symbol, decimals, block.chainid);
        factory.create(name, symbol, recipient, 1e18, block.chainid, decimals, tokenMetadata);
    }

    function test_create_succeeds_withDifferentAddresses() public {
        bytes32 initCodeHash = keccak256(
            abi.encodePacked(
                type(Token).creationCode,
                abi.encode(name, symbol, recipient, 1e18, block.chainid, decimals, tokenMetadata)
            )
        );

        address expectedTokenAddress = Create2.computeAddress(SALT, initCodeHash, address(factory));

        Token token = factory.create(name, symbol, recipient, 1e18, block.chainid, decimals, tokenMetadata);

        assertEq(address(token), expectedTokenAddress);

        // symbol changes which causes a different initCodeHash and thus a different address
        initCodeHash = keccak256(
            abi.encodePacked(
                type(Token).creationCode,
                abi.encode(name, "TOKEN2", recipient, 1e18, block.chainid, decimals, tokenMetadata)
            )
        );
        address newExpectedTokenAddress = Create2.computeAddress(SALT, initCodeHash, address(factory));
        Token newToken = factory.create(name, "TOKEN2", recipient, 1e18, block.chainid, decimals, tokenMetadata);
        assertEq(address(newToken), newExpectedTokenAddress);
        assertNotEq(address(newToken), address(token));
    }

    function test_create_revertsWithCreateCollision() public {
        factory.create(name, symbol, recipient, 1e18, block.chainid, decimals, tokenMetadata);

        vm.expectRevert();
        factory.create(name, symbol, recipient, 1e18, block.chainid, decimals, tokenMetadata);
    }

    function test_bytecodeSize_factory() public {
        vm.snapshotValue("TokenFactory bytecode size", address(factory).code.length);
    }

    function test_bytecodeSize_token() public {
        Token token = factory.create(name, symbol, recipient, 1e18, block.chainid, decimals, tokenMetadata);
        vm.snapshotValue("Token bytecode size", address(token).code.length);
    }
}
