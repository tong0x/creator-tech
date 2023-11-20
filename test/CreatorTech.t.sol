// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "forge-std/Test.sol";
import {CreatorTech} from "../src/CreatorTech.sol";

contract CreatorTechTest is Test {
    function setUp() public {}

    function testAddSigners_MultipleSignersNoDuplicates() public {
        address[] memory signers = new address[](3);
        signers[0] = address(0x1);
        signers[1] = address(0x2);
        signers[2] = address(0x3);

        CreatorTech creatorTech = new CreatorTech(signers);
        assertEq(creatorTech.signers(0), address(0x1));
        assertEq(creatorTech.signers(1), address(0x2));
        assertEq(creatorTech.signers(2), address(0x3));
    }

    function testAddSigners_MultipleSignersWithDuplicates() public {
        address[] memory signers = new address[](3);
        signers[0] = address(0x1);
        signers[1] = address(0x2);
        signers[2] = address(0x1);

        vm.expectRevert("Signer already exists");
        new CreatorTech(signers);
    }

    function testRemoveSigners_ExpectedBehavior() public {
        address[] memory signers = new address[](3);
        signers[0] = address(0x1);
        signers[1] = address(0x2);
        signers[2] = address(0x3);

        CreatorTech creatorTech = new CreatorTech(signers);
        creatorTech.removeSigner(address(0x2));
        assertEq(creatorTech.signers(0), address(0x1));
        assertEq(creatorTech.signers(1), address(0x3));
    }

    function testRemoveSigners_RemoveNonexistent() public {
        address[] memory signers = new address[](3);
        signers[0] = address(0x1);
        signers[1] = address(0x2);
        signers[2] = address(0x3);

        CreatorTech creatorTech = new CreatorTech(signers);
        vm.expectRevert("Signer does not exist");
        creatorTech.removeSigner(address(0x4));
    }

    function testRecover_SingleSigner() public {
        uint256[] memory signerPrivateKeys = new uint256[](3);
        signerPrivateKeys[0] = 0x1;
        signerPrivateKeys[1] = 0x2;
        signerPrivateKeys[2] = 0x3;

        address[] memory signers = new address[](1);
        signers[0] = vm.addr(signerPrivateKeys[0]);

        CreatorTech creatorTech = new CreatorTech(signers);
        bytes32 hash = keccak256(abi.encodePacked("hello world"));
        uint8[] memory v = new uint8[](1);
        bytes32[] memory r = new bytes32[](1);
        bytes32[] memory s = new bytes32[](1);
        (v[0], r[0], s[0]) = vm.sign(signerPrivateKeys[0], hash);
        assertTrue(creatorTech.recover(hash, v, r, s));
    }

    function testRecover_MultipleSigners() public {
        uint256[] memory signerPrivateKeys = new uint256[](3);
        signerPrivateKeys[0] = 0x1;
        signerPrivateKeys[1] = 0x2;
        signerPrivateKeys[2] = 0x3;

        address[] memory signers = new address[](3);
        signers[0] = vm.addr(signerPrivateKeys[0]);
        signers[1] = vm.addr(signerPrivateKeys[1]);
        signers[2] = vm.addr(signerPrivateKeys[2]);

        CreatorTech creatorTech = new CreatorTech(signers);
        bytes32 hash = keccak256(abi.encodePacked("hello world"));
        uint8[] memory v = new uint8[](3);
        bytes32[] memory r = new bytes32[](3);
        bytes32[] memory s = new bytes32[](3);
        (v[0], r[0], s[0]) = vm.sign(signerPrivateKeys[0], hash);
        (v[1], r[1], s[1]) = vm.sign(signerPrivateKeys[1], hash);
        (v[2], r[2], s[2]) = vm.sign(signerPrivateKeys[2], hash);
        assertTrue(creatorTech.recover(hash, v, r, s));
    }

    function testRecover_MultipleSignersWithInvalid() public {
        uint256[] memory signerPrivateKeys = new uint256[](3);
        signerPrivateKeys[0] = 0x1;
        signerPrivateKeys[1] = 0x2;
        signerPrivateKeys[2] = 0x3;

        address[] memory signers = new address[](3);
        signers[0] = vm.addr(signerPrivateKeys[0]);
        signers[1] = vm.addr(signerPrivateKeys[1]);
        signers[2] = vm.addr(signerPrivateKeys[2]);

        CreatorTech creatorTech = new CreatorTech(signers);
        bytes32 hash = keccak256(abi.encodePacked("hello world"));
        uint8[] memory v = new uint8[](3);
        bytes32[] memory r = new bytes32[](3);
        bytes32[] memory s = new bytes32[](3);
        (v[0], r[0], s[0]) = vm.sign(signerPrivateKeys[0], hash);
        (v[1], r[1], s[1]) = vm.sign(signerPrivateKeys[1], hash);
        (v[2], r[2], s[2]) = vm.sign(signerPrivateKeys[2], hash);
        v[2] = 0x0;
        vm.expectRevert("Invalid signer");
        creatorTech.recover(hash, v, r, s);
    }

    function testRecover_MultipleSignersWithDuplicate() public {
        uint256[] memory signerPrivateKeys = new uint256[](3);
        signerPrivateKeys[0] = 0x1;
        signerPrivateKeys[1] = 0x2;
        signerPrivateKeys[2] = 0x3;

        address[] memory signers = new address[](3);
        signers[0] = vm.addr(signerPrivateKeys[0]);
        signers[1] = vm.addr(signerPrivateKeys[1]);
        signers[2] = vm.addr(signerPrivateKeys[2]);

        CreatorTech creatorTech = new CreatorTech(signers);
        bytes32 hash = keccak256(abi.encodePacked("hello world"));
        uint8[] memory v = new uint8[](3);
        bytes32[] memory r = new bytes32[](3);
        bytes32[] memory s = new bytes32[](3);
        (v[0], r[0], s[0]) = vm.sign(signerPrivateKeys[0], hash);
        (v[1], r[1], s[1]) = vm.sign(signerPrivateKeys[1], hash);
        (v[2], r[2], s[2]) = vm.sign(signerPrivateKeys[1], hash);
        vm.expectRevert("Duplicate signer");
        creatorTech.recover(hash, v, r, s);
    }

    // Copied from Tomo
    function getPriceTomo(
        uint256 supply,
        uint256 amount
    ) public pure returns (uint256) {
        uint256 sum1 = (supply * (supply + 1) * (2 * supply + 1)) / 6;
        uint256 sum2 = ((supply + amount) *
            (supply + 1 + amount) *
            (2 * (supply + amount) + 1)) / 6;
        uint256 summation = sum2 - sum1;
        return (summation * 1 ether) / 100000;
    }

    function testGetKeyPrice_Equivalence(
        uint256 currentSupply,
        uint256 keyAmount
    ) public {
        if (keyAmount == 0) {
            return;
        }
        // Let's use 1B keys as cut off
        if (currentSupply > 1_000_000_000 || keyAmount > 1_000_000_000) {
            return;
        }

        address[] memory signers = new address[](1);
        signers[0] = address(0x1);
        CreatorTech creatorTech = new CreatorTech(signers);
        assertEq(
            creatorTech.getKeyPrice(currentSupply, keyAmount),
            getPriceTomo(currentSupply, keyAmount)
        );
    }
}
