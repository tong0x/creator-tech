// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "forge-std/Test.sol";
import {CreatorTech} from "../../src/CreatorTech.sol";

contract CreatorTechTest is Test {
    bytes32 botId = bytes32(uint256(123));
    address creatorAddr = address(0x1);
    address[] public signers = new address[](3);
    uint256[] public signerPrivateKeys = new uint256[](3);
    CreatorTech creatorTech;

    function setUp() public {
        signerPrivateKeys[0] = 0x1;
        signerPrivateKeys[1] = 0x2;
        signerPrivateKeys[2] = 0x3;
        signers[0] = vm.addr(signerPrivateKeys[0]);
        signers[1] = vm.addr(signerPrivateKeys[1]);
        signers[2] = vm.addr(signerPrivateKeys[2]);
        creatorTech = new CreatorTech(signers);
    }

    function testBindCreatorAndClaim_withoutUnclaimedFees() public {
        (uint8[] memory v, bytes32[] memory r, bytes32[] memory s) = signData(
            botId,
            creatorAddr
        );
        bytes32 signedHash = creatorTech._buildBindSeparator(
            botId,
            creatorAddr
        );
        // bytes32 signedHashContract = creatorTech._buildBindSeparator(
        //     creatorId,
        //     creatorAddr
        // );
        // require(signedHash == signedHashContract, "Hash mismatch");
        bool success = creatorTech.recover(signedHash, v, r, s);
        require(success, "Failed to recover");
        creatorTech.bindCreatorAndClaim(botId, creatorAddr, v, r, s);
        address ctCreatorAddr = creatorTech.getBotCreatorAddr(botId);
        assertEq(ctCreatorAddr, creatorAddr);
    }

    function testBindCreatorAndClaim_haveUnclaimedFees() public {}

    function testBindCreatorAndClaim_2() public {}

    function testBindCreatorAndClaim_3() public {}

    // Utility functions

    function signData(
        bytes32 _botId,
        address _creatorAddr
    ) public view returns (uint8[] memory, bytes32[] memory, bytes32[] memory) {
        bytes32 signedHash = creatorTech._buildBindSeparator(
            _botId,
            _creatorAddr
        );
        uint8[] memory v = new uint8[](3);
        bytes32[] memory r = new bytes32[](3);
        bytes32[] memory s = new bytes32[](3);
        (v[0], r[0], s[0]) = vm.sign(signerPrivateKeys[0], signedHash);
        (v[1], r[1], s[1]) = vm.sign(signerPrivateKeys[1], signedHash);
        (v[2], r[2], s[2]) = vm.sign(signerPrivateKeys[2], signedHash);
        creatorTech.recover(signedHash, v, r, s);
        return (v, r, s);
    }
}
