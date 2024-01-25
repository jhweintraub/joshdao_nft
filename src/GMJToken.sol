pragma solidity ^0.8.19;

import { ERC20 } from "@solmate/tokens/ERC20.sol";
import { Ownable } from "@openzeppelin/access/Ownable.sol";
import { JoshDAONFT } from "./JoshDAONFT.sol";

contract GMJToken is ERC20, Ownable {
    constructor(address _owner) ERC20("GMJ", "GMJ", 18) Ownable(_owner) {
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}