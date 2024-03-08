require("@nomiclabs/hardhat-waffle");
require("solidity-coverage");
require("hardhat-contract-sizer");
require("@primitivefi/hardhat-dodoc");
require("@nomicfoundation/hardhat-verify");
require("dotenv").config();

const networks = {};

if (process.env.RPC_URL /* && process.env.PRIVATE_KEY */) {
  networks.mainnet = {
    url: process.env.RPC_URL,
    //accounts: [process.env.PRIVATE_KEY],
  };
}

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    version: "0.8.24",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1200,
      },
    },
  },
  ...(Object.keys(networks).length ? { networks } : {}),
  contractSizer: {
    runOnCompile: true,
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
};
