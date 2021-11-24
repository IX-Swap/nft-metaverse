const path = require("path");
const fs = require('fs');
const HDWalletProvider = require('@truffle/hdwallet-provider');
const { stageGasPrice, prodGasPrice } = require('./constants.js');


function provider(network) {
  if (network !== 'rinkeby' && network !== 'polygon') {
      throw new Error('Allowed network are rinkeby and polygon');
  } else if (!fs.existsSync(path.resolve(__dirname, './.pk'))) {
      throw new Error('Private key file ".pk" does not exist in monorepo root');
  }

  return new HDWalletProvider({
      privateKeys: [fs.readFileSync(path.resolve(__dirname, './.pk')).toString().trim()],
      providerOrUrl: network === 'rinkeby'
          ? "wss://rinkeby.infura.io/ws/v3/7f00ea5349e64a078e7a9533c9126cef"
          : "https://polygon-rpc.com/",
  });    
}


module.exports = {
  contracts_build_directory: path.join(__dirname, "/build"),
  networks: {
     development: {
      host: "127.0.0.1",     // Localhost (default: none)
      port: 8545,            // Standard Ethereum port (default: none)
      network_id: '*',       // Any network (default: none)
      gasPrice: 1000000000, // 1 gwei
    },
    stage: {
      provider: () => provider('rinkeby'),
      network_id: 4,
      confirmations: 2,
      timeoutBlocks: 200,  
      skipDryRun: true,
      gasPrice: stageGasPrice, 
    },
    prod: {
      provider: () => provider('polygon'),
      network_id: 137,
      networkCheckTimeout: 10000000,
      confirmations: 2,
      timeoutBlocks: 200,
      skipDryRun: true,
      gasPrice: prodGasPrice, 
    },
  },

  mocha: {
    timeout: 100000
  },

  compilers: {
    solc: {
      version: "^0.8.7",    // Fetch exact version from solc-bin (default: truffle's version)
    }
  },
};
