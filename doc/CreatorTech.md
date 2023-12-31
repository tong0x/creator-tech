# CreatorTech Smart Contract Integration Guide

## Overview

This guide is intended for front-end and back-end developers who need to interact with the `CreatorTech` smart contract. It provides the necessary information to integrate and use the contract's functions within your application.

## Smart Contract Config

v0.1.0

- **Contract Address on Mainnet (Ethereum):**
- **Contract Address on Testnet (Goerli):** [0xae948882c84204f7d8F370F4940CFc27ac8da880](https://goerli.etherscan.io/address/0xae948882c84204f7d8f370f4940cfc27ac8da880)
- **ABI:** You can obtain the ABI from [here](../out/CreatorTech.sol/CreatorTech.json).

v0.1.1

- **Contract Address on Mainnet (Ethereum):**
- **Contract Address on Testnet (Goerli):** [0x6C131A2cF1502c08E6a9B289C6a510FfcE64Fbc7](https://goerli.etherscan.io/address/0x6C131A2cF1502c08E6a9B289C6a510FfcE64Fbc7)
- **ABI:** You can obtain the ABI from [here](../out/CreatorTech.sol/CreatorTech.json).

## Read-Only Functions

- `getBotCreatorAddr(bytes32 _botId)`: Returns the creator's address associated with the given bot ID.
- `getBotBalanceOf(bytes32 _botId, address _account)`: Returns the balance of keys for a given bot ID and account.

## State-Changing Functions (Transactions)

### buyKey Function

- `buyKey(bytes32 _botId, uint256 _amount, uint8[] _v, bytes32[] _r, bytes32[] _s)`: Allows purchase of keys for a bot.
- **Parameters**:
  - `botId`: `bytes32` - The unique identifier of the bot for which keys are being purchased.
  - `amount`: `uint256` - The number of keys to be purchased.
  - `v`, `r`, `s`: `uint8[]`, `bytes32[]`, `bytes32[]` - The signature components to authorize the transaction.
- **Restrictions**:
  - Must have sufficient ETH for the purchase and fees.
  - The bot must have had its first buy event.
- **Results**:
  - Keys are added to the buyer's account for the given bot.
  - Protocol fees are distributed.
  - A `Trade` event is emitted detailing the transaction.

### sellKey Function

- `sellKey(bytes32 _botId, uint256 _amount)`: Enables selling of keys.
- **Parameters**:
  - `botId`: `bytes32` - The unique identifier of the bot whose keys are being sold.
  - `amount`: `uint256` - The number of keys to sell.
- **Restrictions**:
  - The caller must own the keys they are attempting to sell.
  - The bot must have completed its first buy.
- **Results**:

  - Keys are removed from the seller's account.

  - ETH is transferred to the seller, minus fees.
  - A `Trade` event is emitted detailing the transaction.

### firstBuy Function

- `firstBuy(bytes32 _botId, uint256 _amount, uint8[] _v, bytes32[] _r, bytes32[] _s)`: Initializes the first buy for a bot.
- **Parameters**:
  - `botId`: `bytes32` - The unique identifier of the bot being initialized.
  - `amount`: `uint256` - The number of keys to be purchased.
  - `v`, `r`, `s`: `uint8[]`, `bytes32[]`, `bytes32[]` - The signature components to authorize the transaction.
- **Restrictions**:
  - Can only be called once for each bot.
  - Caller must provide sufficient ETH for the keys and fees.
- **Results**:
  - The buyer receives `amount` keys, and an additional key is reserved for the bot's owner.
  - The bot is initialized and marked as having completed its first buy.
  - A `Trade` event is logged with the transaction details.

### bindCreatorAndClaim Function

- `bindCreatorAndClaim(bytes32 _botId, address _creatorAddr, uint8[] _v, bytes32[] _r, bytes32[] _s)`: Binds a creator to a bot and claims any unclaimed fees.
- **Parameters**:
  - `botId`: `bytes32` - The unique identifier of the bot to which a creator is being bound.
  - `creatorAddr`: `address` - The Ethereum address of the creator being bound to the bot.
  - `v`, `r`, `s`: `uint8[]`, `bytes32[]`, `bytes32[]` - The signature components for operation authorization.
- **Restrictions**:

  - `creatorAddr` cannot be the zero address.
  - A bot can only be bound to one creator address, and once set, it cannot be changed.

- **Results**:
  - Creator is bound to the bot.
  - Any unclaimed fees are transferred to the creator.
  - A `CreatorBound` event is emitted upon successful operation.

## Events

- `SignerAdded(address indexed signer)`: Emitted when a new signer is added.
- `SignerRemoved(address indexed signer)`: Emitted when a signer is removed.
- `CreatorBound(bytes32 indexed creatorId, address creatorAddr, uint256 timestamp)`: Emitted when a creator is bound to a bot.
- `RewardClaimed(address indexed creatorAddr, uint256 timestamp, uint256 claimIdx, uint256 amount)`: Emitted when a reward is claimed.
- `Trade(TradeEvent tradeEvent)`: Emitted on a trade event.

```
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
```

## Modifier Functions

- `addSigner(address _signer)`: Adds a new signer to the contract.
- `removeSigner(address _signer)`: Removes a signer from the contract.

## Protocol Fee Management

- `setProtocolFeeRecipient(address _protocolFeeRecipient)`: Sets the recipient for protocol fees.
- `setCreatorTreasury(address _creatorTreasury)`: Sets the creator's treasury address.
- `setProtocolFee(uint256 _protocolFee)`: Sets the protocol fee.
- `setCreatorTreasuryFee(uint256 _creatorTreasuryFee)`: Sets the creator treasury fee.
- `setCreatorFee(uint256 _creatorFee)`: Sets the creator fee.

## Utility Functions

- `getKeyPrice(uint256 _currentSupply, uint256 _keyAmount)`: Calculates the price for keys based on supply and amount.
