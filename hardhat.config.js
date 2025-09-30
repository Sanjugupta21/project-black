require("@nomicfoundation/hardhat-toolbox");
require('dotenv').config();

module.exports = {
  solidity: "0.8.20",
  networks: {
    // THIS IS OUR NEW TARGET FOR DEPLOYMENT
    lasnaTestnet: {
      url: "https://lasna-rpc.rnk.dev/",
      chainId: 5318007,
      accounts: [process.env.PRIVATE_KEY]
    },
    // We will keep this here for the final deployment
    reactiveMainnet: {
      url: "https://mainnet-rpc.rnk.dev/",
      chainId: 1597,
      accounts: [process.env.PRIVATE_KEY]
    }
  }
};