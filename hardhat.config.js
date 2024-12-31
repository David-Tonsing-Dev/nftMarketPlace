require("@nomicfoundation/hardhat-toolbox");

module.exports = {
  solidity: {
    version: "0.8.20", // specify your desired version here
    settings: {
      evmVersion: "paris", // Set the EVM version to "paris"
    },
  },
  networks: {
    hardhat: {
      chainId: 1337,
    },
  },
};
