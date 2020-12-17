# Xmas Lab

### The DApp is deployed on the BSC testnet.

The application consists of 2 main parts: the laboratory and reward snapshots.

In the laboratory, you stake XLAB/BNB LP tokens and as a reward get XLAB tokens.
When your tokens are staked, you are accumulating rewards. If you decide to withdraw, you have to pay a withdrawal fee.
 
Withdrawal fees go to the reward contract. XLAB and BNB tokens are extracted from the LP pair. 
XLAB tokens are burned and BNB tokens are stored as a reward. 
Reward contract does the snapshot of XLAB token balances and creates a new reward. 
Then, XLAB token HODLers can claim their share in proportion to how much XLABs they held at the snapshot time and what was the total supply.

This model is expected to benefit both HODLers and liquidity providers.

**PancakeSwap did not work very well on BSC testnet 
  so we had to deploy our own mock version of Uniswapv2 and create an LP pair.**

---

* [Binance X Hackathon on Gitcoin](https://gitcoin.co/issue/binancex/Grant-projects/8/100024334 "Link to the hackaton")

* [Deployed DApp](https://xmas-lab.netlify.app/ "Link to the DApp")

* Video presentation:

[![Video presentation](http://img.youtube.com/vi/aljM-yXoiYs/default.jpg)](https://youtu.be/aljM-yXoiYs)

---

### Contracts

* 	Token: [0x4424FA528Ab1e5BCe2372Baf024A5658FEdacBDc](https://explorer.binance.org/smart-testnet/address/0x4424FA528Ab1e5BCe2372Baf024A5658FEdacBDc "Link to the token contract")
* 	Vault: [0x42CFFf119c6033B19ae40DcfF0a4Ed673b292778](https://explorer.binance.org/smart-testnet/address/0x42CFFf119c6033B19ae40DcfF0a4Ed673b292778 "Link to the vault contract")
* 	Reward: [0x41cFEfFB9c00F8313bDF8835f8b478D746e786D0](https://explorer.binance.org/smart-testnet/address/0x41cFEfFB9c00F8313bDF8835f8b478D746e786D0 "Link to the reward contract")

---

### Screenshots

![screenshot 1](screenshots/1.png)

![screenshot 2](screenshots/2.png)


## Technical stuff

### Technologies used

* Node v14.15
* Solidity 0.7.5
* Truffle v5 (+ pet-shop box)
* Web3.js v1.2.9

### Instructions

Clone the project

Install Truffle framework: 

```
npm install -g truffle
```

Install dependencies: 

```
npm install
```

Create .env file in root directory with the same content as in .env.example (replace <...> with real values). 
Infura key can be obtained from https://infura.io/

Compile the contracts:

```
truffle compile
```

Deploy:

See available networks in truffle-config.js.
Also check migrations/2_deploy_contracts.js file to make sure that the deployment parameters are correct.

### Token contract parameters:

_name

    // Token name.
    
_symbol
    
    // Token symbol.
    
_initialSupplyWithoutDecimals

    // Initial supply (premine). Specify it without decimals. It is sent to the deployer address.

### Reward contract parameters:

_token
    
    // Token contract address.

### Vault contract parameters:

_lpToken

    // LP pair token address

_rewardToken

    // Token contract address.

_WETH

    // WETH address.
    
_rewardContract
    
    // Reward contract address.

__withdrawalFeePercentage

    // Withdrawal fee percentage. Please note that denominator is 10000 so to set 8% you need to input 800.
    
_apyPercentage

    // APY percentage. Please note that denominator is 10000 so to set 300% you need to input 30000.

Deploy on BSC testnet:

```
npm run migrate-bsctest
```

Rinkeby:

```
npm run migrate-rinkeby
```

Mainnet:

If you are deploying to the mainnet, please adjust gasPrice (you can adjust gas amount also) in the truffle-config.js.

```
npm run migrate-live
```

Or you can deploy the flattened contracts (under directory flatten) yourself (for example, with Remix IDE).