// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "forge-std/Test.sol";
import {CreatorTech} from "../src/CreatorTech.sol";
import "./utils/TestHelper.sol";

contract CTBindCreatorTest is TestHelper {
    bytes32 botId;

    function setUp() public override {
        super.setUp();
        botId = bytes32(uint256(123));
    }

    function testBindCreatorAndClaim_withoutUnclaimedFees() public {
        bytes32 signedHash = creatorTech._buildBindSeparator(botId, ALICE);
        (uint8[] memory v, bytes32[] memory r, bytes32[] memory s) = signData(
            signedHash
        );
        creatorTech.bindCreatorAndClaim(botId, ALICE, v, r, s);
        address ctCreatorAddr = creatorTech.getBotCreatorAddr(botId);
        assertEq(ctCreatorAddr, ALICE);
        assertEq(ALICE.balance, 0);
    }

    function testBindCreatorAndClaim_haveUnclaimedFees() public {
        uint256 firstBuyAmount = 3;
        bytes32 signedHash = creatorTech._buildFirstBuySeparator(
            botId,
            firstBuyAmount
        );
        (uint8[] memory v, bytes32[] memory r, bytes32[] memory s) = signData(
            signedHash
        );
        creatorTech.firstBuy{value: 0.1 ether}(botId, firstBuyAmount, v, r, s);

        uint256 fee = creatorTech.getBotUnclaimedFees(botId);

        signedHash = creatorTech._buildBindSeparator(botId, ALICE);
        (v, r, s) = signData(signedHash);
        creatorTech.bindCreatorAndClaim(botId, ALICE, v, r, s);
        assertGe(ALICE.balance, 0);
        assertEq(ALICE.balance, fee);
    }
}
