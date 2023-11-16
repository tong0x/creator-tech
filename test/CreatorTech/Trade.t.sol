// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "forge-std/Test.sol";

import {SignData} from "../utils/SignData.sol";
import {CreatorTech} from "../../src/CreatorTech.sol";

contract CreatorTechTest is Test, SignData {
    address owner = address(0x123);
    address trader = address(0x234);
    bytes32 botId = bytes32(uint256(123));
    address creatorAddr = address(0x1);
    uint256 firstBuyAmount = 3;
    uint256 buyAmount = 5;

    CreatorTech creatorTech;

    function setUp() public {
        // signerPrivateKeys[0] = 0x1;
        // signerPrivateKeys[1] = 0x2;
        // signerPrivateKeys[2] = 0x3;
        // signers[0] = vm.addr(signerPrivateKeys[0]);
        // signers[1] = vm.addr(signerPrivateKeys[1]);
        // signers[2] = vm.addr(signerPrivateKeys[2]);
        vm.prank(owner);
        vm.deal(owner, 1000 ether);
        vm.deal(trader, 1000 ether);
        // vm.deal(address(this), 1000 ether);
        creatorTech = new CreatorTech(signers);
    }

    function testFirstBuy_creatorAddrNotSet() public {
        uint256 balanceBefore = owner.balance;
        bytes32 signedHash = creatorTech._buildFirstBuySeparator(
            botId,
            firstBuyAmount
        );
        (uint8[] memory v, bytes32[] memory r, bytes32[] memory s) = signData(
            signedHash
        );
        creatorTech.firstBuy{value: 1 ether}(botId, firstBuyAmount, v, r, s);
        uint256 keyPrice = creatorTech.getKeyPrice(0, firstBuyAmount + 1);
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
        bytes32 signedHash = creatorTech._buildBindSeparator(
            botId,
            creatorAddr
        );
        (uint8[] memory v, bytes32[] memory r, bytes32[] memory s) = signData(
            signedHash
        );
        creatorTech.bindCreatorAndClaim(botId, creatorAddr, v, r, s);
        signedHash = creatorTech._buildFirstBuySeparator(botId, firstBuyAmount);
        (v, r, s) = signData(signedHash);
        creatorTech.firstBuy{value: 1 ether}(botId, firstBuyAmount, v, r, s);
        (, address getCreatorAddr, , ) = creatorTech.bots(botId);
        assertEq(getCreatorAddr, creatorAddr);
    }

    function testBindCreatorAndClaim_insufficientPayment() public {}

    function testBindCreatorAndClaim_unableToSendFunds() public {}

    function testBuyKey() public {
        bytes32 signedHash = creatorTech._buildFirstBuySeparator(
            botId,
            firstBuyAmount
        );
        (uint8[] memory v, bytes32[] memory r, bytes32[] memory s) = signData(
            signedHash
        );
        creatorTech.firstBuy{value: 1 ether}(botId, firstBuyAmount, v, r, s);
        vm.startPrank(trader);
        signedHash = creatorTech._buildBuySeparator(botId, buyAmount);
        (v, r, s) = signData(signedHash);
        creatorTech.buyKey{value: 1 ether}(botId, buyAmount, v, r, s);
        uint256 balanceOfBuyer = creatorTech.getBotBalanceOf(
            botId,
            address(trader)
        );
        assertEq(balanceOfBuyer, buyAmount);
        vm.stopPrank();
    }

    function testSellKey() public {
        bytes32 signedHash = creatorTech._buildFirstBuySeparator(
            botId,
            firstBuyAmount
        );
        (uint8[] memory v, bytes32[] memory r, bytes32[] memory s) = signData(
            signedHash
        );
        creatorTech.firstBuy{value: 1 ether}(botId, firstBuyAmount, v, r, s);
        signedHash = creatorTech._buildBuySeparator(botId, buyAmount);
        (v, r, s) = signData(signedHash);
        vm.startPrank(trader);
        creatorTech.buyKey{value: 1 ether}(botId, buyAmount, v, r, s);
        uint256 balanceOfBuyer = creatorTech.getBotBalanceOf(
            botId,
            address(trader)
        );
        assertEq(balanceOfBuyer, buyAmount);
        creatorTech.sellKey(botId, buyAmount);
        balanceOfBuyer = creatorTech.getBotBalanceOf(botId, address(trader));
        assertEq(balanceOfBuyer, 0);
        vm.stopPrank();
    }
}
