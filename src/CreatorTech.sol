// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

contract CreatorTech is Ownable, ReentrancyGuard, EIP712 {
    // TODO: Add fields related to rewards
    bytes32 public constant BIND_TYPEHASH =
        keccak256(abi.encodePacked("Bind(bytes32 botId,address creatorAddr)"));
    bytes32 public constant FIRSTBUY_TYPEHASH =
        keccak256(abi.encodePacked("FirstBuy(bytes32 botId,uint256 amount)"));
    bytes32 public constant BUY_TYPEHASH =
        keccak256(abi.encodePacked("Buy(bytes32 botId,uint256 amount)"));

    struct Bot {
        bool firstBuy; // if first buy has occurred
        address creatorAddr; // Creator Address, can be 0 initially
        mapping(address => uint256) balanceOf; // trader => balance of keys
        uint256 totalSupply; // of keys
        uint256 unclaimedFees; // fees accumulated before a creator is assigned
    }

    struct TradeEvent {
        uint256 eventIndex;
        uint256 timestamp;
        address trader;
        bytes32 bot;
        bool isBuy;
        bool isFirstBuy;
        uint256 keyAmount;
        uint256 ethAmount;
        uint256 traderBalance;
        uint256 keySupply;
    }

    address public protocolFeeRecipient;
    address public creatorTreasury;

    uint256 public protocolFee;
    uint256 public buyTreasuryFee;
    uint256 public buyCreatorFee;
    uint256 public sellTreasuryFee;
    uint256 public sellCreatorFee;
    uint256 public tradeIndex;
    address[] public signers;
    mapping(bytes32 => Bot) public bots; // Bot ID => Bot Info
    mapping(address => bool) public isSigner;
    mapping(address => uint256) public signerIdx;

    event SignerAdded(address indexed signer);
    event SignerRemoved(address indexed signer);
    event CreatorBound(
        bytes32 indexed creatorId,
        address creatorAddr,
        uint256 timestamp
    );
    event RewardClaimed(
        address indexed creatorAddr,
        uint256 timestamp,
        uint256 claimIdx,
        uint256 amount
    );
    event Trade(TradeEvent tradeEvent);

    constructor(
        address[] memory _signers
    ) Ownable(msg.sender) ReentrancyGuard() EIP712("CreatorTech", "1") {
        for (uint256 i = 0; i < _signers.length; i++) {
            addSigner(_signers[i]);
        }

        protocolFeeRecipient = msg.sender;
        creatorTreasury = msg.sender;

        protocolFee = 0.03 ether; // 3%
        buyTreasuryFee = 0.03 ether; // 3%
        buyCreatorFee = 0.06 ether; // 6%
        sellTreasuryFee = 0.06 ether; // 6%
        sellCreatorFee = 0.03 ether; // 3%
    }

    struct TradeParameters {
        uint256 value;
        uint256 price;
        uint256 protocolFee;
        uint256 creatorFee;
        uint256 treasuryFee;
        bool success;
    }

    function firstBuy(
        bytes32 _botId,
        uint256 _amount,
        uint8[] calldata _v,
        bytes32[] calldata _r,
        bytes32[] calldata _s
    ) external payable nonReentrant {
        recover(_buildFirstBuySeparator(_botId, _amount), _v, _r, _s);
        Bot storage bot = bots[_botId];
        require(bot.firstBuy == false, "First buy already occurred");
        require(bot.totalSupply == 0, "Bot already initialized");
        bot.firstBuy = true;
        TradeParameters memory params;
        params.price = getKeyPrice(bot.totalSupply, _amount + 1);
        params.protocolFee = (params.price * protocolFee) / 1 ether;
        params.creatorFee = (params.price * buyCreatorFee) / 1 ether;
        params.treasuryFee = (params.price * buyTreasuryFee) / 1 ether;
        params.value =
            params.price +
            params.protocolFee +
            params.creatorFee +
            params.treasuryFee;
        require(msg.value >= params.value, "Insufficient payment");
        bot.balanceOf[msg.sender] += _amount;
        bot.totalSupply += _amount + 1;
        if (bot.creatorAddr == address(0)) {
            bot.unclaimedFees += params.creatorFee;
            bot.balanceOf[address(this)] += 1;
        } else {
            (params.success, ) = bot.creatorAddr.call{value: params.creatorFee}(
                new bytes(0)
            );
            require(params.success, "Unable to send funds");
            bot.balanceOf[bot.creatorAddr] += 1;
        }
        (params.success, ) = protocolFeeRecipient.call{
            value: params.protocolFee
        }(new bytes(0));
        require(params.success, "Unable to send funds");
        (params.success, ) = creatorTreasury.call{value: params.treasuryFee}(
            new bytes(0)
        );
        require(params.success, "Unable to send funds");

        emit Trade(
            TradeEvent({
                eventIndex: tradeIndex++,
                timestamp: block.timestamp,
                trader: msg.sender,
                bot: _botId,
                isBuy: true,
                isFirstBuy: true,
                keyAmount: _amount,
                ethAmount: params.price,
                traderBalance: bot.balanceOf[msg.sender],
                keySupply: bot.totalSupply
            })
        );
    }

    function buyKey(
        bytes32 _botId,
        uint256 _amount,
        uint8[] calldata _v,
        bytes32[] calldata _r,
        bytes32[] calldata _s
    ) external payable nonReentrant {
        recover(_buildBuySeparator(_botId, _amount), _v, _r, _s);
        TradeParameters memory params;
        Bot storage bot = bots[_botId];
        require(bot.firstBuy == true, "First buy has not occurred");
        params.price = getKeyPrice(bot.totalSupply, _amount);
        params.protocolFee = (params.price * protocolFee) / 1 ether;
        params.creatorFee = (params.price * buyCreatorFee) / 1 ether;
        params.treasuryFee = (params.price * buyTreasuryFee) / 1 ether;
        params.value =
            params.price +
            params.protocolFee +
            params.creatorFee +
            params.treasuryFee;
        require(msg.value >= params.value, "Insufficient payment");
        bot.balanceOf[msg.sender] += _amount;
        bot.totalSupply += _amount;

        if (bot.creatorAddr == address(0)) {
            bot.unclaimedFees += params.creatorFee;
        } else {
            (params.success, ) = bot.creatorAddr.call{value: params.creatorFee}(
                new bytes(0)
            );
            require(params.success, "Unable to send funds");
        }
        (params.success, ) = protocolFeeRecipient.call{
            value: params.protocolFee
        }(new bytes(0));
        require(params.success, "Unable to send funds");
        (params.success, ) = creatorTreasury.call{value: params.treasuryFee}(
            new bytes(0)
        );
        require(params.success, "Unable to send funds");

        emit Trade(
            TradeEvent({
                eventIndex: tradeIndex++,
                timestamp: block.timestamp,
                trader: msg.sender,
                bot: _botId,
                isBuy: true,
                isFirstBuy: false,
                keyAmount: _amount,
                ethAmount: params.price,
                traderBalance: bot.balanceOf[msg.sender],
                keySupply: bot.totalSupply
            })
        );
    }

    function sellKey(bytes32 _botId, uint256 _amount) external nonReentrant {
        TradeParameters memory params;
        Bot storage bot = bots[_botId];
        require(bot.firstBuy == true, "First buy has not occurred");
        require(bot.balanceOf[msg.sender] >= _amount, "Insufficient passes");
        params.price = getKeyPrice(bot.totalSupply - _amount, _amount);
        params.protocolFee = (params.price * protocolFee) / 1 ether;
        params.creatorFee = (params.price * sellCreatorFee) / 1 ether;
        params.treasuryFee = (params.price * sellTreasuryFee) / 1 ether;
        params.value =
            params.price -
            params.protocolFee -
            params.creatorFee -
            params.treasuryFee;
        bot.balanceOf[msg.sender] -= _amount;
        bot.totalSupply -= _amount;
        if (bot.creatorAddr == address(0)) {
            bot.unclaimedFees += params.creatorFee;
        } else {
            (params.success, ) = bot.creatorAddr.call{value: params.creatorFee}(
                new bytes(0)
            );
            require(params.success, "Unable to send funds");
        }
        (params.success, ) = msg.sender.call{value: params.value}(new bytes(0));
        require(params.success, "Unable to send funds");
        (params.success, ) = protocolFeeRecipient.call{
            value: params.protocolFee
        }(new bytes(0));
        require(params.success, "Unable to send funds");
        (params.success, ) = creatorTreasury.call{value: params.treasuryFee}(
            new bytes(0)
        );
        require(params.success, "Unable to send funds");

        emit Trade(
            TradeEvent({
                eventIndex: tradeIndex++,
                timestamp: block.timestamp,
                trader: msg.sender,
                bot: _botId,
                isBuy: false,
                isFirstBuy: false,
                keyAmount: _amount,
                ethAmount: params.price,
                traderBalance: bot.balanceOf[msg.sender],
                keySupply: bot.totalSupply
            })
        );
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
        bytes32 _hash,
        uint8[] calldata _v,
        bytes32[] calldata _r,
        bytes32[] calldata _s
    ) public view returns (bool) {
        uint256 length = signers.length;
        require(length > 0, "No signers");
        require(
            length == _v.length && length == _r.length && length == _s.length,
            "Invalid signature length"
        );
        address[] memory seen = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            address signer = ecrecover(_hash, _v[i], _r[i], _s[i]);
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

    function setBuyTreasuryFee(uint256 _buyTreasuryFee) external onlyOwner {
        buyTreasuryFee = _buyTreasuryFee;
    }

    function setBuyCreatorFee(uint256 _buyCreatorFee) external onlyOwner {
        buyCreatorFee = _buyCreatorFee;
    }

    function setSellTreasuryFee(uint256 _sellTreasuryFee) external onlyOwner {
        sellTreasuryFee = _sellTreasuryFee;
    }

    function setSellCreatorFee(uint256 _sellCreatorFee) external onlyOwner {
        sellCreatorFee = _sellCreatorFee;
    }

    function _sumOfSquares(uint256 _n) internal pure returns (uint256) {
        return (_n == 0) ? 0 : (_n * (_n + 1) * (2 * _n + 1)) / 6;
    }

    function getBotCreatorAddr(bytes32 _botId) external view returns (address) {
        return bots[_botId].creatorAddr;
    }

    function getBotBalanceOf(
        bytes32 _botId,
        address _account
    ) external view returns (uint256) {
        return bots[_botId].balanceOf[_account];
    }

    function getKeyPrice(
        uint256 _currentSupply,
        uint256 _keyAmount
    ) public pure returns (uint256) {
        uint256 preTradeSum = _sumOfSquares(_currentSupply);
        uint256 postTradeSum = _sumOfSquares(_currentSupply + _keyAmount);
        uint256 diffSum = postTradeSum - preTradeSum;
        return (diffSum * 1 ether) / 100000;
    }

    function _buildBindSeparator(
        bytes32 _botId,
        address _creatorAddr
    ) public view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(abi.encode(BIND_TYPEHASH, _botId, _creatorAddr))
            );
    }

    function _buildFirstBuySeparator(
        bytes32 _botId,
        uint256 _amount
    ) public view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(abi.encode(FIRSTBUY_TYPEHASH, _botId, _amount))
            );
    }

    function _buildBuySeparator(
        bytes32 _botId,
        uint256 _amount
    ) public view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(abi.encode(BUY_TYPEHASH, _botId, _amount))
            );
    }

    function bindCreatorAndClaim(
        bytes32 _botId,
        address _creatorAddr,
        uint8[] calldata _v,
        bytes32[] calldata _r,
        bytes32[] calldata _s
    ) external nonReentrant {
        require(_creatorAddr != address(0), "Invalid creator address");
        recover(_buildBindSeparator(_botId, _creatorAddr), _v, _r, _s);
        Bot storage bot = bots[_botId];
        require(bot.creatorAddr == address(0), "Creator already bound");
        bot.creatorAddr = _creatorAddr;
        emit CreatorBound(_botId, _creatorAddr, block.timestamp);
        uint256 amount = bot.unclaimedFees;
        if (amount > 0) {
            bot.unclaimedFees = 0;
            (bool success, ) = _creatorAddr.call{value: amount}("");
            require(success, "Transfer failed");
            emit RewardClaimed(_creatorAddr, block.timestamp, 0, amount);
        }
        if (bot.firstBuy) {
            bot.balanceOf[address(this)] -= 1;
            bot.balanceOf[bot.creatorAddr] += 1;
        }
    }
}
