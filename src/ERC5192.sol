pragma solidity ^0.8.19;

import {IERC5192} from "./interfaces/IERC5192.sol";
import {Ownable} from "@openzeppelin/access/Ownable.sol";

abstract contract ERC5192 is IERC5192, Ownable {
    mapping(uint256 => bool locked) public override locked;

    function lock(uint256 tokenId) external onlyOwner {
        locked[tokenId] = true;
        emit Locked(tokenId);
    }

    function unlock(uint256 tokenId) external onlyOwner {
        locked[tokenId] = false;
        emit Unlocked(tokenId);
    }
}
