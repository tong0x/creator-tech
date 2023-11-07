// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract CreatorTech is Ownable, ReentrancyGuard {
    address public protocolFeeRecipient;
    address public creatorTreasury;

    uint256 public protocolFee;
    uint256 public creatorTreasuryFee;
    uint256 public creatorFee;

    constructor() Ownable(msg.sender) ReentrancyGuard() {}

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
