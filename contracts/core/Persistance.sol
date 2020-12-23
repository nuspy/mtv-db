pragma solidity ^0.6.0;

interface Persistance {
    // Enum types
    enum ColumnType { Int, Usigned, String, Double, Date, Datetime, Boolean }

    // Persistance data structures
    struct Column {
        ColumnType columnType;
        bytes32 name;
    }
    struct Table {
        uint256 currentIndex;
        Column[] columns;
        string[][] rows;
    }

    // Core data structures
    struct SchemaEntry {
        uint256 index;
        bytes32 name;
    }
    struct TableEntry {
        uint256 index;
        bytes32 name;
        Table data;
    }
}