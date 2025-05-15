// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {UERC20Superchain} from "../src/tokens/UERC20Superchain.sol";
import {UERC20SuperchainFactory} from "../src/factories/UERC20SuperchainFactory.sol";
import {UERC20Metadata} from "../src/libraries/UERC20Metadata.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC7802, IERC165} from "@optimism/interfaces/L2/IERC7802.sol";
import {Base64} from "./libraries/base64.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";

contract UERC20SuperchainTest is Test {
    using Base64 for string;
    using Strings for address;

    address constant SUPERCHAIN_ERC20_BRIDGE = 0x4200000000000000000000000000000000000028;
    address constant PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;
    uint256 constant INITIAL_BALANCE = 5e18;
    uint256 constant TRANSFER_AMOUNT = 1e18;
    uint8 constant DECIMALS = 18;

    UERC20Superchain token;
    UERC20SuperchainFactory factory;
    UERC20Metadata tokenMetadata;

    address recipient = makeAddr("recipient");
    address bob = makeAddr("bob");

    struct JsonTokenAllFields {
        string description;
        string image;
        string website;
    }

    struct JsonTokenDescriptionWebsite {
        string description;
        string website;
    }

    struct JsonTokenDescriptionImage {
        string description;
        string image;
    }

    struct JsonTokenWebsiteImage {
        string image;
        string website;
    }

    struct JsonTokenDescription {
        string description;
    }

    struct JsonTokenWebsite {
        string website;
    }

    struct JsonTokenImage {
        string image;
    }

    event CrosschainMint(address indexed to, uint256 amount, address indexed sender);
    event CrosschainBurn(address indexed from, uint256 amount, address indexed sender);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function setUp() public {
        tokenMetadata = UERC20Metadata({
            description: "A test token",
            website: "https://example.com",
            image: "https://example.com/image.png"
        });
        factory = new UERC20SuperchainFactory();
        token = UERC20Superchain(
            factory.createToken(
                "Test",
                "TEST",
                DECIMALS,
                INITIAL_BALANCE,
                recipient,
                abi.encode(block.chainid, address(this), tokenMetadata)
            )
        );
    }

    /// forge-config: default.isolate = true
    function test_crosschainMint_succeeds() public {
        vm.expectEmit(true, false, true, true);
        emit CrosschainMint(bob, TRANSFER_AMOUNT, SUPERCHAIN_ERC20_BRIDGE);
        vm.startPrank(SUPERCHAIN_ERC20_BRIDGE);
        token.crosschainMint(bob, TRANSFER_AMOUNT);
        vm.snapshotGasLastCall("crosschainMint: first mint");
        assertEq(token.balanceOf(bob), TRANSFER_AMOUNT);
        assertEq(token.totalSupply(), INITIAL_BALANCE + TRANSFER_AMOUNT);
        token.crosschainMint(bob, TRANSFER_AMOUNT);
        vm.snapshotGasLastCall("crosschainMint: second mint");
        assertEq(token.balanceOf(bob), TRANSFER_AMOUNT * 2);
    }

    function test_fuzz_crosschainMint_succeeds(address to, uint256 amount) public {
        vm.assume(to != address(0));
        // Prevent overflow
        amount = bound(amount, 0, type(uint256).max - token.totalSupply());

        uint256 totalSupplyBefore = token.totalSupply();
        uint256 toBalanceBefore = token.balanceOf(to);

        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), to, amount);

        vm.expectEmit(true, false, true, true);
        emit CrosschainMint(to, amount, SUPERCHAIN_ERC20_BRIDGE);

        vm.startPrank(SUPERCHAIN_ERC20_BRIDGE);
        token.crosschainMint(to, amount);

        assertEq(token.totalSupply(), totalSupplyBefore + amount);
        assertEq(token.balanceOf(to), toBalanceBefore + amount);
    }

    function test_crosschainMint_revertsWithNotSuperchainERC20Bridge() public {
        vm.prank(bob);
        vm.expectRevert(
            abi.encodeWithSelector(UERC20Superchain.NotSuperchainTokenBridge.selector, bob, SUPERCHAIN_ERC20_BRIDGE)
        );
        token.crosschainMint(bob, TRANSFER_AMOUNT);
        assertEq(token.balanceOf(bob), 0);
        assertEq(token.totalSupply(), INITIAL_BALANCE);
    }

    function test_fuzz_crosschainMint_revertsWithNotSuperchainERC20Bridge(address caller, address to, uint256 amount)
        public
    {
        vm.assume(caller != SUPERCHAIN_ERC20_BRIDGE);

        vm.expectRevert(
            abi.encodeWithSelector(UERC20Superchain.NotSuperchainTokenBridge.selector, caller, SUPERCHAIN_ERC20_BRIDGE)
        );

        vm.prank(caller);
        token.crosschainMint(to, amount);
    }

    /// forge-config: default.isolate = true
    function test_crosschainBurn_succeeds() public {
        deal(address(token), bob, TRANSFER_AMOUNT);
        assertEq(token.balanceOf(bob), TRANSFER_AMOUNT);
        vm.expectEmit(true, false, true, true);
        emit CrosschainBurn(bob, TRANSFER_AMOUNT, SUPERCHAIN_ERC20_BRIDGE);
        vm.prank(SUPERCHAIN_ERC20_BRIDGE);
        token.crosschainBurn(bob, TRANSFER_AMOUNT);
        vm.snapshotGasLastCall("crosschainBurn");
        assertEq(token.balanceOf(bob), 0);
    }

    function test_fuzz_crosschainBurn_succeeds(uint256 amount) public {
        amount = bound(amount, 0, token.totalSupply());

        uint256 totalSupplyBefore = token.totalSupply();
        uint256 recipientBalanceBefore = token.balanceOf(recipient);

        vm.expectEmit(true, true, false, true);
        emit Transfer(recipient, address(0), amount);

        vm.expectEmit(true, false, true, true);
        emit CrosschainBurn(recipient, amount, SUPERCHAIN_ERC20_BRIDGE);

        vm.startPrank(SUPERCHAIN_ERC20_BRIDGE);
        token.crosschainBurn(recipient, amount);

        assertEq(token.totalSupply(), totalSupplyBefore - amount);
        assertEq(token.balanceOf(recipient), recipientBalanceBefore - amount);
    }

    function test_crosschainBurn_revertsWithNotSuperchainERC20Bridge() public {
        deal(address(token), bob, TRANSFER_AMOUNT);
        assertEq(token.balanceOf(bob), TRANSFER_AMOUNT);
        vm.prank(bob);
        vm.expectRevert(
            abi.encodeWithSelector(UERC20Superchain.NotSuperchainTokenBridge.selector, bob, SUPERCHAIN_ERC20_BRIDGE)
        );
        token.crosschainBurn(bob, TRANSFER_AMOUNT);
        assertEq(token.balanceOf(bob), TRANSFER_AMOUNT);
    }

    function test_fuzz_crosschainBurn_revertsWithNotSuperchainERC20Bridge(address caller, address from, uint256 amount)
        public
    {
        vm.assume(caller != SUPERCHAIN_ERC20_BRIDGE);

        vm.expectRevert(
            abi.encodeWithSelector(UERC20Superchain.NotSuperchainTokenBridge.selector, caller, SUPERCHAIN_ERC20_BRIDGE)
        );

        vm.prank(caller);
        token.crosschainBurn(from, amount);
    }

    function test_supportsInterface() public view {
        assertTrue(bytes4(0x01ffc9a7) == type(IERC165).interfaceId);
        assertTrue(token.supportsInterface(0x01ffc9a7)); // IERC165
        assertTrue(bytes4(0x33331994) == type(IERC7802).interfaceId);
        assertTrue(token.supportsInterface(0x33331994)); // IERC7802
        assertTrue(bytes4(0x36372b07) == type(IERC20).interfaceId);
        assertTrue(token.supportsInterface(0x36372b07)); // IERC20
    }

    function test_fuzz_supportsInterface(bytes4 interfaceId) public view {
        vm.assume(interfaceId != type(IERC165).interfaceId);
        vm.assume(interfaceId != type(IERC7802).interfaceId);
        vm.assume(interfaceId != type(IERC20).interfaceId);
        assertFalse(token.supportsInterface(interfaceId));
    }

    function test_permit2CanTransferWithoutAllowance() public {
        vm.startPrank(PERMIT2);
        token.transferFrom(recipient, bob, TRANSFER_AMOUNT);
        assertEq(token.balanceOf(bob), TRANSFER_AMOUNT);
        assertEq(token.balanceOf(recipient), INITIAL_BALANCE - TRANSFER_AMOUNT);
        vm.stopPrank();
    }

    function test_nonPermit2CannotTransferWithoutAllowance() public {
        vm.startPrank(bob);
        vm.expectRevert();
        token.transferFrom(recipient, bob, TRANSFER_AMOUNT);
        vm.stopPrank();
    }

    function test_nonPermit2CanTransferWithAllowance() public {
        vm.prank(recipient);
        token.approve(bob, TRANSFER_AMOUNT);

        vm.prank(bob);
        token.transferFrom(recipient, bob, TRANSFER_AMOUNT);

        assertEq(token.balanceOf(bob), TRANSFER_AMOUNT);
        assertEq(token.balanceOf(recipient), INITIAL_BALANCE - TRANSFER_AMOUNT);
        assertEq(token.allowance(recipient, bob), 0);
    }

    function test_permit2InfiniteAllowance() public view {
        assertEq(token.allowance(recipient, PERMIT2), type(uint256).max);
    }

    function test_nameSymbolDecimalsTotalSupply() public view {
        assertEq(token.name(), "Test");
        assertEq(token.symbol(), "TEST");
        assertEq(token.decimals(), DECIMALS);
        assertEq(token.totalSupply(), INITIAL_BALANCE);
    }

    function test_data_succeeds() public view {
        assertEq(token.homeChainId(), block.chainid);
        assertEq(token.creator(), address(this));
    }

    function test_tokenURI_allFields() public view {
        bytes memory data = decode(token);
        JsonTokenAllFields memory jsonToken = abi.decode(data, (JsonTokenAllFields));

        // Parse JSON to extract individual fields
        assertEq(jsonToken.description, "A test token");
        assertEq(jsonToken.website, "https://example.com");
        assertEq(jsonToken.image, "https://example.com/image.png");
    }

    function test_tokenURI_maliciousInjectionDetected() public {
        tokenMetadata = UERC20Metadata({
            description: "A test token",
            website: "https://example.com",
            image: "Normal description\" , \"Website\": \"https://malicious.com"
        });
        factory = new UERC20SuperchainFactory();
        token = UERC20Superchain(
            factory.createToken(
                "Test",
                "TEST",
                DECIMALS,
                INITIAL_BALANCE,
                recipient,
                abi.encode(block.chainid, address(this), tokenMetadata)
            )
        );

        bytes memory data = decode(token);
        JsonTokenAllFields memory jsonToken = abi.decode(data, (JsonTokenAllFields));

        // Parse JSON to extract individual fields
        assertEq(jsonToken.description, "A test token");
        assertEq(jsonToken.website, "https://example.com");
        assertEq(jsonToken.image, "Normal description\" , \"Website\": \"https://malicious.com");
    }

    function test_tokenURI_descriptionWebsite() public {
        tokenMetadata = UERC20Metadata({description: "A test token", website: "https://example.com", image: ""});
        factory = new UERC20SuperchainFactory();
        token = UERC20Superchain(
            factory.createToken(
                "Test",
                "TEST",
                DECIMALS,
                INITIAL_BALANCE,
                recipient,
                abi.encode(block.chainid, address(this), tokenMetadata)
            )
        );

        bytes memory data = decode(token);
        JsonTokenDescriptionWebsite memory jsonToken = abi.decode(data, (JsonTokenDescriptionWebsite));

        // Parse JSON to extract individual fields
        assertEq(jsonToken.description, "A test token");
        assertEq(jsonToken.website, "https://example.com");
    }

    function test_tokenURI_descriptionImage() public {
        tokenMetadata =
            UERC20Metadata({description: "A test token", website: "", image: "https://example.com/image.png"});
        factory = new UERC20SuperchainFactory();
        token = UERC20Superchain(
            factory.createToken(
                "Test",
                "TEST",
                DECIMALS,
                INITIAL_BALANCE,
                recipient,
                abi.encode(block.chainid, address(this), tokenMetadata)
            )
        );

        bytes memory data = decode(token);
        JsonTokenDescriptionImage memory jsonToken = abi.decode(data, (JsonTokenDescriptionImage));

        // Parse JSON to extract individual fields
        assertEq(jsonToken.description, "A test token");
        assertEq(jsonToken.image, "https://example.com/image.png");
    }

    function test_tokenURI_websiteImage() public {
        tokenMetadata =
            UERC20Metadata({description: "", website: "https://example.com", image: "https://example.com/image.png"});
        factory = new UERC20SuperchainFactory();
        token = UERC20Superchain(
            factory.createToken(
                "Test",
                "TEST",
                DECIMALS,
                INITIAL_BALANCE,
                recipient,
                abi.encode(block.chainid, address(this), tokenMetadata)
            )
        );

        bytes memory data = decode(token);
        JsonTokenWebsiteImage memory jsonToken = abi.decode(data, (JsonTokenWebsiteImage));

        // Parse JSON to extract individual fields
        assertEq(jsonToken.website, "https://example.com");
        assertEq(jsonToken.image, "https://example.com/image.png");
    }

    function test_tokenURI_description() public {
        tokenMetadata = UERC20Metadata({description: "A test token", website: "", image: ""});
        factory = new UERC20SuperchainFactory();
        token = UERC20Superchain(
            factory.createToken(
                "Test",
                "TEST",
                DECIMALS,
                INITIAL_BALANCE,
                recipient,
                abi.encode(block.chainid, address(this), tokenMetadata)
            )
        );

        bytes memory data = decode(token);
        JsonTokenDescription memory jsonToken = abi.decode(data, (JsonTokenDescription));

        // Parse JSON to extract individual fields
        assertEq(jsonToken.description, "A test token");
    }

    function test_tokenURI_website() public {
        tokenMetadata = UERC20Metadata({description: "", website: "https://example.com", image: ""});
        factory = new UERC20SuperchainFactory();
        token = UERC20Superchain(
            factory.createToken(
                "Test",
                "TEST",
                DECIMALS,
                INITIAL_BALANCE,
                recipient,
                abi.encode(block.chainid, address(this), tokenMetadata)
            )
        );

        bytes memory data = decode(token);
        JsonTokenWebsite memory jsonToken = abi.decode(data, (JsonTokenWebsite));

        // Parse JSON to extract individual fields
        assertEq(jsonToken.website, "https://example.com");
    }

    function test_tokenURI_image() public {
        tokenMetadata = UERC20Metadata({description: "", website: "", image: "https://example.com/image.png"});
        factory = new UERC20SuperchainFactory();
        token = UERC20Superchain(
            factory.createToken(
                "Test",
                "TEST",
                DECIMALS,
                INITIAL_BALANCE,
                recipient,
                abi.encode(block.chainid, address(this), tokenMetadata)
            )
        );

        bytes memory data = decode(token);
        JsonTokenImage memory jsonToken = abi.decode(data, (JsonTokenImage));

        // Parse JSON to extract individual fields
        assertEq(jsonToken.image, "https://example.com/image.png");
    }

    function decode(UERC20Superchain _uerc20) private view returns (bytes memory) {
        // The prefix length is calculated by converting the string to bytes and finding its length
        uint256 prefixLength = bytes("data:application/json;base64,").length;

        string memory uri = _uerc20.tokenURI();
        // Convert the uri to bytes
        bytes memory uriBytes = bytes(uri);

        // Slice the uri to get only the base64-encoded part
        bytes memory base64Part = new bytes(uriBytes.length - prefixLength);

        for (uint256 i = 0; i < base64Part.length; i++) {
            base64Part[i] = uriBytes[i + prefixLength];
        }

        // Decode the base64-encoded part
        bytes memory decoded = Base64.decode(string(base64Part));
        string memory json = string(decoded);

        // decode json
        return vm.parseJson(json);
    }
}
