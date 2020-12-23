const Utility = require('../utility/Bytes');

const { accounts, contract, web3 } = require('@openzeppelin/test-environment');
const { expectEvent, expectRevert } = require('@openzeppelin/test-helpers');
const { expect } = require('chai');

// Load compiled artifacts
const Token = contract.fromArtifact('TestToken');
const Database = contract.fromArtifact('Database');
const DatabaseFactory = contract.fromArtifact('DatabaseFactory');

const TABLE_INDEX = '0'; // Table indexing starts at 0

const createTable = async function(contract, from, tableName, columns) {
    return await contract.createTable(
        tableName,
        columns,
        { from }
    );
};

const numberToBytes = function(num) {
    return web3.utils.padLeft(web3.utils.numberToHex(num), 64, '0');
}

describe('Database', () => {
    const [ deployer, user ] = accounts;

    const TABLE_NAME = Utility.stringToBytes('Bacon');
    const TABLE_NAME_PAD = Utility.stringToBytes('Bacon', true);

    const TABLE_COLUMNS = [
        numberToBytes(0),
        Utility.stringToBytes('integer_column'),
        numberToBytes(2),
        Utility.stringToBytes('string_column'),
        numberToBytes(6),
        Utility.stringToBytes('boolean_column')
    ];

    const AmountPerUser = web3.utils.toWei('10000');

    beforeEach(async () => {
        this.token = await Token.new({from: deployer});
        this.factory = await DatabaseFactory.new({ from: deployer });
        this.contract = await Database.new(this.factory.address, { from: deployer });

        await this.factory.updateTokenAddress(this.token.address, { from: deployer });

        await this.token.transfer(user, AmountPerUser, { from: deployer });
        await this.token.approve(this.contract.address, AmountPerUser, { from: user });
    });

    it('creates table', async () => {
        const receipt = await createTable(this.contract, user, TABLE_NAME, TABLE_COLUMNS);

        expectEvent(receipt, 'TableCreated', { name: TABLE_NAME_PAD, index: TABLE_INDEX }); 
    });

    it('drops table', async () => {
        // Then create a table
        await createTable(this.contract, user, TABLE_NAME, TABLE_COLUMNS);

        const receipt = await this.contract.dropTable(TABLE_INDEX, { from: user });

        expectEvent(receipt, 'TableDropped', { index: TABLE_INDEX });
    });

    it('table existance check', async () => {
        await expectRevert(
            this.contract.dropTable(Utility.stringToBytes('FAKE TABLE NAME'), { from: user }),
            "Table does not exist"
        );
    });

    it('tables list', async () => {
        // Then create a table
        await createTable(this.contract, user, TABLE_NAME, TABLE_COLUMNS);

        const tables = await this.contract.showTables({ from: user });

        expect(tables[0]).to.equal(numberToBytes(0));
        expect(tables[1]).to.equal(TABLE_NAME_PAD);
    });

    it('insert', async () => {
        // Then create a table
        await createTable(this.contract, user, TABLE_NAME, TABLE_COLUMNS);

        const rowData = [
            "1234", // number type
            "foo bar", // string type
            "0" // boolean type
        ];

        // Insert into table
        const receipt = await this.contract.insert(
            TABLE_INDEX,
            rowData,
            { from: user }
        );

        expectEvent(receipt, 'RowCreated', { index: '0' });
    });

    it('delete single row', async () => {
        // Then create a table
        await createTable(this.contract, user, TABLE_NAME, TABLE_COLUMNS);

        const rowData = [
            "1234", // number type
            "foo bar", // string type
            "0" // boolean type
        ];

        // Insert into table
        await this.contract.insert(
            TABLE_INDEX,
            rowData,
            { from: user }
        );

        const prevTable = await this.contract.selectAll(0, 0, 5, { from: user });

        // Delete from table
        const receipt = await this.contract.deleteDirect(
            TABLE_INDEX,
            '0',
            { from: user }
        );

        const currTable = await this.contract.selectAll(0, 0, 5, { from: user });

        expectEvent(receipt, 'RowDeleted', { index: '0' });
    });

    it('update single row', async () => {
        // Then create a table
        await createTable(this.contract, user, TABLE_NAME, TABLE_COLUMNS);

        const rowData = [
            "1234", // number type
            "foo bar", // string type
            "0" // boolean type
        ];

        // Insert into table
        await this.contract.insert(
            TABLE_INDEX,
            rowData,
            { from: user }
        );

        // Delete from table
        const receipt = await this.contract.updateDirect(
            TABLE_INDEX,
            '0',
            [0, 2],
            [
                "3333",
                "1"
            ],
            { from: user }
        );

        expectEvent(receipt, 'RowUpdated', { index: '0' });
    });

    it('select all', async () => {
        // Then create a table
        await createTable(this.contract, user, TABLE_NAME, TABLE_COLUMNS);

        const rowData = [
            "1234", // number type
            "foo bar", // string type
            "0" // boolean type
        ];

        // Insert into table
        await this.contract.insert(
            TABLE_INDEX,
            rowData,
            { from: user }
        );

        // Delete from table
        const result = await this.contract.selectAll(
            TABLE_INDEX,
            0,
            50,
            { from: user }
        );

        //expect(result).to.equal([rowData]);
    });
});

