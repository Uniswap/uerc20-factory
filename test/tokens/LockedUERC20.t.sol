// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20ConformanceTest} from "../conformance/ERC20ConformanceTest.sol";
import {LockedUERC20} from "../../src/tokens/LockedUERC20.sol";
import {TokenFactory} from "../../src/factories/TokenFactory.sol";
import {UERC20Config} from "../../src/types/UERC20Config.sol";
import {Metadata} from "../../src/types/Metadata.sol";

/// @notice LockedUERC20 reuses the shared ERC20 conformance suite (deployed unlocked, so it behaves
/// as a standard ERC20), then adds tests for its lock-specific behavior on fresh locked instances.
contract LockedUERC20Test is ERC20ConformanceTest {
    address internal creator = makeAddr("creator");
    address internal recipient = makeAddr("recipient");
    address internal owner = makeAddr("owner");
    uint256 internal constant SUPPLY = 1_000_000e18;
    bytes32 internal constant GRAFFITI = bytes32(uint256(0xabcd));

    TokenFactory internal factory;
    bytes32 internal deploymentInitCodeHash;

    /// @dev Conformance deploys through the factory and unlocks so standard ERC20 holds.
    function _deploy() internal override returns (IERC20 token_, address holder_, uint256 supply_) {
        factory = new TokenFactory();
        deploymentInitCodeHash = factory.register(type(LockedUERC20).creationCode);
        // owner = this test contract, so we can unlock() directly for the conformance suite.
        LockedUERC20 t = _newLocked(address(this), GRAFFITI);
        t.unlock();
        return (IERC20(address(t)), recipient, SUPPLY);
    }

    function _newLocked(address owner_, bytes32 graffiti_) internal returns (LockedUERC20) {
        bytes memory data = abi.encode(
            LockedUERC20.Config({
                base: UERC20Config({
                    name: "Locked",
                    symbol: "LOCK",
                    decimals: 18,
                    totalSupply: SUPPLY,
                    recipient: recipient,
                    metadata: Metadata({description: "", website: "", image: "", extraData: ""})
                }),
                owner: owner_
            })
        );
        vm.prank(creator);
        return LockedUERC20(factory.createToken(deploymentInitCodeHash, data, graffiti_));
    }

    // ---- lock behavior (fresh locked instances) ----

    function test_transfer_revertsWhenLockedAndNotAllowlisted() public {
        LockedUERC20 t = _newLocked(owner, bytes32(uint256(1)));
        assertFalse(t.unlocked());
        vm.prank(recipient);
        vm.expectRevert(abi.encodeWithSelector(LockedUERC20.TransferLocked.selector, recipient, bob));
        t.transfer(bob, 1e18);
    }

    function test_transfer_succeedsWhenSenderAllowlisted() public {
        LockedUERC20 t = _newLocked(owner, bytes32(uint256(2)));
        vm.prank(owner);
        t.allowlist(recipient, true);

        vm.prank(recipient);
        assertTrue(t.transfer(bob, 1e18));
        assertEq(t.balanceOf(bob), 1e18);
    }

    function test_transfer_succeedsWhenRecipientAllowlisted() public {
        LockedUERC20 t = _newLocked(owner, bytes32(uint256(3)));
        vm.prank(owner);
        t.allowlist(bob, true);

        vm.prank(recipient);
        assertTrue(t.transfer(bob, 1e18));
    }

    function test_transfer_succeedsAfterUnlock() public {
        LockedUERC20 t = _newLocked(owner, bytes32(uint256(4)));
        vm.prank(owner);
        t.unlock();

        vm.prank(recipient);
        assertTrue(t.transfer(bob, 1e18));
    }

    function test_transferFrom_gatedByLock() public {
        LockedUERC20 t = _newLocked(owner, bytes32(uint256(5)));
        vm.prank(recipient);
        t.approve(bob, 1e18);

        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(LockedUERC20.TransferLocked.selector, recipient, alice));
        t.transferFrom(recipient, alice, 1e18);

        vm.prank(owner);
        t.allowlist(recipient, true);
        vm.prank(bob);
        assertTrue(t.transferFrom(recipient, alice, 1e18));
    }

    function test_initialMint_notGatedByLock() public {
        LockedUERC20 t = _newLocked(owner, bytes32(uint256(6)));
        assertFalse(t.unlocked());
        assertEq(t.balanceOf(recipient), SUPPLY);
        assertEq(t.totalSupply(), SUPPLY);
    }

    function test_allowlist_onlyOwner() public {
        LockedUERC20 t = _newLocked(owner, bytes32(uint256(7)));
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(LockedUERC20.NotOwner.selector, bob));
        t.allowlist(bob, true);
    }

    function test_unlock_onlyOwner() public {
        LockedUERC20 t = _newLocked(owner, bytes32(uint256(8)));
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(LockedUERC20.NotOwner.selector, bob));
        t.unlock();
    }

    function test_setOwner_transfersControl() public {
        LockedUERC20 t = _newLocked(owner, bytes32(uint256(9)));
        address newOwner = makeAddr("newOwner");

        vm.prank(owner);
        t.setOwner(newOwner);
        assertEq(t.owner(), newOwner);

        // old owner can no longer act
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(LockedUERC20.NotOwner.selector, owner));
        t.unlock();

        // new owner can
        vm.prank(newOwner);
        t.unlock();
        assertTrue(t.unlocked());
    }

    function test_allowlist_emitsEvent() public {
        LockedUERC20 t = _newLocked(owner, bytes32(uint256(10)));
        vm.prank(owner);
        vm.expectEmit(true, false, false, true, address(t));
        emit LockedUERC20.Allowlisted(bob, true);
        t.allowlist(bob, true);
    }
}
