// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {Script, console2} from "forge-std/Script.sol";
import {CreatorTech} from "../src/CreatorTech.sol";

contract DeployScript is Script {
    function setUp() public {}

    function run(address[] memory signers) public {
        vm.startBroadcast();
        CreatorTech creatorTech = new CreatorTech(signers);
        console2.log("CreatorTech deployed to:", address(creatorTech));
        vm.stopBroadcast();
    }
}
