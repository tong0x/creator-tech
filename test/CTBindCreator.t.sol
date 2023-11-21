// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "./utils/TestHelper.sol";

contract CTBindCreatorTest is TestHelper {
    bytes32 botId;
    address creatorAddr;

    function setUp() public override {
        super.setUp();
        botId = bytes32(uint256(123));
        creatorAddr = address(0x1);
    }

    function testBindCreatorAndClaim_withoutUnclaimedFees() public {
        (uint8[] memory v, bytes32[] memory r, bytes32[] memory s) = signData(
            botId,
            creatorAddr
        );
        bytes32 signedHash = creatorTech._buildBindSeparator(
            botId,
            creatorAddr
        );
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

    function testBindCreatorAndClaim_haveUnclaimedFees() public {}

    function testBindCreatorAndClaim_2() public {}

    function testBindCreatorAndClaim_3() public {}

    // Utility functions

    function signData(
        bytes32 _botId,
        address _creatorAddr
    ) public view returns (uint8[] memory, bytes32[] memory, bytes32[] memory) {
        bytes32 signedHash = creatorTech._buildBindSeparator(
            _botId,
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
