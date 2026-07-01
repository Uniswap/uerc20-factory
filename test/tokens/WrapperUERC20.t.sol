// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {ERC20ConformanceTest} from "../conformance/ERC20ConformanceTest.sol";
import {WrapperUERC20} from "../../src/tokens/WrapperUERC20.sol";
import {IVirtualERC20} from "../../src/interfaces/IVirtualERC20.sol";
import {TokenFactory} from "../../src/factories/TokenFactory.sol";
import {UERC20Config, RecipientCannotBeZeroAddress} from "../../src/types/UERC20Config.sol";
import {Metadata} from "../../src/types/Metadata.sol";
import {MockERC20} from "../mocks/MockERC20.sol";

/// @notice WrapperUERC20 is a freely-transferable virtual token, so it inherits the shared ERC20
/// conformance suite unchanged, then adds tests for redemption of the underlying.
contract WrapperUERC20Test is ERC20ConformanceTest {
    address internal creator = makeAddr("creator");
    address internal recipient = makeAddr("recipient");
    uint256 internal constant SUPPLY = 1_000_000e18;
    bytes32 internal constant GRAFFITI = bytes32(uint256(0xabcd));

    TokenFactory internal factory;
    MockERC20 internal underlying;
    uint256 internal id;

    /// @dev Conformance deploys through the factory; the wrapper is a standard ERC20.
    function _deploy() internal override returns (IERC20 token_, address holder_, uint256 supply_) {
        factory = new TokenFactory();
        underlying = new MockERC20("Underlying", "UND", 18);
        id = factory.register(type(WrapperUERC20).creationCode);
        WrapperUERC20 t = _newWrapper(GRAFFITI, 18);
        return (IERC20(address(t)), recipient, SUPPLY);
    }

    /// @dev Encodes a wrapper config, varying only the fields the tests exercise.
    function _encode(uint8 decimals_, address underlying_) internal view returns (bytes memory) {
        return abi.encode(
            WrapperUERC20.Config({
                base: UERC20Config({
                    name: "Wrapped",
                    symbol: "WRAP",
                    decimals: decimals_,
                    totalSupply: SUPPLY,
                    recipient: recipient,
                    metadata: Metadata({description: "", website: "", image: "", extraData: ""})
                }),
                underlying: underlying_
            })
        );
    }

    function _newWrapper(bytes32 graffiti_, uint8 decimals_) internal returns (WrapperUERC20) {
        vm.prank(creator);
        return WrapperUERC20(factory.createToken(id, _encode(decimals_, address(underlying)), graffiti_));
    }

    /// @dev Deploys a fresh wrapper and funds it with `funding` of the underlying.
    function _fundedWrapper(bytes32 graffiti_, uint256 funding) internal returns (WrapperUERC20 t) {
        t = _newWrapper(graffiti_, 18);
        underlying.mint(address(t), funding);
    }

    // ---- construction ----

    function test_underlyingTokenAddress_isSet() public {
        WrapperUERC20 t = _newWrapper(bytes32(uint256(1)), 18);
        assertEq(t.UNDERLYING_TOKEN_ADDRESS(), address(underlying));
    }

    function test_constructor_revertsOnZeroUnderlying() public {
        vm.prank(creator);
        vm.expectRevert(WrapperUERC20.UnderlyingCannotBeZeroAddress.selector);
        factory.createToken(id, _encode(18, address(0)), bytes32(uint256(2)));
    }

    function test_constructor_revertsOnDecimalsMismatch() public {
        // underlying is 18 decimals; config declares 6 → mismatch
        vm.prank(creator);
        vm.expectRevert(abi.encodeWithSelector(WrapperUERC20.DecimalsMismatch.selector, uint8(6), uint8(18)));
        factory.createToken(id, _encode(6, address(underlying)), bytes32(uint256(3)));
    }

    function test_supportsInterface_advertisesVirtualERC20() public {
        WrapperUERC20 t = _newWrapper(bytes32(uint256(4)), 18);
        assertTrue(t.supportsInterface(type(IVirtualERC20).interfaceId));
        assertTrue(t.supportsInterface(type(IERC165).interfaceId));
    }

    // ---- redemption ----

    function test_redeem_burnsAndReturnsUnderlyingToCaller() public {
        WrapperUERC20 t = _fundedWrapper(bytes32(uint256(5)), SUPPLY);
        uint256 amount = 100e18;

        vm.prank(recipient);
        vm.expectEmit(true, true, false, true, address(t));
        emit WrapperUERC20.Redeemed(recipient, recipient, amount);
        t.redeem(amount);

        assertEq(t.balanceOf(recipient), SUPPLY - amount);
        assertEq(t.totalSupply(), SUPPLY - amount);
        assertEq(underlying.balanceOf(recipient), amount);
        assertEq(underlying.balanceOf(address(t)), SUPPLY - amount);
    }

    function test_redeem_toDifferentRecipient() public {
        WrapperUERC20 t = _fundedWrapper(bytes32(uint256(6)), SUPPLY);
        uint256 amount = 50e18;

        vm.prank(recipient);
        t.redeem(bob, amount);

        assertEq(t.balanceOf(recipient), SUPPLY - amount);
        assertEq(underlying.balanceOf(bob), amount);
        assertEq(underlying.balanceOf(recipient), 0);
    }

    function test_redeemFrom_spendsAllowance() public {
        WrapperUERC20 t = _fundedWrapper(bytes32(uint256(7)), SUPPLY);
        uint256 amount = 25e18;

        vm.prank(recipient);
        t.approve(bob, amount);

        vm.prank(bob);
        t.redeemFrom(recipient, alice, amount);

        assertEq(t.balanceOf(recipient), SUPPLY - amount);
        assertEq(t.allowance(recipient, bob), 0);
        assertEq(underlying.balanceOf(alice), amount);
    }

    function test_redeemFrom_revertsWithoutAllowance() public {
        WrapperUERC20 t = _fundedWrapper(bytes32(uint256(8)), SUPPLY);
        vm.prank(bob);
        vm.expectRevert(); // allowance underflow
        t.redeemFrom(recipient, alice, 1e18);
    }

    function test_redeem_revertsWhenUnderfunded() public {
        // fund with less than the redeem amount → first-come-first-served: safeTransfer reverts
        WrapperUERC20 t = _fundedWrapper(bytes32(uint256(9)), 10e18);
        vm.prank(recipient);
        vm.expectRevert(); // SafeERC20: insufficient underlying balance
        t.redeem(11e18);
    }

    function test_redeem_revertsOnZeroAmount() public {
        WrapperUERC20 t = _fundedWrapper(bytes32(uint256(10)), SUPPLY);
        vm.prank(recipient);
        vm.expectRevert(WrapperUERC20.RedeemAmountCannotBeZero.selector);
        t.redeem(0);
    }

    function test_redeem_revertsOnZeroRecipient() public {
        WrapperUERC20 t = _fundedWrapper(bytes32(uint256(11)), SUPPLY);
        vm.prank(recipient);
        vm.expectRevert(RecipientCannotBeZeroAddress.selector);
        t.redeem(address(0), 1e18);
    }

    function test_redeem_revertsOnInsufficientBalance() public {
        WrapperUERC20 t = _fundedWrapper(bytes32(uint256(12)), SUPPLY);
        vm.prank(bob); // holds nothing
        vm.expectRevert(); // burn underflow
        t.redeem(1e18);
    }

    // ---- underlying views ----

    function test_underlyingBalance_reflectsFunding() public {
        WrapperUERC20 t = _newWrapper(bytes32(uint256(13)), 18);
        assertEq(t.underlyingBalance(), 0);

        underlying.mint(address(t), SUPPLY);
        assertEq(t.underlyingBalance(), SUPPLY);
    }

    function test_underlyingTotalSupply_readsUnderlying() public {
        WrapperUERC20 t = _newWrapper(bytes32(uint256(14)), 18);
        assertEq(t.underlyingTotalSupply(), underlying.totalSupply());

        // includes underlying held elsewhere, not just what backs this wrapper
        underlying.mint(address(t), SUPPLY);
        underlying.mint(bob, 7e18);
        assertEq(t.underlyingTotalSupply(), SUPPLY + 7e18);
        assertEq(t.underlyingTotalSupply(), underlying.totalSupply());
    }

    function test_redeem_keepsBalanceCoveringSupply() public {
        // funded to back the full supply; a redeem drops held balance and token supply equally,
        // so the held balance keeps covering the remaining supply.
        WrapperUERC20 t = _fundedWrapper(bytes32(uint256(15)), SUPPLY);
        assertGe(t.underlyingBalance(), t.totalSupply());

        vm.prank(recipient);
        t.redeem(123e18);

        assertGe(t.underlyingBalance(), t.totalSupply());
    }

    function testFuzz_redeem_conservesUnderlying(uint256 amount) public {
        amount = bound(amount, 1, SUPPLY);
        WrapperUERC20 t = _fundedWrapper(bytes32(uint256(16)), SUPPLY);

        vm.prank(recipient);
        t.redeem(amount);

        // underlying leaves the contract 1:1 with the burned supply
        assertEq(underlying.balanceOf(recipient), amount);
        assertEq(t.totalSupply(), SUPPLY - amount);
        assertEq(underlying.balanceOf(address(t)) + underlying.balanceOf(recipient), SUPPLY);
    }
}
