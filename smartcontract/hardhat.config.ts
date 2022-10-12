import * as dotenv from "dotenv";

import { HardhatUserConfig, task } from "hardhat/config";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "hardhat-gas-reporter";
import "solidity-coverage";
import 'hardhat-contract-sizer';
import 'hardhat-abi-exporter';
import 'solidity-docgen';

// const privatekey = require('./secrets.json');
const { mnemonic, privatekey } = require('./secrets.json');
dotenv.config();

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.4",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000,
      },
    },
  },
  networks: {
    ropsten: {
      url: process.env.ROPSTEN_URL || "",
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    qa: {
      url: "http://192.168.1.9:8545/",
      chainId: 31338,
      gasPrice: 2000000000,
      accounts: [
        //address = 0x8FC689Ce34D10Ba5F93B5E25B9537DB03830354A
        "0x44ebb0188aa9b4d6e3d0eae2d46898112a4fb09d67fd9faa727705b7950cbe57",
        // address = 0x5A1B71A108E4f080db5cA3488eae889179E2beee --> Luan
        "0xea9da230825defb25147c5e96e6988a03dcf3504d417f0fa225a5871708c79eb"
      ]
    },
    // bsc: {
    //   url: "https://bsc-dataseed.binance.org/",
    //   chainId: 56,
    //   gasPrice: 20000000000,
    //   accounts: [privatekey]
    // },
    // bsctestnet: {
    //   url: "https://data-seed-prebsc-1-s1.binance.org:8545",
    //   chainId: 97,
    //   gasPrice: 20000000000,
    //   accounts: [privatekey]
    // },
    localhost: {
      url: "http://localhost:8545/",
      chainId: 31337,
      gasPrice: 2000000000,
      accounts: [privatekey]
    },
    klaytn: {
      url: "https://api.baobab.klaytn.net:8651",
      chainId: 1001,
      gasPrice: 250000000000,
      accounts: [privatekey]
    }
  },
  gasReporter: {
    enabled: true, //process.env.REPORT_GAS !== undefined,
    currency: "USD",
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
  contractSizer: {
    alphaSort: true,
    disambiguatePaths: false,
    runOnCompile: true,
    strict: true,
  },
  abiExporter: {
    path: './abi',
    runOnCompile: true,
    format: 'json'
  },
  docgen: {
    pages: "files"
  },
};

export default config;
