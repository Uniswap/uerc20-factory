// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {USUPERC20Factory} from "../src/factories/USUPERC20Factory.sol";

/// @title DeployUSUPERC20Factory
/// @notice Deploys the USUPERC20Factory deterministically via CREATE2.
contract DeployUSUPERC20Factory is Script {
    /// @dev Default CREATE2 salt. Override with the SALT env var when needed.
    bytes32 internal constant DEFAULT_SALT = bytes32(0);

    function run() external returns (USUPERC20Factory factory) {
        bytes32 salt = vm.envOr("SALT", DEFAULT_SALT);

        vm.startBroadcast();
        factory = new USUPERC20Factory{salt: salt}();
        vm.stopBroadcast();

        console2.log("USUPERC20Factory deployed at:", address(factory));
    }
}
