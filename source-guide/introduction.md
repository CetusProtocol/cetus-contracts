# Cetus CLMM Source Code Guide

## Introduction and Project Overview

This guide provides a comprehensive overview of the Cetus CLMM (Concentrated Liquidity Market Maker) smart contract implementation. The Cetus CLMM protocol is a decentralized exchange protocol built on the Move blockchain that implements concentrated liquidity AMM (Automated Market Maker) functionality.

### What is Concentrated Liquidity?

Unlike traditional constant product AMMs that distribute liquidity uniformly across the entire price range, Concentrated Liquidity allows liquidity providers to specify price ranges where their liquidity is active. This significantly improves capital efficiency by concentrating liquidity where it's most needed.

### Core Architecture

The Cetus CLMM protocol consists of several interconnected modules that work together to provide a complete AMM solution:

1. **Pool Module**: Core functionality for trading, liquidity management, and position handling
2. **Position Module**: Management of user positions and associated NFTs
3. **Factory Module**: Pool creation and management
4. **Rewarder Module**: Incentive distribution system for liquidity providers
5. **Tick Module**: Price tick management for concentrated liquidity
6. **Configuration Module**: System-wide configuration and access control

### Key Features

- Concentrated liquidity positions with configurable price ranges
- Advanced reward distribution system with multiple reward tokens
- Permission-based pool creation and management
- Flash loan support for advanced DeFi strategies
- Protocol fee collection and management
- Pool restoration capabilities for recovery scenarios

This guide will walk through each module's implementation and explain how they work together to form a robust decentralized exchange protocol.