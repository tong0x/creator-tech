# Database Schema Recommendation

## Tables Definition

### Bot Table

On the contract, the Bot ID is a bytes32 datatype that maps to the bot's related data. The contract does not store the Bot ID; the backend must record the Bot ID and corresponding data.

| Field Name       | Data Type | Constraints | Description                      |
| ---------------- | --------- | ----------- | -------------------------------- |
| BotID            | INT       | PRIMARY KEY | Unique identifier for the bot    |
| BotOnChainID     | BYTES32   | UNIQUE      | Bot ID in the contract           |
| BotMakerID       | INT       | FOREIGN KEY | Reference to the Bot Maker table |
| BondingCurveType | VARCHAR   |             | Type of bonding curve            |

### Bot Maker Table

| Field Name      | Data Type | Constraints | Description                         |
| --------------- | --------- | ----------- | ----------------------------------- |
| BotMakerID      | INT       | PRIMARY KEY | Unique identifier for the bot maker |
| BotMakerAddress | VARCHAR   |             | Blockchain address of the bot maker |

### Bot Transaction Table

| Field Name      | Data Type | Constraints | Description                             |
| --------------- | --------- | ----------- | --------------------------------------- |
| TransactionID   | INT       | PRIMARY KEY | Unique identifier for the transaction   |
| BotID           | INT       | FOREIGN KEY | Reference to the Bot table              |
| TransactionType | VARCHAR   |             | Type of transaction (buy/sell/firstBuy) |
| Amount          | DECIMAL   |             | Amount of keys transacted               |
| TransactionDate | TIMESTAMP |             | Date and time of the transaction        |

## Relationships

- `Bot.BotMakerID` references `BotMaker.BotMakerID` to link bots to their creators.
- `BotTransaction.BotID` references `Bot.BotID` to associate transactions with their specific bots.

## Expected Operations

- **First Buy**: The user selects the desired bot ID and quantity for purchase, then the frontend requests the bot's bonding curve type based on `Bot.BondingCurveType` and ECDSA signature from the backend. The user's wallet uses these parameters to execute the transaction.
- **Buy Key**: The user selects a bot ID and quantity to purchase, and the frontend requests the ECDSA signature from the backend. The user's wallet uses these parameters to execute the transaction.
- **Sell Key**: The user selects the bot ID and quantity they wish to sell. The user's wallet uses these parameters to execute the transaction.
- **Bind Creator**: The user selects a bot ID to bind, and the backend verifies `BotMaker.BotMakerAddress`. If verified, it provides an ECDSA signature for the user's wallet to complete the binding transaction.
- **Transaction Recording**: Backend captures each buy or sell transaction with relevant details in the `Bot Transaction` table.
