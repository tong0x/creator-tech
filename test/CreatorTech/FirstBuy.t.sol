// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "forge-std/Test.sol";
import {CreatorTech} from "../../src/CreatorTech.sol";

import {MockEIP712} from "../utils/MockEIP712.sol"; // mock contract address for verification

contract CreatorTechTest is Test {
    address owner = address(0x123);
    uint64 creatorId = 1;
    address creatorAddr = address(0x1);
    address[] public signers = new address[](3);
    uint256[] public signerPrivateKeys = new uint256[](3);
    CreatorTech creatorTech;
    MockEIP712 mockEIP712;

    struct Creator {
        address creatorAddr; // ETH address of creator
        uint256 totalBots; // total amount of bots of this creator
        mapping(uint256 => Bot) bots; // bot idx => bot
        uint256 unclaimedCreatorFees; // total amount of unclaimed creator fees
    }

    struct Bot {
        uint64 creatorId; // Twitter UUID
        mapping(address => uint256) balanceOf; // trader => balance of keys
        uint256 totalSupply; // of keys
    }

    function setUp() public {
        signerPrivateKeys[0] = 0x1;
        signerPrivateKeys[1] = 0x2;
        signerPrivateKeys[2] = 0x3;
        signers[0] = vm.addr(signerPrivateKeys[0]);
        signers[1] = vm.addr(signerPrivateKeys[1]);
        signers[2] = vm.addr(signerPrivateKeys[2]);
        vm.prank(owner);
        vm.deal(owner, 1000 ether);
        creatorTech = new CreatorTech(signers);
        mockEIP712 = new MockEIP712("CreatorTech", "1", address(creatorTech));
    }

    function testFirstBuy_creatorAddrNotSet() public {
        (uint8[] memory v, bytes32[] memory r, bytes32[] memory s) = signData(
            creatorId
        );
        creatorTech.firstBuy{value: 1 ether}(creatorId, v, r, s);
        (, uint256 totalBots, ) = creatorTech.creators(creatorId);
        assertEq(totalBots, 1);
    }

    function testBindCreatorAndClaim_setCreatorAddr() public {}

    function testBindCreatorAndClaim_2() public {}

    function testBindCreatorAndClaim_3() public {}

    // Utility functions

    function signData(
        uint64 _creatorId
    ) public view returns (uint8[] memory, bytes32[] memory, bytes32[] memory) {
        bytes32 signedHash = _buildFirstBuySeparator(_creatorId);
        uint8[] memory v = new uint8[](3);
        bytes32[] memory r = new bytes32[](3);
        bytes32[] memory s = new bytes32[](3);
        (v[0], r[0], s[0]) = vm.sign(signerPrivateKeys[0], signedHash);
        (v[1], r[1], s[1]) = vm.sign(signerPrivateKeys[1], signedHash);
        (v[2], r[2], s[2]) = vm.sign(signerPrivateKeys[2], signedHash);
        creatorTech.recover(signedHash, v, r, s);
        return (v, r, s);
    }

    function _buildFirstBuySeparator(
        uint64 _creatorId
    ) public view returns (bytes32) {
        bytes32 FIRSTBUY_TYPEHASH = keccak256(
            abi.encodePacked("FirstBuy(uint64 creatorId)")
        );
        return
            mockEIP712._hashTypedDataV4(
                keccak256(abi.encode(FIRSTBUY_TYPEHASH, _creatorId))
            );
    }
}
