// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "forge-std/Test.sol";
import {CreatorTech} from "../../src/CreatorTech.sol";

abstract contract TestHelper is Test {
    uint256 signersAmount = 3;
    address payable immutable DEV = payable(makeAddr("owner"));
    address payable immutable ALICE = payable(makeAddr("alice"));
    address payable immutable BOB = payable(makeAddr("bob"));

    uint256[] public signerPrivateKeys = new uint256[](signersAmount);
    address[] public signers = new address[](signersAmount);

    CreatorTech internal creatorTech;

    function setUp() public virtual {
        signerPrivateKeys[0] = 0x1;
        signerPrivateKeys[1] = 0x2;
        signerPrivateKeys[2] = 0x3;
        signers[0] = vm.addr(signerPrivateKeys[0]);
        signers[1] = vm.addr(signerPrivateKeys[1]);
        signers[2] = vm.addr(signerPrivateKeys[2]);
        vm.prank(DEV);
        creatorTech = new CreatorTech(signers);
    }

    function signData(
        bytes32 signedHash
    ) public view returns (uint8[] memory, bytes32[] memory, bytes32[] memory) {
        uint8[] memory v = new uint8[](signersAmount);
        bytes32[] memory r = new bytes32[](signersAmount);
        bytes32[] memory s = new bytes32[](signersAmount);
        for (uint i = 0; i < signersAmount; i++) {
            (v[i], r[i], s[i]) = vm.sign(signerPrivateKeys[i], signedHash);
        }
        printSignData(v, r, s);
        return (v, r, s);
    }

    function printSignData(
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) public view {
        console2.log("uint8[%d] v:", v.length);
        for (uint i = 0; i < v.length; i++) {
            console.logUint(v[i]);
        }
        console2.log("bytes32[%d] r:", r.length);
        for (uint i = 0; i < r.length; i++) {
            console.logBytes32(r[i]);
        }
        console2.log("bytes32[%d] s:", s.length);
        for (uint i = 0; i < s.length; i++) {
            console.logBytes32(s[i]);
        }
    }
}
