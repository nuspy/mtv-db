pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestToken is ERC20 {
    string public constant name = "TestToken";
    string public constant symbol = "TTK";
    uint8 public constant decimals = 18;

    constructor() public {
        _mint(msg.sender, 250000000 * (10 ** uint256(decimals)));
    }
}