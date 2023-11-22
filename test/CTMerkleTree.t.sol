// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "./utils/TestHelper.sol";

contract CTMerkleTreeTest is TestHelper {
    bytes32 botId;
    address creatorAddr;
    uint256 firstBuyAmount;

    function setUp() public override {
        super.setUp();
        botId = bytes32(uint256(123));
        creatorAddr = address(0x1);
        firstBuyAmount = 1000;
        bytes32 signedHash = creatorTech._buildFirstBuySeparator(
            botId,
            firstBuyAmount
        );
        (uint8[] memory v, bytes32[] memory r, bytes32[] memory s) = signData(
            signedHash
        );
        creatorTech.firstBuy{value: 4000 ether}(botId, firstBuyAmount, v, r, s);
    }

    function testCreateMerkleRootAndClaimReward() public {
        // Example leaves (hash of actual data)
        bytes32[] memory leaves = new bytes32[](4);
        leaves[0] = keccak256(abi.encodePacked(ALICE, uint256(10)));
        leaves[1] = keccak256(abi.encodePacked(BOB, uint256(20)));
        leaves[2] = keccak256(abi.encodePacked(CINDY, uint256(30)));
        leaves[3] = keccak256(abi.encodePacked(DAISY, uint256(40)));

        // Generate the Merkle tree and root
        bytes32[] memory leaves2 = new bytes32[](2);
        leaves2[0] = _hashPair(leaves[0], leaves[1]);
        leaves2[1] = _hashPair(leaves[2], leaves[3]);
        bytes32 merkleRoot = _hashPair(leaves2[0], leaves2[1]);

        // Generate the Merkle proof for BOB
        bytes32[] memory proof = new bytes32[](2);
        proof[0] = leaves[0];
        proof[1] = leaves2[1];

        // Update Merkle root on contract
        vm.prank(DEV);
        creatorTech.setMerkleRoot(0, merkleRoot);

        // Verify the Merkle proof
        creatorTech.claimReward(0, BOB, 20, proof);
    }

    function testCreateMerkleRootAndClaimReward_diffOrder() public {
        // Example leaves (hash of actual data)
        bytes32[] memory leaves = new bytes32[](4);
        leaves[0] = keccak256(abi.encodePacked(ALICE, uint256(10)));
        leaves[1] = keccak256(abi.encodePacked(BOB, uint256(20)));
        leaves[2] = keccak256(abi.encodePacked(CINDY, uint256(30)));
        leaves[3] = keccak256(abi.encodePacked(DAISY, uint256(40)));

        // Generate the Merkle tree and root
        bytes32[] memory leaves2 = new bytes32[](2);
        leaves2[0] = _hashPair(leaves[1], leaves[0]);
        leaves2[1] = _hashPair(leaves[2], leaves[3]);
        bytes32 merkleRoot = _hashPair(leaves2[1], leaves2[0]);

        // Generate the Merkle proof for BOB
        bytes32[] memory proof = new bytes32[](2);
        proof[0] = leaves[0];
        proof[1] = leaves2[1];

        // Update Merkle root on contract
        vm.prank(DEV);
        creatorTech.setMerkleRoot(0, merkleRoot);

        // Verify the Merkle proof
        creatorTech.claimReward(0, BOB, 20, proof);
    }
}
