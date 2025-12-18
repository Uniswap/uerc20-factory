// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {DeployUERC20Factory} from "../../script/util/deploy/DeployUERC20Factory.s.sol";
import {IUERC20Factory} from "../../src/interfaces/IUERC20Factory.sol";
import {Test} from "forge-std/Test.sol";

contract DeployUERC20FactoryTest is Test {
    DeployUERC20Factory deployer;

    function setUp() public {
        deployer = new DeployUERC20Factory();
    }

    function test_run_uerc20Factory() public {
        IUERC20Factory factory = deployer.run();
        assertTrue(address(factory) != address(0));
    }
}
