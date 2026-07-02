// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {TokenFactory} from "../../src/factories/TokenFactory.sol";
import {ITokenFactory} from "../../src/interfaces/ITokenFactory.sol";
import {UERC20} from "../../src/tokens/UERC20.sol";
import {UERC20Config} from "../../src/types/UERC20Config.sol";
import {Metadata} from "../../src/types/Metadata.sol";

contract TokenFactoryTest is Test {
    TokenFactory internal factory;
    address internal creator = makeAddr("creator");
    address internal recipient = makeAddr("recipient");
    bytes32 internal constant GRAFFITI = bytes32(uint256(1));
    uint256 internal constant SUPPLY = 1_000e18;

    bytes32 internal deploymentInitCodeHash;

    function setUp() public {
        factory = new TokenFactory();
        deploymentInitCodeHash = factory.register(type(UERC20).creationCode);
    }

    function _config(uint256 supply_, address recipient_) internal pure returns (bytes memory) {
        return abi.encode(
            UERC20Config({
                name: "N",
                symbol: "S",
                decimals: 18,
                totalSupply: supply_,
                recipient: recipient_,
                metadata: Metadata({description: "", website: "", image: "", extraData: ""})
            })
        );
    }

    function test_register_keysByInitCodeHashAndStoresCode() public view {
        assertEq(deploymentInitCodeHash, keccak256(type(UERC20).creationCode));
        assertTrue(factory.implementationOf(deploymentInitCodeHash) != address(0));
    }

    function test_register_revertsOnEmptyInitCode() public {
        vm.expectRevert(ITokenFactory.EmptyInitCode.selector);
        factory.register("");
    }

    function test_register_revertsOnDuplicateInitCode() public {
        vm.expectRevert(abi.encodeWithSelector(ITokenFactory.AlreadyRegistered.selector, deploymentInitCodeHash));
        factory.register(type(UERC20).creationCode);
    }

    function test_createToken_deploysWorkingToken() public {
        vm.prank(creator);
        address token = factory.createToken(deploymentInitCodeHash, _config(SUPPLY, recipient), GRAFFITI);

        assertEq(UERC20(token).creator(), creator);
        assertEq(UERC20(token).graffiti(), GRAFFITI);
        assertEq(UERC20(token).totalSupply(), SUPPLY);
        assertEq(UERC20(token).balanceOf(recipient), SUPPLY);
    }

    function test_createToken_revertsOnUnknownId() public {
        bytes32 unknown = keccak256("unknown");
        vm.expectRevert(abi.encodeWithSelector(ITokenFactory.UnknownImplementation.selector, unknown));
        factory.createToken(unknown, _config(SUPPLY, recipient), GRAFFITI);
    }

    function test_getAddress_predictsDeployedAddress() public {
        bytes memory data = _config(SUPPLY, recipient);
        address predicted = factory.getAddress(deploymentInitCodeHash, creator, GRAFFITI, keccak256(data));

        vm.prank(creator);
        address actual = factory.createToken(deploymentInitCodeHash, data, GRAFFITI);

        assertEq(actual, predicted);
    }

    function test_getAddress_variesWithInputs() public view {
        bytes memory data = _config(SUPPLY, recipient);
        address base = factory.getAddress(deploymentInitCodeHash, creator, GRAFFITI, keccak256(data));
        assertTrue(base != factory.getAddress(deploymentInitCodeHash, creator, bytes32(uint256(2)), keccak256(data)));
        assertTrue(base != factory.getAddress(deploymentInitCodeHash, address(0xdead), GRAFFITI, keccak256(data)));
        assertTrue(
            base
                != factory.getAddress(
                    deploymentInitCodeHash, creator, GRAFFITI, keccak256(_config(SUPPLY + 1, recipient))
                )
        );
    }
}
