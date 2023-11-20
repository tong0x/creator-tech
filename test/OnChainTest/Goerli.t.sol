// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "../utils/TestHelper.sol";

contract CreatorTechTest is TestHelper {
    address owner;
    bytes32 botId;
    uint256 firstBuyAmount = 1;

    function setUp() public override {
        super.setUp();
        vm.createSelectFork(vm.rpcUrl("goerli"));
        creatorTech = CreatorTech(0x6C131A2cF1502c08E6a9B289C6a510FfcE64Fbc7);
        owner = address(0xE6f27ad7e6b7297F7324a0a7d10Dd9b75d2F4d73);
        botId = bytes32(
            0x0000000000000000000000000000000000000000000000000000000000001212
        );
        vm.deal(ALICE, 1000 ether);
    }

    function testFirstBuy_creatorAddrNotSet() public {
        uint256 balanceBefore = owner.balance;
        bytes32 signedHash = creatorTech._buildFirstBuySeparator(botId, 1);
        (uint8[] memory v, bytes32[] memory r, bytes32[] memory s) = signData(
            signedHash
        );
        vm.prank(ALICE);
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
        assertEq(creatorTech.getBotBalanceOf(botId, address(ALICE)), 1);
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
