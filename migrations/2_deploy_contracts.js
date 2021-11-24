var IxsNft = artifacts.require("./IxsNft");
let { getNetworkDetails } = require('../constants.js');

module.exports = async function(deployer) {
    let networkDetails = getNetworkDetails;
    await deployer.deploy(IxsNft, networkDetails.name, networkDetails.symbol, networkDetails.baseTokenURI, networkDetails._max_token_number);
};