// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "./utils/TestHelper.sol";

contract CTTradeTest is TestHelper {
    bytes32 botId;
    address creatorAddr;
    uint256 firstBuyAmount;
    uint256 buyAmount;

    function setUp() public override {
        super.setUp();
        vm.deal(DEV, 1000 ether);
        vm.deal(ALICE, 1000 ether);
        // vm.prank(DEV);
        botId = bytes32(uint256(123));
        creatorAddr = address(0x1);
        firstBuyAmount = 3;
        buyAmount = 5;
    }

    function testFirstBuy_creatorAddrNotSet() public {
        uint256 balanceBefore = DEV.balance;
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
        // uint256 creatorFees = (keyPrice * creatorTech.creatorFee()) / 1 ether;
        uint256 balanceAfter = balanceBefore + protocolFees;
        assertEq(DEV.balance, balanceAfter);
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

    function testBuyKey() public {
        bytes32 signedHash = creatorTech._buildFirstBuySeparator(
            botId,
            firstBuyAmount
        );
        (uint8[] memory v, bytes32[] memory r, bytes32[] memory s) = signData(
            signedHash
        );
        creatorTech.firstBuy{value: 1 ether}(botId, firstBuyAmount, v, r, s);
        vm.startPrank(ALICE);
        signedHash = creatorTech._buildBuySeparator(botId, buyAmount);
        (v, r, s) = signData(signedHash);
        creatorTech.buyKey{value: 1 ether}(botId, buyAmount, v, r, s);
        uint256 balanceOfBuyer = creatorTech.getBotBalanceOf(
            botId,
            address(ALICE)
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
        vm.startPrank(ALICE);
        creatorTech.buyKey{value: 1 ether}(botId, buyAmount, v, r, s);
        uint256 balanceOfBuyer = creatorTech.getBotBalanceOf(
            botId,
            address(ALICE)
        );
        assertEq(balanceOfBuyer, buyAmount);
        creatorTech.sellKey(botId, buyAmount);
        balanceOfBuyer = creatorTech.getBotBalanceOf(botId, address(ALICE));
        assertEq(balanceOfBuyer, 0);
        vm.stopPrank();
    }
}
