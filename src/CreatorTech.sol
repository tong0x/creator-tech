// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

contract CreatorTech is Ownable, ReentrancyGuard, EIP712 {
    // TODO: Add fields related to rewards
    struct Bot {
        uint64 owner; // Twitter UUID
        mapping(address => uint256) balanceOf; // trader => balance of keys
        uint256 totalSupply; // of keys
        uint256 unclaimedCreatorFees;
    }

    mapping(uint64 => address) public creatorAddrs; // Twitter UUID to ETH address
    mapping(uint64 => mapping(uint256 => Bot)) public bots; // Twitter UUID => bot idx => bot

    address[] public signers;
    mapping(address => bool) public isSigner;
    mapping(address => uint256) public signerIdx;

    address public protocolFeeRecipient;
    address public creatorTreasury;

    uint256 public protocolFee;
    uint256 public creatorTreasuryFee;
    uint256 public creatorFee;

    event SignerAdded(address indexed signer);
    event SignerRemoved(address indexed signer);

    constructor(
        address[] memory _signers
    ) Ownable(msg.sender) ReentrancyGuard() EIP712("CreatorTech", "1") {
        for (uint256 i = 0; i < _signers.length; i++) {
            addSigner(_signers[i]);
        }

        protocolFeeRecipient = msg.sender;
        creatorTreasury = msg.sender;

        protocolFee = 0.02 ether; // 2%
        creatorTreasuryFee = 0.05 ether; // 5%
        creatorFee = 0.03 ether; // 3%
    }

    function addSigner(address _signer) public onlyOwner {
        require(!isSigner[_signer], "Signer already exists");
        isSigner[_signer] = true;
        signerIdx[_signer] = signers.length;
        signers.push(_signer);
        emit SignerAdded(_signer);
    }

    function removeSigner(address _signer) external onlyOwner {
        require(isSigner[_signer], "Signer does not exist");
        uint256 idx = signerIdx[_signer];
        uint256 lastIdx = signers.length - 1;

        if (idx != lastIdx) {
            address lastSigner = signers[lastIdx];
            signers[idx] = lastSigner;
            signerIdx[lastSigner] = idx;
        }

        delete isSigner[_signer];
        delete signerIdx[_signer];
        signers.pop();

        emit SignerRemoved(_signer);
    }

    function recover(
        bytes32 hash,
        uint8[] calldata v,
        bytes32[] calldata r,
        bytes32[] calldata s
    ) public view returns (bool) {
        uint256 length = signers.length;
        require(length > 0, "No signers");
        require(
            length == v.length && length == r.length && length == s.length,
            "Invalid signature length"
        );
        address[] memory seen = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            address signer = ecrecover(hash, v[i], r[i], s[i]);
            require(isSigner[signer], "Invalid signer");
            for (uint256 j = 0; j < i; j++) {
                require(signer != seen[j], "Duplicate signer");
            }
            seen[i] = signer;
        }
        return true;
    }

    function setProtocolFeeRecipient(
        address _protocolFeeRecipient
    ) external onlyOwner {
        protocolFeeRecipient = _protocolFeeRecipient;
    }

    function setCreatorTreasury(address _creatorTreasury) external onlyOwner {
        creatorTreasury = _creatorTreasury;
    }

    function setProtocolFee(uint256 _protocolFee) external onlyOwner {
        protocolFee = _protocolFee;
    }

    function setCreatorTreasuryFee(
        uint256 _creatorTreasuryFee
    ) external onlyOwner {
        creatorTreasuryFee = _creatorTreasuryFee;
    }

    function setCreatorFee(uint256 _creatorFee) external onlyOwner {
        creatorFee = _creatorFee;
    }

    function sumOfSquares(uint256 n) internal pure returns (uint256) {
        return (n == 0) ? 0 : (n * (n + 1) * (2 * n + 1)) / 6;
    }

    function getKeyPrice(
        uint256 currentSupply,
        uint256 keyAmount
    ) public pure returns (uint256) {
        uint256 preTradeSum = sumOfSquares(currentSupply);
        uint256 postTradeSum = sumOfSquares(currentSupply + keyAmount);
        uint256 diffSum = postTradeSum - preTradeSum;
        return (diffSum * 1 ether) / 43370;
    }
}
