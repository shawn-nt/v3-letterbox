require("@nomicfoundation/hardhat-toolbox");
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-etherscan");
//require("@openzeppelin/hardhat-upgrades");
require("hardhat-deploy");
require("dotenv").config();

const PRIVATE_KEY_MOONBASE = process.env.PRIVATE_KEY_MOONBASE;
const MOONBASE_RPC_URL = process.env.MOONBASE_RPC_URL;
const MOONBASEALPHA_API_KEY = process.env.MOONBASEALPHA_API_KEY;

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.15",
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {},
    moonbase: {
      url: MOONBASE_RPC_URL,
      accounts: [PRIVATE_KEY_MOONBASE],
      saveDeployments: true,
      chainId: 1287,
    },
  },
  etherscan: {
    apiKey: MOONBASEALPHA_API_KEY,
  },
};
