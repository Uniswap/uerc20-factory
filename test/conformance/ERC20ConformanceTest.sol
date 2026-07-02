// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {PERMIT_TYPEHASH, PermitExpired, InvalidPermitSignature} from "../../src/types/Permit.sol";
import {PERMIT2} from "../../src/types/Allowances.sol";

/// @notice Reusable ERC20 + EIP-2612 conformance suite. Every token feature inherits this and
/// implements `_deploy()`; the standard surface is then verified for free. Transfer-transforming
/// features override `_expectedReceived` so the movement assertions still hold.
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

    // -------------------------------------------------------------------------
    // EIP-2612 permit
    // -------------------------------------------------------------------------

    function _signPermit(
        uint256 ownerKey,
        address owner,
        address spender,
        uint256 value,
        uint256 nonce,
        uint256 deadline
    ) internal view returns (uint8 v, bytes32 r, bytes32 s) {
        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonce, deadline));
        bytes32 digest =
            keccak256(abi.encodePacked("\x19\x01", IERC20Permit(address(token)).DOMAIN_SEPARATOR(), structHash));
        (v, r, s) = vm.sign(ownerKey, digest);
    }

    function test_permit_setsAllowanceAndIncrementsNonce() public {
        (address owner, uint256 key) = makeAddrAndKey("permitOwner");
        IERC20Permit p = IERC20Permit(address(token));
        uint256 deadline = block.timestamp + 1 days;

        (uint8 v, bytes32 r, bytes32 s) = _signPermit(key, owner, bob, 100, p.nonces(owner), deadline);
        p.permit(owner, bob, 100, deadline, v, r, s);

        assertEq(token.allowance(owner, bob), 100);
        assertEq(p.nonces(owner), 1);
    }

    function test_permit_revertsWhenExpired() public {
        (address owner, uint256 key) = makeAddrAndKey("permitOwner");
        IERC20Permit p = IERC20Permit(address(token));
        uint256 deadline = block.timestamp - 1;

        (uint8 v, bytes32 r, bytes32 s) = _signPermit(key, owner, bob, 100, p.nonces(owner), deadline);
        vm.expectRevert(PermitExpired.selector);
        p.permit(owner, bob, 100, deadline, v, r, s);
    }

    function test_permit_revertsOnInvalidSignature() public {
        (address owner, uint256 key) = makeAddrAndKey("permitOwner");
        IERC20Permit p = IERC20Permit(address(token));
        uint256 deadline = block.timestamp + 1 days;

        // sign the wrong nonce so the recovered signer != owner
        (uint8 v, bytes32 r, bytes32 s) = _signPermit(key, owner, bob, 100, p.nonces(owner) + 1, deadline);
        vm.expectRevert(InvalidPermitSignature.selector);
        p.permit(owner, bob, 100, deadline, v, r, s);
    }
}
