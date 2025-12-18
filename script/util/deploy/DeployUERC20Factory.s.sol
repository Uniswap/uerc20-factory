// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {IUERC20Factory} from "../../../src/interfaces/IUERC20Factory.sol";
import {UERC20Factory} from "../../../src/factories/UERC20Factory.sol";

contract DeployUERC20Factory is Script {
    function run() public returns (IUERC20Factory factory) {
        vm.startBroadcast();

        factory = new UERC20Factory{salt: bytes32(0)}();

        console.log("IUERC20Factory deployed to:", address(factory));
        vm.stopBroadcast();
    }
}
