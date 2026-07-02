// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {Permit, PERMIT_TYPEHASH, PermitExpired, InvalidPermitSignature} from "../../src/types/Permit.sol";

/// @dev Exposes the `Permit` type for isolated testing, independent of any token.
contract PermitHarness {
    Permit internal p;

    constructor(string memory name) {
        p.init(name, address(this));
    }

    function domainSeparator() external view returns (bytes32) {
        return p.domainSeparator();
    }

    function nonces(address owner) external view returns (uint256) {
        return p.nonces[owner];
    }

    function verify(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external
    {
        p.verify(owner, spender, value, deadline, v, r, s);
    }
}

contract PermitTest is Test {
    PermitHarness internal h;
    address internal spender = makeAddr("spender");

    function setUp() public {
        h = new PermitHarness("Example");
    }

    function _sign(uint256 key, address owner, uint256 value, uint256 nonce, uint256 deadline)
        internal
        view
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonce, deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", h.domainSeparator(), structHash));
        (v, r, s) = vm.sign(key, digest);
    }

    function test_verify_consumesNonce() public {
        (address owner, uint256 key) = makeAddrAndKey("owner");
        uint256 deadline = block.timestamp + 1 days;

        (uint8 v, bytes32 r, bytes32 s) = _sign(key, owner, 1e18, 0, deadline);
        h.verify(owner, spender, 1e18, deadline, v, r, s);

        assertEq(h.nonces(owner), 1);
    }

    function test_verify_revertsOnReplay() public {
        (address owner, uint256 key) = makeAddrAndKey("owner");
        uint256 deadline = block.timestamp + 1 days;

        (uint8 v, bytes32 r, bytes32 s) = _sign(key, owner, 1e18, 0, deadline);
        h.verify(owner, spender, 1e18, deadline, v, r, s);

        // nonce 0 is consumed; replaying the same signature now recovers a non-owner
        vm.expectRevert(InvalidPermitSignature.selector);
        h.verify(owner, spender, 1e18, deadline, v, r, s);
    }

    function test_verify_revertsWhenExpired() public {
        (address owner, uint256 key) = makeAddrAndKey("owner");
        uint256 deadline = block.timestamp - 1;

        (uint8 v, bytes32 r, bytes32 s) = _sign(key, owner, 1e18, 0, deadline);
        vm.expectRevert(PermitExpired.selector);
        h.verify(owner, spender, 1e18, deadline, v, r, s);
    }

    function test_domainSeparator_recomputesOnNewChainId() public {
        bytes32 before = h.domainSeparator();
        vm.chainId(block.chainid + 1);
        assertTrue(h.domainSeparator() != before);
    }
}
