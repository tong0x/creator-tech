// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

contract CreatorTech is Ownable, ReentrancyGuard, EIP712 {
    // TODO: Add fields related to rewards
    struct Bot {
        bool firstBuy; // if first buy has occurred
        address creatorAddr; // Creator Address, can be 0 initially
        mapping(address => uint256) balanceOf; // trader => balance of keys
        uint256 totalSupply; // of keys
        uint256 unclaimedFees; // fees accumulated before a creator is assigned
    }

    bytes32 public constant BIND_TYPEHASH =
        keccak256(
            abi.encodePacked("Bind(uint64 creatorId,address creatorAddr)")
        );

    mapping(uint64 => Bot) bots; // Bot ID => Bot Info

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
    event CreatorBound(
        uint64 indexed creatorId,
        address creatorAddr,
        uint256 timestamp
    );
    event RewardClaimed(
        address indexed creatorAddr,
        uint256 timestamp,
        uint256 claimIdx,
        uint256 amount
    );

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

    function _sumOfSquares(uint256 _n) internal pure returns (uint256) {
        return (_n == 0) ? 0 : (_n * (_n + 1) * (2 * _n + 1)) / 6;
    }

    function getBotCreatorAddr(
        uint64 _botId
    ) external view returns (address creatorAddr) {
        creatorAddr = bots[_botId].creatorAddr;
    }

    function getKeyPrice(
        uint256 _currentSupply,
        uint256 _keyAmount
    ) public pure returns (uint256) {
        uint256 preTradeSum = _sumOfSquares(_currentSupply);
        uint256 postTradeSum = _sumOfSquares(_currentSupply + _keyAmount);
        uint256 diffSum = postTradeSum - preTradeSum;
        return (diffSum * 1 ether) / 43370;
    }

    function _buildBindSeparator(
        uint64 _botId,
        address _creatorAddr
    ) public view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(abi.encode(BIND_TYPEHASH, _botId, _creatorAddr))
            );
    }

    function bindCreatorAndClaim(
        uint64 _botId,
        address _creatorAddr,
        uint8[] calldata _v,
        bytes32[] calldata _r,
        bytes32[] calldata _s
    ) external nonReentrant {
        require(_creatorAddr != address(0), "Invalid creator address");
        recover(_buildBindSeparator(_botId, _creatorAddr), _v, _r, _s);
        Bot storage bot = bots[_botId];
        if (bot.creatorAddr == address(0)) {
            bot.creatorAddr = _creatorAddr;
            emit CreatorBound(_botId, _creatorAddr, block.timestamp);
        }
        uint256 amount = bot.unclaimedFees;
        if (amount > 0) {
            bot.unclaimedFees = 0;
            (bool success, ) = _creatorAddr.call{value: amount}("");
            require(success, "Transfer failed");
            emit RewardClaimed(_creatorAddr, block.timestamp, 0, amount);
        }
    }
}
