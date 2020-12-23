pragma solidity ^0.6.0;

import "./Database.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract DatabaseFactory is Ownable {
    /** @dev SafeMath library */
    using SafeMath for uint256;

    /** @dev eMTV token address */
    address public EMTV_TOKEN_ADDRESS = 0x07a7ED332c595B53a317AfCEE50733Af571475e7;

    /** @dev Action prices */
    uint256 public UpdatePrice = 1 ether;
    uint256 public DropTablePrice = 1 ether;
    uint256 public InsertIntoPrice = 1 ether;
    uint256 public DeleteFromPrice = 1 ether;
    uint256 public CreateTablePrice = 1 ether;
    uint256 public CreateDatabasePrice = 1 ether;

    /**
     * @dev Created databases
     */
    mapping(address => address[]) public databaseAddresses;
    mapping(address => bytes32[]) public databaseNames;

    /**
     * @dev Used to check for duplicated databases' names
     */
    mapping(address => mapping(bytes32 => bool)) private databaseUsedNames;

    /**
     * @dev Returns the databases owned by the requested address
     * @return _addresses The database addresses list
     * @return _names The database names list
     */
    function databases(address _owner) external returns (address[] memory _addresses, bytes32[] memory _names) {
        return (databaseAddresses[_owner], databaseNames[_owner]);
    }

    /**
     * @dev Creates a new database instance
     * @return _database The newly created contract
     */
    function create(bytes32 _name) external returns (address _database) {
        return _create(_name, msg.sender);
    }

    /**
     * @dev Creates a new database instance using tokens from another account
     * @return _database The newly created contract
     */
    function createFrom(bytes32 _name, address _from) external returns (address _database) {
        return _create(_name, _from);
    }

    /**
     * @dev Withdraws all eMTVs to an address
     */
    function withdraw(address _to) external onlyOwner {
        ERC20 token = ERC20(EMTV_TOKEN_ADDRESS);

        token.transfer(_to, token.balanceOf(address(this)));
    }

    /**
     * @dev Updates the price to update a row
     */
    function updateUpdatePrice(uint256 _newPrice) external onlyOwner {
        UpdatePrice = _newPrice;

        emit UpdatePriceUpdated(_newPrice);
    }

    /**
     * @dev Updates the price to drop a table
     */
    function updateDropTablePrice(uint256 _newPrice) external onlyOwner {
        DropTablePrice = _newPrice;

        emit DropTablePriceUpdated(_newPrice);
    }

    /**
     * @dev Updates the price to insert a row
     */
    function updateInsertIntoPrice(uint256 _newPrice) external onlyOwner {
        InsertIntoPrice = _newPrice;

        emit InsertIntoPriceUpdated(_newPrice);
    }

    /**
     * @dev Updates the price to delete a row
     */
    function updateDeleteFromPrice(uint256 _newPrice) external onlyOwner {
        DeleteFromPrice = _newPrice;

        emit DeleteFromPriceUpdated(_newPrice);
    }

    /**
     * @dev Updates the price to delete a row
     */
    function updateCreateTablePrice(uint256 _newPrice) external onlyOwner {
        CreateTablePrice = _newPrice;

        emit CreateTablePriceUpdated(_newPrice);
    }

    /**
     * @dev Updates the price to create a new Database
     */
    function updateCreateDatabasePrice(uint256 _newPrice) external onlyOwner {
        CreateDatabasePrice = _newPrice;

        emit CreateDatabasePriceUpdated(_newPrice);
    }

    /**
     * @dev Update the token address. This is here only for debugging porpuses!
     */
    function updateTokenAddress(address _newAddress) external onlyOwner {
        EMTV_TOKEN_ADDRESS = _newAddress;

        emit TokenAddressUpdated(_newAddress);
    }

    /**
     * @dev Checks if an address can make a purchase
     */
    function canPurchase(address _from, uint256 _price) public view returns (bool _canPurchase) {
        ERC20 token = ERC20(EMTV_TOKEN_ADDRESS);
        uint256 balance = token.balanceOf(_from);

        return balance.sub(_price) >= 0;
    }

    function _create(bytes32 _name, address _from) internal returns (address _database) {
        require(_name.length > 0, "A database must have a name");
        require(_from != address(0x0), "Invalid owner address");
        require(databaseUsedNames[_from][_name] == false, "Duplicate database name");

        ERC20 token = ERC20(EMTV_TOKEN_ADDRESS);
        uint256 balance = token.balanceOf(_from);

        require(balance.sub(CreateDatabasePrice) >= 0, "Not enough tokens to create a new database");

        bool result = token.transferFrom(_from, address(this), CreateDatabasePrice);

        require(result, "Transfer returned false");

        Database db = new Database(address(this), _from);
        address dbAddress = address(db);

        databaseUsedNames[_from][_name] = true;

        databaseNames[_from].push(_name);
        databaseAddresses[_from].push(dbAddress);

        emit DatabaseCreated(_name, _from, address(db));

        return address(db);
    }

    event DatabaseCreated(bytes32 _name, address _by, address _contract);
    event TokenAddressUpdated(address _newAddress);

    event UpdatePriceUpdated(uint256 _newPrice);
    event DropTablePriceUpdated(uint256 _newPrice);
    event InsertIntoPriceUpdated(uint256 _newPrice);
    event DeleteFromPriceUpdated(uint256 _newPrice);
    event CreateTablePriceUpdated(uint256 _newPrice);
    event CreateDatabasePriceUpdated(uint256 _newPrice);
}
