// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {UERC20Factory} from "../src/factories/UERC20Factory.sol";

/// @title DeployUERC20Factory
/// @notice Deploys the UERC20Factory deterministically via CREATE2.
contract DeployUERC20Factory is Script {
    /// @dev Default CREATE2 salt. Override with the SALT env var when needed.
    bytes32 internal constant DEFAULT_SALT = bytes32(0);

    function run() external returns (UERC20Factory factory) {
        bytes32 salt = vm.envOr("SALT", DEFAULT_SALT);

        vm.startBroadcast();
        factory = new UERC20Factory{salt: salt}();
        vm.stopBroadcast();

        console2.log("UERC20Factory deployed at:", address(factory));
    }
}
