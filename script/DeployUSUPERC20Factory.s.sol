// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {USUPERC20Factory} from "../src/factories/USUPERC20Factory.sol";
import {console} from "forge-std/console.sol";

/// @title DeployUSUPERC20Factory
/// @notice Deploys the USUPERC20Factory deterministically via CREATE2.
contract DeployUSUPERC20Factory is Script {
    /// @dev Default CREATE2 salt. Override with the SALT env var when needed.
    bytes32 internal constant DEFAULT_SALT = bytes32(0);

    function run() external returns (USUPERC20Factory factory) {
        bytes32 salt = vm.envOr("SALT", DEFAULT_SALT);

        bytes32 initcodeHash = keccak256(abi.encodePacked(type(USUPERC20Factory).creationCode));
        console.logBytes32(initcodeHash);

        // salt 0x0524f579a286d355aba261051021a5be1e026d1cfc88150fdd4d05b563a996f7 deploys to 0xeEeeEEE204Afb6BABb1287ffed52cCD6BA0b0fb2
        vm.startBroadcast();
        factory = new USUPERC20Factory{salt: salt}();
        vm.stopBroadcast();

        console2.log("USUPERC20Factory deployed at:", address(factory));
    }
}
