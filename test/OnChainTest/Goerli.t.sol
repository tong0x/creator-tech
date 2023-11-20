// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "forge-std/Test.sol";
import {SignData} from "../utils/SignData.sol";
import {CreatorTech} from "../../src/CreatorTech.sol";

contract CreatorTechTest is Test, SignData {
    address owner = address(0xE6f27ad7e6b7297F7324a0a7d10Dd9b75d2F4d73);
    address trader = address(0x000aaa);
    bytes32 botId =
        bytes32(
            0x0000000000000000000000000000000000000000000000000000000000001212
        );
    uint256 firstBuyAmount = 1;
    address creatorAddr = address(0x1);
    CreatorTech creatorTech;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("goerli"));
        creatorTech = CreatorTech(0x6C131A2cF1502c08E6a9B289C6a510FfcE64Fbc7);
        vm.deal(trader, 1000 ether);
    }

    function testFirstBuy_creatorAddrNotSet() public {
        uint256 balanceBefore = owner.balance;
        bytes32 signedHash = creatorTech._buildFirstBuySeparator(botId, 1);
        (uint8[] memory v, bytes32[] memory r, bytes32[] memory s) = signData(
            signedHash
        );
        vm.prank(trader);
        creatorTech.firstBuy{value: 0.001 ether}(
            botId,
            firstBuyAmount,
            v,
            r,
            s
        );
        uint256 keyPrice = creatorTech.getKeyPrice(0, firstBuyAmount + 1);
        uint256 protocolFees = (keyPrice * creatorTech.protocolFee()) / 1 ether;
        uint256 creatorTreasuryFees = (keyPrice *
            creatorTech.buyTreasuryFee()) / 1 ether;
        uint256 balanceAfter = balanceBefore +
            protocolFees +
            creatorTreasuryFees;
        assertEq(owner.balance, balanceAfter);
        assertEq(creatorTech.getBotBalanceOf(botId, address(trader)), 1);
    }

    function printSignData() public view {
        bytes32 signedHash = creatorTech._buildFirstBuySeparator(botId, 1);
        console2.log("First Buy Signature:");
        signData(signedHash);
        signedHash = creatorTech._buildBuySeparator(botId, 1);
        console2.log("Buy Signature:");
        signData(signedHash);
    }
}
