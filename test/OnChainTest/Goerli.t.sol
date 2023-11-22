// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "../utils/TestHelper.sol";

contract CreatorTechTest is TestHelper {
    address owner;
    bytes32 botId;
    uint256 firstBuyAmount = 1;

    function setUp() public override {
        super.setUp();
        signersAmount = 1;
        signerPrivateKeys[
            0
        ] = 0x99b07ead3e50245003d7c1c6e5ac5fcc5ac15fd2ddfda22a6a4f423b90e61143;
        signers[0] = vm.addr(signerPrivateKeys[0]);
        vm.createSelectFork(vm.rpcUrl("goerli"));
        creatorTech = CreatorTech(0x2361a33d89D923A6dd63D6f582beF7A8B45DFc0B);
        owner = address(0xE6f27ad7e6b7297F7324a0a7d10Dd9b75d2F4d73);
        botId = bytes32(
            0x0000000000000000000000000000000000000000000000000000000000000001
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
        uint256 balanceAfter = balanceBefore + protocolFees;
        assertEq(owner.balance, balanceAfter);
        assertEq(creatorTech.getBotBalanceOf(botId, address(ALICE)), 1);
    }

    function printFirstBuySignature() public view {
        bytes32 signedHash = creatorTech._buildFirstBuySeparator(botId, 1);
        console2.log("First Buy Signature:");
        signData(signedHash);
    }

    function printBuySignature() public view {
        bytes32 signedHash = creatorTech._buildBuySeparator(botId, 1);
        console2.log("Buy Signature:");
        signData(signedHash);
    }
}
