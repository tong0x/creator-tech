// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "forge-std/Test.sol";
import {CreatorTech} from "../../src/CreatorTech.sol";

contract CreatorTechTest is Test {
    address owner = address(0x123);
    uint64 botId = 1;
    address creatorAddr = address(0x1);
    address[] public signers = new address[](3);
    uint256[] public signerPrivateKeys = new uint256[](3);
    CreatorTech creatorTech;

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
    }

    function testFirstBuy_creatorAddrNotSet() public {
        uint256 balanceBefore = owner.balance;
        (
            uint8[] memory v,
            bytes32[] memory r,
            bytes32[] memory s
        ) = signFirstBuyData(botId);
        creatorTech.firstBuy{value: 1 ether}(botId, v, r, s);
        uint256 keyPrice = creatorTech.getKeyPrice(0, 2);
        uint256 protocolFees = (keyPrice * creatorTech.protocolFee()) / 1 ether;
        uint256 creatorTreasuryFees = (keyPrice *
            creatorTech.creatorTreasuryFee()) / 1 ether;
        // uint256 creatorFees = (keyPrice * creatorTech.creatorFee()) / 1 ether;
        uint256 balanceAfter = balanceBefore +
            protocolFees +
            creatorTreasuryFees;
        assertEq(owner.balance, balanceAfter);
    }

    function testBindCreatorAndClaim_setCreatorAddr() public {
        (
            uint8[] memory v,
            bytes32[] memory r,
            bytes32[] memory s
        ) = signBindData(botId, creatorAddr);
        creatorTech.bindCreatorAndClaim(botId, creatorAddr, v, r, s);
        (v, r, s) = signFirstBuyData(botId);
        creatorTech.firstBuy{value: 1 ether}(botId, v, r, s);
        (, address getCreatorAddr, , ) = creatorTech.bots(botId);
        assertEq(getCreatorAddr, creatorAddr);
    }

    function testBindCreatorAndClaim_insufficientPayment() public {}

    function testBindCreatorAndClaim_unableToSendFunds() public {}

    // Utility functions

    function signFirstBuyData(
        uint64 _creatorId
    ) public view returns (uint8[] memory, bytes32[] memory, bytes32[] memory) {
        bytes32 signedHash = creatorTech._buildFirstBuySeparator(_creatorId);
        uint8[] memory v = new uint8[](3);
        bytes32[] memory r = new bytes32[](3);
        bytes32[] memory s = new bytes32[](3);
        (v[0], r[0], s[0]) = vm.sign(signerPrivateKeys[0], signedHash);
        (v[1], r[1], s[1]) = vm.sign(signerPrivateKeys[1], signedHash);
        (v[2], r[2], s[2]) = vm.sign(signerPrivateKeys[2], signedHash);
        creatorTech.recover(signedHash, v, r, s);
        return (v, r, s);
    }

    function signBindData(
        uint64 _creatorId,
        address _creatorAddr
    ) public view returns (uint8[] memory, bytes32[] memory, bytes32[] memory) {
        bytes32 signedHash = creatorTech._buildBindSeparator(
            _creatorId,
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
