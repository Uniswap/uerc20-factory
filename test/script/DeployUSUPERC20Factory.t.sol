// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {DeployUSUPERC20Factory} from "../../script/util/deploy/DeployUSUPERC20Factory.s.sol";
import {IUSUPERC20Factory} from "../../src/interfaces/IUSUPERC20Factory.sol";
import {Test} from "forge-std/Test.sol";

contract DeployUSUPERC20FactoryTest is Test {
    DeployUSUPERC20Factory deployer;

    function setUp() public {
        deployer = new DeployUSUPERC20Factory();
    }

    function test_run_usuperc20Factory() public {
        IUSUPERC20Factory factory = deployer.run();
        assertTrue(address(factory) != address(0));
    }
}
