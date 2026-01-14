// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {UERC20TimeLocked} from "../src/tokens/UERC20TimeLocked.sol";
import {UERC20TimeLockedFactory} from "../src/factories/UERC20TimeLockedFactory.sol";
import {UERC20Metadata} from "../src/libraries/UERC20MetadataLibrary.sol";
import {Base64} from "./libraries/base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IERC165} from "@optimism/interfaces/L2/IERC7802.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";

contract UERC20TimeLockedTest is Test {
    using Base64 for string;
    using Strings for address;

    address constant PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;
    uint256 constant INITIAL_BALANCE = 5e18;
    uint256 constant TRANSFER_AMOUNT = 1e18;
    uint8 constant DECIMALS = 18;

    UERC20TimeLocked token;
    UERC20TimeLockedFactory factory;
    UERC20Metadata tokenMetadata;

    address bob = makeAddr("bob");

    address operator = makeAddr("operator");

    function setUp() public {
        tokenMetadata = UERC20Metadata({
            description: "A test token", website: "https://example.com", image: "https://example.com/image.png"
        });
        factory = new UERC20TimeLockedFactory();
    }

    function test_createToken_revertsWithOperatorCannotBeZeroAddress() public {
        bytes memory data = abi.encode(0, address(0), tokenMetadata);
        vm.expectRevert(abi.encodeWithSelector(UERC20TimeLockedFactory.OperatorCannotBeZeroAddress.selector));
        factory.createToken("Test", "TEST", DECIMALS, INITIAL_BALANCE, address(this), data, bytes32("test"));
    }

    function test_setOperator_revertsWithNotOperator(uint256 _releaseBlock, address _to) public {
        address notOperator = makeAddr("notOperator");
        bytes memory data = abi.encode(_releaseBlock, operator, tokenMetadata);
        token = UERC20TimeLocked(
            factory.createToken("Test", "TEST", DECIMALS, INITIAL_BALANCE, address(this), data, bytes32("test"))
        );

        vm.prank(notOperator);
        vm.expectRevert(abi.encodeWithSelector(UERC20TimeLocked.NotOperator.selector));
        token.setOperator(_to);
    }

    function test_setOperator_succeeds(uint256 _releaseBlock, address _to) public {
        bytes memory data = abi.encode(_releaseBlock, operator, tokenMetadata);
        token = UERC20TimeLocked(
            factory.createToken("Test", "TEST", DECIMALS, INITIAL_BALANCE, address(this), data, bytes32("test"))
        );

        vm.prank(operator);
        token.setOperator(_to);
        assertEq(token.operator(), _to);
    }

    function test_allowTransfer_revertsWithNotOperator(uint256 _releaseBlock, address _to) public {
        address notOperator = makeAddr("notOperator");
        bytes memory data = abi.encode(_releaseBlock, operator, tokenMetadata);
        token = UERC20TimeLocked(
            factory.createToken("Test", "TEST", DECIMALS, INITIAL_BALANCE, address(this), data, bytes32("test"))
        );

        vm.prank(notOperator);
        vm.expectRevert(abi.encodeWithSelector(UERC20TimeLocked.NotOperator.selector));
        token.allowTransfer(_to, true);
    }

    function test_allowTransfer_succeeds(uint256 _releaseBlock, address _from) public {
        bytes memory data = abi.encode(_releaseBlock, operator, tokenMetadata);
        token = UERC20TimeLocked(
            factory.createToken("Test", "TEST", DECIMALS, INITIAL_BALANCE, address(this), data, bytes32("test"))
        );

        vm.prank(operator);
        token.allowTransfer(_from, true);
        assertEq(token.allowed(_from), true);
    }

    function test_transfer_revertsWithTimeLocked(uint256 _releaseBlock, address _from) public {
        vm.assume(_releaseBlock > 0);

        bytes memory data = abi.encode(_releaseBlock, operator, tokenMetadata);
        token = UERC20TimeLocked(
            factory.createToken("Test", "TEST", DECIMALS, INITIAL_BALANCE, address(this), data, bytes32("test"))
        );

        vm.roll(_releaseBlock - 1);

        vm.prank(_from);
        vm.expectRevert(abi.encodeWithSelector(UERC20TimeLocked.TimeLocked.selector));
        token.transfer(_from, TRANSFER_AMOUNT);
    }

    function test_transferAllowed_transferSucceeds(uint256 _releaseBlock, address _from) public {
        bytes memory data = abi.encode(_releaseBlock, operator, tokenMetadata);
        token = UERC20TimeLocked(
            factory.createToken("Test", "TEST", DECIMALS, INITIAL_BALANCE, address(this), data, bytes32("test"))
        );

        deal(address(token), _from, INITIAL_BALANCE);

        vm.prank(operator);
        token.allowTransfer(_from, true);

        address _to = makeAddr("to");
        uint256 balanceBefore = token.balanceOf(_to);

        vm.prank(_from);
        token.transfer(_to, TRANSFER_AMOUNT);
        assertEq(token.balanceOf(_to), balanceBefore + TRANSFER_AMOUNT);
    }

    function test_transfer_afterReleaseBlock_transferSucceeds(uint256 _releaseBlock, address _from) public {
        vm.assume(_releaseBlock > 0);
        vm.assume(_from != address(0) && _from != address(this) && _from != address(PERMIT2));

        bytes memory data = abi.encode(_releaseBlock, operator, tokenMetadata);
        token = UERC20TimeLocked(
            factory.createToken("Test", "TEST", DECIMALS, INITIAL_BALANCE, address(this), data, bytes32("test"))
        );

        vm.roll(_releaseBlock);

        deal(address(token), _from, INITIAL_BALANCE);
        address _to = makeAddr("to");
        uint256 balanceBefore = token.balanceOf(_to);

        vm.prank(_from);
        token.transfer(_to, TRANSFER_AMOUNT);
        assertEq(token.balanceOf(_to), balanceBefore + TRANSFER_AMOUNT);
    }

    function test_transferFrom_revertsWithTimeLocked(uint256 _releaseBlock, address _from, address _to) public {
        vm.assume(_releaseBlock > 0);

        bytes memory data = abi.encode(_releaseBlock, operator, tokenMetadata);
        token = UERC20TimeLocked(
            factory.createToken("Test", "TEST", DECIMALS, INITIAL_BALANCE, address(this), data, bytes32("test"))
        );

        vm.roll(_releaseBlock - 1);

        vm.prank(_from);
        vm.expectRevert(abi.encodeWithSelector(UERC20TimeLocked.TimeLocked.selector));
        token.transferFrom(_from, _to, TRANSFER_AMOUNT);
    }

    function test_transferFrom_senderAllowed_transferSucceeds(uint256 _releaseBlock, address _from, address _spender)
        public
    {
        vm.assume(_releaseBlock > 0);
        vm.assume(_from != address(0) && _from != address(this) && _from != address(PERMIT2));
        vm.assume(_spender != address(0) && _spender != address(this) && _spender != address(PERMIT2));

        bytes memory data = abi.encode(_releaseBlock, operator, tokenMetadata);
        token = UERC20TimeLocked(
            factory.createToken("Test", "TEST", DECIMALS, INITIAL_BALANCE, address(this), data, bytes32("test"))
        );

        vm.roll(_releaseBlock - 1);

        vm.prank(operator);
        token.allowTransfer(_from, true);

        deal(address(token), _from, INITIAL_BALANCE);

        vm.prank(_from);
        token.approve(_spender, TRANSFER_AMOUNT);

        address _to = makeAddr("to");
        uint256 balanceBefore = token.balanceOf(_to);
        vm.prank(_spender);
        token.transferFrom(_from, _to, TRANSFER_AMOUNT);

        assertEq(token.balanceOf(_to), balanceBefore + TRANSFER_AMOUNT);
        assertEq(token.balanceOf(_from), INITIAL_BALANCE - TRANSFER_AMOUNT);
    }

    function test_transferFrom_afterReleaseBlock_transferSucceeds(
        uint256 _releaseBlock,
        address _from,
        address _spender
    ) public {
        vm.assume(_releaseBlock > 0);
        vm.assume(_from != address(0) && _from != address(this) && _from != address(PERMIT2));
        vm.assume(_spender != address(0) && _spender != address(this) && _spender != address(PERMIT2));

        bytes memory data = abi.encode(_releaseBlock, operator, tokenMetadata);
        token = UERC20TimeLocked(
            factory.createToken("Test", "TEST", DECIMALS, INITIAL_BALANCE, address(this), data, bytes32("test"))
        );

        vm.roll(_releaseBlock);

        deal(address(token), _from, INITIAL_BALANCE);
        address _to = makeAddr("to");
        uint256 balanceBefore = token.balanceOf(_to);

        vm.prank(_from);
        token.approve(_spender, TRANSFER_AMOUNT);
        vm.prank(_spender);
        token.transferFrom(_from, _to, TRANSFER_AMOUNT);

        assertEq(token.balanceOf(_to), balanceBefore + TRANSFER_AMOUNT);
        assertEq(token.balanceOf(_from), INITIAL_BALANCE - TRANSFER_AMOUNT);
    }
}
