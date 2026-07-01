// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20ConformanceTest} from "../conformance/ERC20ConformanceTest.sol";
import {UERC20} from "../../src/tokens/UERC20.sol";

/// @notice Base UERC20: inherits the shared ERC20 conformance suite, then adds only its own logic.
contract UERC20Test is ERC20ConformanceTest {
    address internal creator = makeAddr("creator");
    address internal recipient = makeAddr("recipient");
    uint256 internal constant SUPPLY = 1_000_000e18;
    bytes32 internal constant GRAFFITI = bytes32(uint256(0xabcd));

    function _deploy() internal override returns (IERC20 token_, address holder_, uint256 supply_) {
        UERC20 t = new UERC20("Uniswap Token", "UNI", 18, SUPPLY, recipient, creator, GRAFFITI);
        return (IERC20(address(t)), recipient, SUPPLY);
    }

    function test_constructor_setsMetadata() public view {
        UERC20 t = UERC20(address(token));
        assertEq(t.name(), "Uniswap Token");
        assertEq(t.symbol(), "UNI");
        assertEq(t.decimals(), 18);
        assertEq(t.creator(), creator);
        assertEq(t.graffiti(), GRAFFITI);
    }

    function test_constructor_revertsOnZeroRecipient() public {
        vm.expectRevert(UERC20.RecipientCannotBeZeroAddress.selector);
        new UERC20("N", "S", 18, SUPPLY, address(0), creator, GRAFFITI);
    }

    function test_constructor_revertsOnZeroSupply() public {
        vm.expectRevert(UERC20.TotalSupplyCannotBeZero.selector);
        new UERC20("N", "S", 18, 0, recipient, creator, GRAFFITI);
    }
}
