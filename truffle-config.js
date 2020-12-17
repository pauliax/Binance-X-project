require('dotenv').config();
const HDWalletProvider = require("@truffle/hdwallet-provider");

const MNEMONIC = process.env.MNEMONIC;
const INFURA_KEY = process.env.INFURA_KEY;

const needsInfura = process.env.npm_config_argv &&
  (process.env.npm_config_argv.includes('rinkeby') ||
    process.env.npm_config_argv.includes('ropsten') ||
    process.env.npm_config_argv.includes('live') ||
    process.env.npm_config_argv.includes('bsctest'));

if ((!MNEMONIC || !INFURA_KEY) && needsInfura) {
  console.error('Please set a mnemonic and infura key.');
  process.exit(0);
}

module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // for more about customizing your Truffle configuration!
  contracts_build_directory: "src/contracts",
  networks: {
    development: {
      host: "127.0.0.1",
      port: 7545,
      network_id: "*" // Match any network id
    },
    develop: {
      port: 8545
    },
    rinkeby: {
      provider: function () {
        return new HDWalletProvider(
          MNEMONIC,
          "https://rinkeby.infura.io/v3/" + INFURA_KEY
        );
      },
      network_id: 4,
      gas: 5000000,
      gasPrice: 40000000000
    },
    ropsten: {
      provider: function () {
        return new HDWalletProvider(
          MNEMONIC,
          "https://ropsten.infura.io/v3/" + INFURA_KEY
        );
      },
      network_id: 3,
      networkCheckTimeout: 10000000,
      gas: 1000000,
      gasPrice: 50000000000
    },
    live: {
      network_id: 1,
      provider: function () {
        return new HDWalletProvider(
          MNEMONIC,
          "https://mainnet.infura.io/v3/" + INFURA_KEY
        );
      },
      gas: 1000000,
      gasPrice: 50000000000
    },
    bsctest: {
      provider: () => new HDWalletProvider(MNEMONIC, `https://data-seed-prebsc-1-s1.binance.org:8545`),
      network_id: 0x61,
      confirmations: 2,
      timeoutBlocks: 200,
      skipDryRun: true
    },
  },
  mocha: {
    reporter: 'eth-gas-reporter',
    reporterOptions: {
      currency: 'USD',
      gasPrice: 100
    }
  },
  compilers: {
    solc: {
      version: "^0.7.5"
    }
  },
  plugins: ["solidity-coverage"]
};