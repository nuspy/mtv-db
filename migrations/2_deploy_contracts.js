const Database = artifacts.require('./Database.sol');

module.exports = async function (deployer) {
    await deployer.deploy(Database);

    await Database.deployed();
};