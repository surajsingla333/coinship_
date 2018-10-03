var EtaProto = artifacts.require("./EtaProto.sol");

contract('EtaProto', function(accounts) {
    var tokenInstance;
    var owner = accounts[0];

    it('it makes the order list', function() {
        return EtaProto.deployed().then(function(instance) {
            tokenInstance = instance;
            return tokenInstance.makeOrder();
        }).then(function(maker) {
            assert.equal(maker, accounts[0], 'made by maker');
        })
    })
})