# Factory Module Implementation

The Factory module is responsible for pool creation and management, serving as the entry point for creating new liquidity pools in the Cetus CLMM protocol. It implements permission-based pool creation and comprehensive pool lifecycle management.

## Core Data Structures

### Pool Management

The `Pools` struct maintains a registry of all pools in the system:

- **Pool Registry**: `list` - A linked table mapping pool keys to simple pool information
- **Index Tracking**: `index` - Sequential counter for pool identification
- **Pool Identification**: `id` - Unique identifier for the pools registry object

### Pool Keys and Permissions

The module implements sophisticated pool creation controls:

- **PoolKey**: Uniquely identifies pool configurations with coin types and tick spacing
- **PoolCreationCap**: Capabilities that permit specific coin pool creations
- **PermissionPairManager**: Manages allowed coin-tick combinations for pool creation
- **DenyCoinList**: Controls which coins can or cannot be used in pool creation

## Key Features

### Pool Creation

The factory enables controlled pool creation through several mechanisms:
- **Permission-based Creation**: Requires specific capabilities for pool creation
- **Whitelist/Blacklist**: Controls which coins can participate in pool creation
- **Fee Tier Validation**: Ensures tick spacing compliance with predefined tiers
- **Pool Key Generation**: Creates unique identifiers for pool configurations

### Access Control

Robust permission management ensures secure pool creation:
- **Role-based Access**: Pool managers have elevated privileges
- **Capability-based Permissions**: Granular control over which coins can create pools
- **Configuration Validation**: Prevents invalid pool setups
- **Administrative Controls**: Admin functions for managing permissions

### Pool Lifecycle Management

The factory handles complete pool lifecycle operations:
- **Pool Registration**: Records new pools in the global registry
- **Pool Retrieval**: Efficient lookup of existing pools
- **Pool Validation**: Verifies pool existence and correctness
- **Pool Statistics**: Maintains pool count and metadata

## Implementation Details

The factory module uses dynamic object fields to store complex permission structures, enabling runtime configuration of allowed pool creation patterns. It maintains separate tracking for:

1. **Allowed Coin Lists**: Which coins are permitted for pool creation
2. **Denied Coin Lists**: Which coins are restricted from pool creation
3. **Permission Pair Configurations**: Which coin combinations can be used with specific tick spacings
4. **Creation Capabilities**: Individual permissions for specific coin types

This design allows for flexible, secure pool creation that can be managed by protocol administrators while still permitting community-driven pool creation through proper capability management.

The implementation also includes comprehensive event emission for tracking pool creation activities, permission changes, and access control modifications, making it easy to monitor and audit pool operations.