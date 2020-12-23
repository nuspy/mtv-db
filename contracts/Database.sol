pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./core/Persistance.sol";
import "./DatabaseFactory.sol";

contract Database is Persistance, Ownable {
    /** @dev SafeMath library */
    using SafeMath for uint256;

    // Persistant data
    Persistance.TableEntry[] private tables;
    mapping(uint256 => bool) private knownTables;
    mapping(bytes32 => bool) private knownTableNames;

    // Utility
    uint256 private currentTableIndex;

    // Factory and pricing
    DatabaseFactory public factory;

    constructor(address factoryAddress, address creatorAddress) public {
        factory = DatabaseFactory(factoryAddress);
        
        transferOwnership(creatorAddress);
    }

    /**
     * Equivalent of `show tables;` in SQL
     * @return _tables Array of strings. Empty rows must be ignored.
     *    Even indices are tables' identifiers.
     *    Odd indices are tables' names.
     */
    function showTables() external view returns(bytes32[] memory _tables) {
        bytes32[] memory result = new bytes32[](tables.length * 2);

        for (uint i = 0; i < tables.length; i++) {
            if (!knownTables[tables[i].index]) {
                continue;
            }

            result[i * 2] = bytes32(tables[i].index);
            result[i * 2 + 1] = tables[i].name;
        }

        return result;
    }

    /**
     * Equivalent of `create table` in SQL
     * @param _name Table name
     * @param _columns Table columns
     * @return _index Table's identifier
     */
    function createTable(bytes32 _name, bytes32[] calldata _columns) external price(factory.CreateTablePrice()) returns(uint256 _index) {
        require(_name[0] != 0, "Name must not be empty");
        require(_columns.length > 0, "Empty columns array");

        // Check if name is already taken
        require(knownTableNames[_name] == false, "Duplicate table name");

        // Insert new table into mapping
        tables.push();
        Persistance.TableEntry storage table = tables[tables.length - 1];
        table.name = _name;
        table.index = currentTableIndex;

        // Set into known mapping
        knownTableNames[_name] = true;
        knownTables[currentTableIndex] = true;

        // Insert table's columns defintions
        for (uint i = 0; i < _columns.length; i += 2) {
            table.data.columns.push(Persistance.Column({
                columnType: Persistance.ColumnType(uint(_columns[i])),
                name: _columns[i + 1]
            }));
        }

        uint256 tmpIndex = currentTableIndex;

        // Increment counter
        currentTableIndex = currentTableIndex.add(1);

        // Emit event
        emit TableCreated(tmpIndex, _name);

        return tmpIndex;
    }

    function dropTable(uint256 _table) external hasTable(_table) price(factory.DropTablePrice()) {
        TableEntry storage table = tables[_table];

        // Clear storage
        delete tables[_table];
        knownTables[_table] = false;
        knownTableNames[table.name] = false;

        // Emit event
        emit TableDropped(_table);
    }

    function desc(uint256 _table) external view hasTable(_table) returns (bytes32[] memory _columns) {
        bytes32[] memory result = new bytes32[](tables[_table].data.columns.length * 2);

        for (uint i = 0; i < tables[_table].data.columns.length; i++) {
            result[i * 2] = bytes32(uint(tables[_table].data.columns[i].columnType));
            result[i * 2 + 1] = tables[_table].data.columns[i].name;
        }

        return result;
    }

    function insert(uint256 _table, string[] calldata _values) external
        hasTable(_table)
        price(factory.InsertIntoPrice())
        returns(uint256 _index)
    {
        // Create an empty row
        tables[_table].data.rows.push();
        uint256 latestIndex = tables[_table].data.rows.length - 1;

        /**
         * @dev we need to iterate the array because of a bug in the compiler
         * @todo Switch to a direct assignment once ABIEncoderV2 is stable
         */
        for (uint i = 0; i < _values.length; i++) {
            tables[_table].data.rows[latestIndex].push(_values[i]);
        }

        // Emit event
        emit RowCreated(latestIndex);

        return latestIndex;
    }

    function deleteDirect(uint256 _table, uint256 _index) external hasTable(_table) price(factory.DeleteFromPrice()) {
        // Clear storage
        delete tables[_table].data.rows[_index];

        // Emit event
        emit RowDeleted(_index);
    }

    function updateDirect(uint256 _table, uint256 _index, uint256[] calldata _columns, string[] calldata _values) external
        hasTable(_table)
        price(factory.UpdatePrice())
    {
        require(_columns.length == _values.length, "Columns and values arrays must be of equal length");

        string[] storage row = tables[_table].data.rows[_index];
        for (uint i = 0; i < _columns.length; i++) {
            row[_columns[i]] = _values[i];
        }

        emit RowUpdated(_index);
    }

    function selectAll(uint256 _table, uint256 _offset, uint256 _limit) external view
        hasTable(_table)
        returns (string[][] memory _rows)
    {
        require(_offset >= 0, "Offset must be a positive integer or zero");
        require(_limit >= 0 && _limit <= 50, "Limit must be between 0 and 50");
        require(_offset < tables[_table].data.rows.length, "Offset must be smaller that the number of rows");

        uint256 upper = _offset.add(_limit);
        uint256 limit = tables[_table].data.rows.length < upper ? tables[_table].data.rows.length : upper;

        string[][] memory rows = new string[][](limit);

        for (uint i = _offset; i < limit; i++) {
            rows[i.sub(_offset)] = tables[_table].data.rows[i];
        }

        return rows;
    }

    function rowsCount(uint256 _table) external view hasTable(_table) returns (uint256 _count) {
        return tables[_table].data.rows.length;
    }

    function _purchase(address _from, uint256 _price) internal {
        ERC20 token = ERC20(factory.EMTV_TOKEN_ADDRESS());

        bool result = token.transferFrom(_from, address(factory), _price);

        require(result, "Transfer returned false");
    }

    modifier hasTable(uint256 _table) {
        require(knownTables[_table] == true, "Table does not exist");
        _;
    }

    modifier price(uint256 _price) {
        require(factory.canPurchase(msg.sender, _price), "Not enough eMTV to proceed with the transaction");

        _purchase(msg.sender, _price);

        _;
    }

    event TableCreated(uint256 index, bytes32 name);
    event TableDropped(uint256 index);
    event RowCreated(uint256 index);
    event RowDeleted(uint256 index);
    event RowUpdated(uint256 index);
}