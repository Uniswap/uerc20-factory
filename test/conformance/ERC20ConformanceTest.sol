// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {PERMIT2} from "../../src/types/Allowances.sol";

/// @notice Reusable ERC20 conformance suite. Every token feature inherits this and implements
/// `_deploy()`; the standard balance/allowance/transfer surface is then verified for free.
/// Transfer-transforming features (e.g. fee-on-transfer) override `_expectedReceived` so the
/// movement assertions still hold under a modified transfer.
abstract contract ERC20ConformanceTest is Test {
    IERC20 internal token;
    address internal initialHolder;
    uint256 internal supply;

    address internal alice = makeAddr("alice");
    address internal bob = makeAddr("bob");

    /// @dev Implemented per feature: deploy the token and report who holds the initial `supply`.
    function _deploy() internal virtual returns (IERC20 token_, address holder_, uint256 supply_);

    /// @dev Amount `to` actually receives when `amount` is sent. Overridden by transform features.
    function _expectedReceived(uint256 amount) internal view virtual returns (uint256) {
        return amount;
    }

    function setUp() public virtual {
        (token, initialHolder, supply) = _deploy();
    }

    function test_totalSupply_matchesInitial() public view {
        assertEq(token.totalSupply(), supply);
    }

    function test_initialHolder_holdsFullSupply() public view {
        assertEq(token.balanceOf(initialHolder), supply);
    }

    function test_transfer_movesBalanceAndReturnsTrue() public {
        uint256 amount = supply / 2;
        uint256 received = _expectedReceived(amount);

        vm.prank(initialHolder);
        vm.expectEmit(true, true, false, true, address(token));
        emit IERC20.Transfer(initialHolder, bob, amount);
        bool ok = token.transfer(bob, amount);

        assertTrue(ok);
        assertEq(token.balanceOf(bob), received);
        assertEq(token.balanceOf(initialHolder), supply - amount);
    }

    function test_transfer_revertsOnInsufficientBalance() public {
        vm.prank(bob); // bob holds nothing
        vm.expectRevert();
        token.transfer(alice, 1);
    }

    function test_approve_setsAllowanceAndReturnsTrue() public {
        vm.prank(alice);
        vm.expectEmit(true, true, false, true, address(token));
        emit IERC20.Approval(alice, bob, 100);
        bool ok = token.approve(bob, 100);

        assertTrue(ok);
        assertEq(token.allowance(alice, bob), 100);
    }

    function test_transferFrom_spendsFiniteAllowance() public {
        uint256 amount = supply / 4;

        vm.prank(initialHolder);
        token.approve(bob, amount);

        vm.prank(bob);
        token.transferFrom(initialHolder, alice, amount);

        assertEq(token.balanceOf(alice), _expectedReceived(amount));
        assertEq(token.allowance(initialHolder, bob), 0);
    }

    function test_transferFrom_infiniteAllowanceNotDecremented() public {
        uint256 amount = supply / 4;

        vm.prank(initialHolder);
        token.approve(bob, type(uint256).max);

        vm.prank(bob);
        token.transferFrom(initialHolder, alice, amount);

        assertEq(token.allowance(initialHolder, bob), type(uint256).max);
    }

    function test_permit2_hasInfiniteAllowanceByDefault() public view {
        assertEq(token.allowance(alice, PERMIT2), type(uint256).max);
    }
}
