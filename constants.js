const HDWalletProvider = require("truffle-hdwallet-provider");
let mnemonic = "provide return net imitate object brief dog glad spawn garage budget just";
var provider = new HDWalletProvider(mnemonic, "http://localhost:8545", 0);
let NETWORK = process.env.NETWORK;

let stageGasPrice = 1000000000; // 1 gwei
let prodGasPrice = 50000000000; // 50 gwei    

function getNetworkDetails() {
    if(NETWORK == "development" || process.argv[2] == "test"){
        let name = "IX Swap NFT Launch Collection";
        let symbol = "IXS-NFT";
        let baseTokenURI = "https://nft.app.ixswap.io/metadata/";
        let _max_token_number = "18"
        return {name: name, symbol: symbol, baseTokenURI: baseTokenURI, _max_token_number: _max_token_number};
    }
            
    if(NETWORK == "stage" || process.argv[4] == "stage"){
        let name = "IX Swap NFT Launch Collection";
        let symbol = "IXS-NFT";
        let baseTokenURI = "https://nft.app.ixswap.io/metadata/";
        let _max_token_number = "188"
        return {name: name, symbol: symbol, baseTokenURI: baseTokenURI, _max_token_number: _max_token_number};
    }
            
    if(NETWORK == "prod" || process.argv[4] == "prod"){
        let name = "IX Swap NFT Launch Collection";
        let symbol = "IXS-NFT";
        let baseTokenURI = "https://nft.app.ixswap.io/metadata/";
        let _max_token_number = "888"
        return {name: name, symbol: symbol, baseTokenURI: baseTokenURI, _max_token_number: _max_token_number};
    }    
}

exports.getNetworkDetails = getNetworkDetails();
exports.stageGasPrice = stageGasPrice;
exports.prodGasPrice = prodGasPrice;
