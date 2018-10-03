var CoshBTC = artifacts.require("./CoshBTC.sol");
var CoshETH = artifacts.require("./CoshETH.sol");

module.exports = function(deployer) {
    deployer.deploy(CoshBTC, 100000);
    deployer.deploy(CoshETH, 100000);
  };