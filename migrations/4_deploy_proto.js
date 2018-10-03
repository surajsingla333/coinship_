var EtaProto = artifacts.require("./EtaProto.sol")
var ZetaProto = artifacts.require("./ZetaProto.sol")

module.exports = function(deployer) {
    deployer.deploy(EtaProto);
    deployer.deploy(ZetaProto);
};