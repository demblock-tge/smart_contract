pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Mintable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Pausable.sol";

contract CBToken is Ownable, ERC20Mintable, ERC20Pausable, ERC20Detailed {
    constructor(string memory _name, 
                string memory _symbol, 
                uint8 _decimals)
        ERC20Detailed(_name, _symbol, _decimals)
        public
    {
    }
}