// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {Script, console2} from "forge-std/Script.sol";
import {CreatorTech} from "../src/CreatorTech.sol";

contract DeployScript is Script {
    uint256[] public signerPrivateKeys = [0x1, 0x2, 0x3];
    address[] public signers = [
        vm.addr(signerPrivateKeys[0]),
        vm.addr(signerPrivateKeys[1]),
        vm.addr(signerPrivateKeys[2])
    ];

    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        CreatorTech creatorTech = new CreatorTech(signers);
        console2.log("CreatorTech deployed to:", address(creatorTech));
        vm.stopBroadcast();
    }
}
