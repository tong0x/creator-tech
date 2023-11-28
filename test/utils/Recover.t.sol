// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "forge-std/Test.sol";

contract RecoverTest is Test {
    uint256 signerPrivateKeys;
    address signer;

    function setUp() public {
        signerPrivateKeys = 0x99b07ead3e50245003d7c1c6e5ac5fcc5ac15fd2ddfda22a6a4f423b90e61143;
        signer = vm.addr(signerPrivateKeys);
    }

    function testSignatureRecover() public {
        address testBuyer = 0x55B0023B2f59881f7125f183953a61ee3069833c;
        bytes32 testHash = keccak256(abi.encodePacked(testBuyer));
        console2.log("Test Hash:");
        console.logBytes32(testHash);
        console2.log("Test Data Signature:");
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKeys, testHash);
        console2.log("uint8 v:");
        console.logUint(v);
        console2.log("bytes32 r:");
        console.logBytes32(r);
        console2.log("bytes32 s:");
        console.logBytes32(s);
        address getSigner = ecrecover(testHash, v, r, s);
        assertEq(signer, getSigner); // [PASS]
    }
}
