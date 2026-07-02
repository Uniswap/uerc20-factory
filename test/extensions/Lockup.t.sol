// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {Lockup} from "../../src/extensions/Lockup.sol";

/// @dev Exposes the `Lockup` policy for isolated testing, independent of any token.
contract LockupHarness {
    Lockup internal l;

    function setOwner(address o) external {
        l.setOwner(o);
    }

    function allowlist(address a, bool ok) external {
        l.allowlist(a, ok);
    }

    function unlock() external {
        l.unlock();
    }

    function allowlisted(address from, address to) external view returns (bool) {
        return l.allowlisted(from, to);
    }

    function isAllowlisted(address a) external view returns (bool) {
        return l.isAllowlisted(a);
    }

    function unlocked() external view returns (bool) {
        return l.unlocked;
    }
}

contract LockupTest is Test {
    LockupHarness internal h;
    address internal a = makeAddr("a");
    address internal b = makeAddr("b");

    function setUp() public {
        h = new LockupHarness();
    }

    function test_default_blocksAllTransfers() public view {
        assertFalse(h.allowlisted(a, b));
        assertFalse(h.unlocked());
    }

    function test_allowlistedSender_permits() public {
        h.allowlist(a, true);
        assertTrue(h.allowlisted(a, b));
    }

    function test_allowlistedRecipient_permits() public {
        h.allowlist(b, true);
        assertTrue(h.allowlisted(a, b));
    }

    function test_removingFromAllowlist_blocksAgain() public {
        h.allowlist(a, true);
        h.allowlist(a, false);
        assertFalse(h.allowlisted(a, b));
        assertFalse(h.isAllowlisted(a));
    }

    function test_unlock_permitsEveryone() public {
        h.unlock();
        assertTrue(h.unlocked());
        assertTrue(h.allowlisted(a, b));
        assertTrue(h.allowlisted(makeAddr("x"), makeAddr("y")));
    }
}
