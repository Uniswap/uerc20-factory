// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {TokenFactory} from "../src/TokenFactory.sol";
import {Token} from "../src/Token.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";

contract TokenFactoryTest is Test {
    bytes32 constant SALT = bytes32(uint256(1));
    TokenFactory public factory;

    event TokenCreated(
        address indexed tokenAddress, uint256 indexed chainId, string name, string symbol, uint256 homeChainId
    );

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
        vm.snapshotGasLastCall("deploy new token");

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

    function test_create_succeeds_withEventEmitted() public {
        string memory name = "Test Token";
        string memory symbol = "TOKEN";
        uint256 totalSupply = 1e18;
        address recipient = makeAddr("recipient");
        uint256 homeChainId = block.chainid;

        bytes32 initCodeHash = keccak256(
            abi.encodePacked(type(Token).creationCode, abi.encode(name, symbol, totalSupply, recipient, homeChainId))
        );

        address tokenAddress = Create2.computeAddress(SALT, initCodeHash, address(factory));

        vm.expectEmit(true, true, true, true);
        emit TokenCreated(tokenAddress, block.chainid, name, symbol, homeChainId);
        factory.create(name, symbol, totalSupply, recipient, homeChainId);
    }

    function test_create_succeeds_withDifferentAddresses() public {
        string memory name = "Test Token";
        string memory symbol = "TOKEN";
        uint256 totalSupply = 1e18;
        address recipient = makeAddr("recipient");
        uint256 homeChainId = block.chainid;

        bytes32 initCodeHash = keccak256(
            abi.encodePacked(type(Token).creationCode, abi.encode(name, symbol, totalSupply, recipient, homeChainId))
        );

        address expectedTokenAddress = Create2.computeAddress(SALT, initCodeHash, address(factory));

        Token token = factory.create(name, symbol, totalSupply, recipient, homeChainId);

        assertEq(address(token), expectedTokenAddress);

        // symbol changes which causes a different initCodeHash and thus a different address
        symbol = "TOKEN2";
        initCodeHash = keccak256(
            abi.encodePacked(type(Token).creationCode, abi.encode(name, symbol, totalSupply, recipient, homeChainId))
        );
        address newExpectedTokenAddress = Create2.computeAddress(SALT, initCodeHash, address(factory));
        Token newToken = factory.create(name, symbol, totalSupply, recipient, homeChainId);
        assertEq(address(newToken), newExpectedTokenAddress);
        assertNotEq(address(newToken), address(token));
    }

    function test_create_revertsWithCreateCollision() public {
        string memory name = "Test Token";
        string memory symbol = "TOKEN";
        uint256 totalSupply = 1e18;
        address recipient = makeAddr("recipient");
        uint256 homeChainId = block.chainid;

        factory.create(name, symbol, totalSupply, recipient, homeChainId);

        vm.expectRevert();
        factory.create(name, symbol, totalSupply, recipient, homeChainId);
    }

    function test_bytecodeSize_factory() public {
        vm.snapshotValue("TokenFactory bytecode size", address(factory).code.length);
    }

    function test_bytecodeSize_token() public {
        string memory name = "Test Token";
        string memory symbol = "TOKEN";
        uint256 totalSupply = 1e18;
        address recipient = makeAddr("recipient");
        uint256 homeChainId = block.chainid;

        Token token = factory.create(name, symbol, totalSupply, recipient, homeChainId);
        vm.snapshotValue("Token bytecode size", address(token).code.length);
    }
}
