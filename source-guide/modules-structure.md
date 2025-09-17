# Core Modules Structure

The Cetus CLMM protocol is built around a modular architecture where each component serves a specific purpose in the overall system. Understanding the relationship between these modules is crucial for grasping how the protocol functions.

## Module Interdependencies

The core modules interact in a well-defined manner:

### Pool Module (central hub)
The `pool` module is the central component that orchestrates most operations. It manages:
- Trading functionality (swaps)
- Liquidity provision and removal
- Position tracking and management
- Fee calculations and distributions
- Reward distribution coordination

### Position Module (user positions)
The `position` module handles user-facing position management:
- Position NFT creation and management
- Position metadata and display information
- Liquidity calculations for positions
- Reward accumulation tracking

### Factory Module (pool creation)
The `factory` module governs pool lifecycle management:
- Pool creation and initialization
- Pool key generation and validation
- Permission management for pool creation
- Coin type validation and restrictions

### Rewarder Module (incentives)
The `rewarder` module implements the incentive system:
- Multiple reward token support
- Reward distribution based on liquidity
- Point-based reward allocation mechanism
- Vault management for reward assets

### Tick Module (price management)
The `tick` module handles discrete price points:
- Tick initialization and management
- Liquidity tracking at specific price levels
- Fee and reward accumulation at ticks
- Efficient data structures for price indexing

## Data Flow and Control Flow

1. **Pool Creation**: Factory module creates pools and registers them
2. **Position Management**: Users interact with positions through the position module
3. **Trading Operations**: Pool module handles swaps and liquidity updates
4. **Reward Distribution**: Pool module coordinates with rewarder module for reward processing
5. **Price Management**: Tick module maintains price points and liquidity distribution

## Key Data Structures

Each module implements specific data structures that form the backbone of the system:

- **Pool**: Main pool structure containing state like liquidity, fees, and price
- **Position**: User position tracking with NFT identification
- **TickManager**: Efficient storage and retrieval of price tick information
- **RewarderManager**: Configuration and state for reward distribution systems
- **Pools**: Factory-managed list of all pools in the system

This modular approach allows for clear separation of concerns and makes the system easier to maintain, extend, and debug.