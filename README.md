# Liquidity Pool Dashboard

This project is a decentralized liquidity pool dashboard built with React and Ethereum smart contracts. It allows users to interact with a liquidity pool by swapping tokens, adding liquidity, and removing liquidity from the pool.

## Features
- **Swap Tokens**: Swap between two tokens supported by the liquidity pool.
- **Add Liquidity**: Add liquidity to the pool by supplying both tokens.
- **Remove Liquidity**: Remove liquidity from the pool based on the user's share.

## Requirements
- [MetaMask](https://metamask.io/) (or another Ethereum-compatible wallet) installed in your browser.
- An Ethereum network (e.g., Mainnet, Testnet, or your custom network).

## Setup Instructions

### 1. Clone the repository

```bash
git clone https://github.com/your-username/liquidity-pool-dashboard.git
cd liquidity-pool-dashboard
```
### 2. Install dependencies
Make sure you have Node.js installed. Then, run the following command to install dependencies:

```bash

npm install
```
### 3. Update Configuration
Replace deployed_address.json and abi.json with the contract’s actual ABI and deployed address.
Update the tokens object with the correct token addresses in the LiquidityPool.js file.
### 4. Run the application
Once everything is set up, you can start the development server:
```bash
npm run dev
```
The application will open at http://localhost:5173 in your browser.

### 5. Connect Wallet
Upon loading, you will be prompted to connect your Ethereum wallet (e.g., MetaMask).
Ensure your wallet is connected to the correct network (Testnet/Mainnet).
Usage
Tabs:
Swap: Swap between two tokens in the liquidity pool.
Add Liquidity: Add both tokens to the liquidity pool.
Remove Liquidity: Remove liquidity from the pool based on your share.
Error Handling:
The dashboard will show error messages for any failed transactions or issues (e.g., insufficient funds, contract failures).
### Technologies Used
React: Frontend framework for building the user interface.
Ethers.js: Ethereum library for interacting with the blockchain.
MetaMask: Browser wallet for interacting with Ethereum.