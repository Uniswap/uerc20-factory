// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {UERC20Factory} from "../src/factories/UERC20Factory.sol";
import {console} from "forge-std/console.sol";

/// @title DeployUERC20Factory
/// @notice Deploys the UERC20Factory deterministically via CREATE2.
contract DeployUERC20Factory is Script {
    /// @dev Default CREATE2 salt. Override with the SALT env var when needed.
    bytes32 internal constant DEFAULT_SALT = bytes32(0);

    function run() external returns (UERC20Factory factory) {
        bytes32 salt = vm.envOr("SALT", DEFAULT_SALT);

        bytes32 initcodeHash = keccak256(abi.encodePacked(type(UERC20Factory).creationCode));
        console.logBytes32(initcodeHash);

        vm.startBroadcast();
        /// salt 0x2e36e8638e3163474ff2b2a355e1de801786d9ef34436cd7dd6418693d4474d8 deploys to 0x000000e200088D55C39a11F609E5F667729ad49b
        factory = new UERC20Factory{salt: salt}();
        vm.stopBroadcast();

        console2.log("UERC20Factory deployed at:", address(factory));
    }
}
