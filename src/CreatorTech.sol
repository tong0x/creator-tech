// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract CreatorTech is Ownable, ReentrancyGuard {
    // TODO: Add fields related to rewards
    struct Bot {
        uint64 owner; // Twitter UUID
        mapping(address => uint256) balanceOf; // trader => balance of keys
        uint256 totalSupply; // of keys
        uint256 unclaimedCreatorFees;
    }

    mapping(uint64 => address) public creatorAddrs; // Twitter UUID to ETH address
    mapping(uint64 => mapping(uint256 => Bot)) public bots; // Twitter UUID => bot idx => bot

    address public protocolFeeRecipient;
    address public creatorTreasury;

    uint256 public protocolFee;
    uint256 public creatorTreasuryFee;
    uint256 public creatorFee;

    constructor() Ownable(msg.sender) ReentrancyGuard() {
        protocolFeeRecipient = msg.sender;
        creatorTreasury = msg.sender;

        protocolFee = 0.02 ether; // 2%
        creatorTreasuryFee = 0.05 ether; // 5%
        creatorFee = 0.03 ether; // 3%
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
}
