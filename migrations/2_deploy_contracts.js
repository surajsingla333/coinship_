var CoshToken = artifacts.require("./CoshToken.sol");
var CoshTokenSale = artifacts.require("./CoshTokenSale.sol");

module.exports = function(deployer) {
  deployer.deploy(CoshToken, 1000000).then(function() {
    // Token price is 0.001 Ether
    var tokenPrice = 1000000000000000;
    return deployer.deploy(CoshTokenSale, CoshToken.address, tokenPrice);
  });
};

