// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {ERC20ConformanceTest} from "../conformance/ERC20ConformanceTest.sol";
import {UERC20} from "../../src/tokens/UERC20.sol";
import {TokenFactory} from "../../src/factories/TokenFactory.sol";
import {UERC20Config, RecipientCannotBeZeroAddress, TotalSupplyCannotBeZero} from "../../src/types/UERC20Config.sol";
import {Metadata} from "../../src/types/Metadata.sol";

/// @notice Base UERC20: inherits the shared ERC20 conformance suite, then adds only its own logic.
/// Deploys through a real TokenFactory to exercise the implementation registry + `deployment()` callback path.
contract UERC20Test is ERC20ConformanceTest {
    address internal creator = makeAddr("creator");
    address internal recipient = makeAddr("recipient");
    uint256 internal constant SUPPLY = 1_000_000e18;
    bytes32 internal constant GRAFFITI = bytes32(uint256(0xabcd));

    TokenFactory internal factory;
    bytes32 internal deploymentInitCodeHash;

    function _deploy() internal override returns (IERC20 token_, address holder_, uint256 supply_) {
        factory = new TokenFactory();
        deploymentInitCodeHash = factory.register(type(UERC20).creationCode);
        vm.prank(creator);
        address t = factory.createToken(deploymentInitCodeHash, _config(SUPPLY, recipient), GRAFFITI);
        return (IERC20(t), recipient, SUPPLY);
    }

    function _config(uint256 supply_, address recipient_) internal pure returns (bytes memory) {
        return abi.encode(
            UERC20Config({
                name: "Uniswap Token",
                symbol: "UNI",
                decimals: 18,
                totalSupply: supply_,
                recipient: recipient_,
                metadata: Metadata({
                    description: "Uniswap governance token", website: "https://uniswap.org", image: "", extraData: ""
                })
            })
        );
    }

    function test_constructor_setsIdentity() public view {
        UERC20 t = UERC20(address(token));
        assertEq(t.name(), "Uniswap Token");
        assertEq(t.symbol(), "UNI");
        assertEq(t.decimals(), 18);
        assertEq(t.creator(), creator);
        assertEq(t.graffiti(), GRAFFITI);
    }

    function test_metadata_storedAndRendered() public view {
        UERC20 t = UERC20(address(token));
        (string memory description, string memory website, string memory image,) = t.metadata();
        assertEq(description, "Uniswap governance token");
        assertEq(website, "https://uniswap.org");
        assertEq(image, "");

        Metadata memory expected = Metadata({
            description: "Uniswap governance token", website: "https://uniswap.org", image: "", extraData: ""
        });
        assertEq(t.tokenURI(), expected.toJSON());
    }

    function test_supportsInterface() public view {
        UERC20 t = UERC20(address(token));
        assertTrue(t.supportsInterface(type(IERC165).interfaceId));
        assertTrue(t.supportsInterface(type(IERC20).interfaceId));
        assertFalse(t.supportsInterface(0xffffffff));
    }

    function test_createToken_revertsOnZeroRecipient() public {
        vm.expectRevert(RecipientCannotBeZeroAddress.selector);
        factory.createToken(deploymentInitCodeHash, _config(SUPPLY, address(0)), GRAFFITI);
    }

    function test_createToken_revertsOnZeroSupply() public {
        vm.expectRevert(TotalSupplyCannotBeZero.selector);
        factory.createToken(deploymentInitCodeHash, _config(0, recipient), GRAFFITI);
    }
}
