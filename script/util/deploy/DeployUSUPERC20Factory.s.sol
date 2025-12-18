// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {IUSUPERC20Factory} from "../../../src/interfaces/IUSUPERC20Factory.sol";
import {USUPERC20Factory} from "../../../src/factories/USUPERC20Factory.sol";

contract DeployUSUPERC20Factory is Script {
    function run() public returns (IUSUPERC20Factory factory) {
        vm.startBroadcast();

        factory = new USUPERC20Factory{salt: bytes32(0)}();

        console.log("USUPERC20Factory deployed to:", address(factory));
        vm.stopBroadcast();
    }
}
