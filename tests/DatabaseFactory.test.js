const { accounts, contract, web3 } = require('@openzeppelin/test-environment');
const { expectEvent, expectRevert } = require('@openzeppelin/test-helpers');
const { expect } = require('chai');

const Bytes = require('../utility/Bytes');

// Load compiled artifacts
const Factory = contract.fromArtifact('DatabaseFactory');
const Token = contract.fromArtifact('TestToken');

describe('DatabaseFactory', () => {
    const [ deployer, user, user2, notAllowed ] = accounts;
    
    const AmountPerUser = web3.utils.toWei('10000');
    const DatabaseName = Bytes.stringToBytes('test_db');
    const DatabaseNamePadded = Bytes.stringToBytes('test_db', true);

    beforeEach(async () => {
        this.contract = await Factory.new({ from: deployer });
        this.token = await Token.new({ from: deployer });

        await this.contract.updateTokenAddress(this.token.address, { from: deployer });
    });

    it('updates create price', async () => {
        const receipt = await this.contract.updateCreateDatabasePrice('12345', { from: deployer });

        expectEvent(receipt, 'CreateDatabasePriceUpdated', { '_newPrice': '12345' });
    });

    it('create: not enough tokens', async () => {
        await expectRevert(
            this.contract.create(DatabaseName, { from: user }),
            "SafeMath: subtraction overflow." // Safemath reverts the transaction when there is an overflow
        );
    });

    it('create from: not enough tokens', async () => {
        await expectRevert(
            this.contract.createFrom(DatabaseName, user2, { from: user }),
            "SafeMath: subtraction overflow." // Safemath reverts the transaction when there is an overflow
        );
    });

    it('create: not allowed', async () => {
        await this.token.transfer(notAllowed, AmountPerUser, { from: deployer });

        await expectRevert(
            this.contract.create(DatabaseName, { from: notAllowed }),
            "ERC20: transfer amount exceeds allowance."
        );
    });

    it('create from: not allowed', async () => {
        await this.token.transfer(notAllowed, AmountPerUser, { from: deployer });

        await expectRevert(
            this.contract.createFrom(DatabaseName, notAllowed, { from: notAllowed }),
            "ERC20: transfer amount exceeds allowance."
        );
    });

    it('create: successful', async () => {
        await this.token.transfer(user, AmountPerUser, { from: deployer });
        await this.token.approve(this.contract.address, AmountPerUser, { from: user });

        const receipt = await this.contract.create(DatabaseName, { from: user });

        expectEvent(receipt, 'DatabaseCreated', { _by: user });
    });

    it('create from: successful', async () => {
        await this.token.transfer(user2, AmountPerUser, { from: deployer });
        await this.token.approve(this.contract.address, AmountPerUser, { from: user2 });

        const receipt = await this.contract.createFrom(DatabaseName, user2, { from: user });

        expectEvent(receipt, 'DatabaseCreated', { _by: user2 });
    });

    it('create from: invalid from', async () => {
        await expectRevert(
            this.contract.createFrom(DatabaseName, '0x0000000000000000000000000000000000000000', { from: user }),
            'Invalid owner address'
        );
    });

    it('create: duplicated name, same owner', async () => {
        await this.token.transfer(user, AmountPerUser, { from: deployer });
        await this.token.approve(this.contract.address, AmountPerUser, { from: user });

        // Create first database
        await this.contract.create(DatabaseName, { from: user });
        
        await expectRevert(
            this.contract.create(DatabaseName, { from: user }),
            'Duplicate database name'
        );
    });

    it('create from: duplicated name, same owner', async () => {
        await this.token.transfer(user2, AmountPerUser, { from: deployer });
        await this.token.approve(this.contract.address, AmountPerUser, { from: user2 });

        // Create first database
        await this.contract.createFrom(DatabaseName, user2, { from: user });
        
        await expectRevert(
            this.contract.createFrom(DatabaseName, user2, { from: user }),
            'Duplicate database name'
        );
    });

    it('create: duplicated name, different owner', async () => {
        await this.token.transfer(user, AmountPerUser, { from: deployer });
        await this.token.approve(this.contract.address, AmountPerUser, { from: user });

        await this.token.transfer(user2, AmountPerUser, { from: deployer });
        await this.token.approve(this.contract.address, AmountPerUser, { from: user2 });

        // Create first database
        await this.contract.create(DatabaseName, { from: user });
        
        const receipt = await this.contract.create(DatabaseName, { from: user2 }); 

        expectEvent(receipt, 'DatabaseCreated', { _name: DatabaseNamePadded, _by: user2 });
    });
});