// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "forge-std/Test.sol";
import {CreatorTech} from "../../src/CreatorTech.sol";

import {MockEIP712} from "../utils/MockEIP712.sol"; // mock contract address for verification

contract CreatorTechTest is Test {
    address[] public signers = new address[](3);
    uint256[] public signerPrivateKeys = new uint256[](3);
    CreatorTech creatorTech;
    MockEIP712 mockEIP712;

    function setUp() public {
        signerPrivateKeys[0] = 0x1;
        signerPrivateKeys[1] = 0x2;
        signerPrivateKeys[2] = 0x3;
        signers[0] = vm.addr(signerPrivateKeys[0]);
        signers[1] = vm.addr(signerPrivateKeys[1]);
        signers[2] = vm.addr(signerPrivateKeys[2]);
        creatorTech = new CreatorTech(signers);
        mockEIP712 = new MockEIP712("CreatorTech", "1", address(creatorTech));
    }

    function testBindCreatorAndClaim_withoutUnclaimedFees() public {
        uint64 botId = 1;
        address creatorAddr = address(0x1);
        (uint8[] memory v, bytes32[] memory r, bytes32[] memory s) = signData(
            botId,
            creatorAddr
        );
        bytes32 signedHash = _buildBindSeparator(botId, creatorAddr);
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

    function signData(
        uint64 _creatorId,
        address _creatorAddr
    ) public view returns (uint8[] memory, bytes32[] memory, bytes32[] memory) {
        bytes32 signedHash = _buildBindSeparator(_creatorId, _creatorAddr);
        uint8[] memory v = new uint8[](3);
        bytes32[] memory r = new bytes32[](3);
        bytes32[] memory s = new bytes32[](3);
        (v[0], r[0], s[0]) = vm.sign(signerPrivateKeys[0], signedHash);
        (v[1], r[1], s[1]) = vm.sign(signerPrivateKeys[1], signedHash);
        (v[2], r[2], s[2]) = vm.sign(signerPrivateKeys[2], signedHash);
        creatorTech.recover(signedHash, v, r, s);
        return (v, r, s);
    }

    function _buildBindSeparator(
        uint64 _creatorId,
        address _creatorAddr
    ) public view returns (bytes32) {
        bytes32 BIND_TYPEHASH = keccak256(
            abi.encodePacked("Bind(uint64 creatorId,address creatorAddr)")
        );
        return
            mockEIP712._hashTypedDataV4(
                keccak256(abi.encode(BIND_TYPEHASH, _creatorId, _creatorAddr))
            );
    }
}
