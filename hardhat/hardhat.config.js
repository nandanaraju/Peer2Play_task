require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  defaultNetwork: "alchemyhol",
  networks: {
    localhost: {
      url: "http://127.0.0.1:8545"
    },
    alchemyhol:{
      url: "https://eth-sepolia.g.alchemy.com/v2/aEW4ADL3Ukk-b-3ggwgbWfZowhq1Me7L",
      accounts:["2f81fbd962b14cab7ea4714dcec9c5b7bc3885c8f2083047fc3aec1808ec8876"]
    },
    hardhat: {
      // See its defaults
    }
  },
  solidity: "0.8.20",
};