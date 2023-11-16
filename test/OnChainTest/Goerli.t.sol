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
            0x0000000000000000000000000000000000000000000000000000000000007777
        );
    uint256 firstBuyAmount = 1;
    address creatorAddr = address(0x1);
    CreatorTech creatorTech;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("goerli"));
        creatorTech = CreatorTech(0xae948882c84204f7d8F370F4940CFc27ac8da880);
        // signerPrivateKeys[0] = 0x1;
        // signerPrivateKeys[1] = 0x2;
        // signerPrivateKeys[2] = 0x3;
        // signers[0] = vm.addr(signerPrivateKeys[0]);
        // signers[1] = vm.addr(signerPrivateKeys[1]);
        // signers[2] = vm.addr(signerPrivateKeys[2]);
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
            creatorTech.creatorTreasuryFee()) / 1 ether;
        // uint256 creatorFees = (keyPrice * creatorTech.creatorFee()) / 1 ether;
        uint256 balanceAfter = balanceBefore +
            protocolFees +
            creatorTreasuryFees;
        assertEq(owner.balance, balanceAfter);
        assertEq(creatorTech.getBotBalanceOf(botId, address(trader)), 1);
    }

    function testBindCreatorAndClaim_setCreatorAddr() public {}

    function testBindCreatorAndClaim_insufficientPayment() public {}

    function testBindCreatorAndClaim_unableToSendFunds() public {}

    function testBuyKey() public {}

    function testSellKey() public {}
}
