// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20ConformanceTest} from "../conformance/ERC20ConformanceTest.sol";
import {UERC20} from "../../src/tokens/UERC20.sol";
import {TokenFactory} from "../../src/factories/TokenFactory.sol";

/// @notice Base UERC20: inherits the shared ERC20 conformance suite, then adds only its own logic.
/// Deploys through a real TokenFactory to exercise the blueprint + `deployment()` callback path.
contract UERC20Test is ERC20ConformanceTest {
    address internal creator = makeAddr("creator");
    address internal recipient = makeAddr("recipient");
    uint256 internal constant SUPPLY = 1_000_000e18;
    bytes32 internal constant GRAFFITI = bytes32(uint256(0xabcd));

    TokenFactory internal factory;
    uint256 internal blueprintId;

    function _deploy() internal override returns (IERC20 token_, address holder_, uint256 supply_) {
        factory = new TokenFactory();
        blueprintId = factory.register(type(UERC20).creationCode);
        bytes memory data = _config(SUPPLY, recipient);
        vm.prank(creator);
        address t = factory.createToken(blueprintId, data, GRAFFITI);
        return (IERC20(t), recipient, SUPPLY);
    }

    function _config(uint256 supply_, address recipient_) internal pure returns (bytes memory) {
        return abi.encode(
            UERC20.Config({
                name: "Uniswap Token", symbol: "UNI", decimals: 18, totalSupply: supply_, recipient: recipient_
            })
        );
    }

    function test_constructor_setsMetadata() public view {
        UERC20 t = UERC20(address(token));
        assertEq(t.name(), "Uniswap Token");
        assertEq(t.symbol(), "UNI");
        assertEq(t.decimals(), 18);
        assertEq(t.creator(), creator);
        assertEq(t.graffiti(), GRAFFITI);
    }

    function test_createToken_revertsOnZeroRecipient() public {
        vm.expectRevert(UERC20.RecipientCannotBeZeroAddress.selector);
        factory.createToken(blueprintId, _config(SUPPLY, address(0)), GRAFFITI);
    }

    function test_createToken_revertsOnZeroSupply() public {
        vm.expectRevert(UERC20.TotalSupplyCannotBeZero.selector);
        factory.createToken(blueprintId, _config(0, recipient), GRAFFITI);
    }
}
