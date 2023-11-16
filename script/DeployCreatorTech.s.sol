// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {Script, console2} from "forge-std/Script.sol";
import {CreatorTech} from "../src/CreatorTech.sol";

contract DeployScript is Script {
    address[] signers;

    function setUp() public {
        signers.push(address(0x1234567890123456789012345678901234567890));
        signers.push(address(0x1234567890123456789012345678901234567891));
        signers.push(address(0x1234567890123456789012345678901234567892));
    }

    function run() public {
        vm.startBroadcast();
        CreatorTech creatorTech = new CreatorTech(signers);
        console2.log("CreatorTech deployed to:", address(creatorTech));
        vm.stopBroadcast();
    }
}
