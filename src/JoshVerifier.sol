pragma solidity ^0.8.19;

import {Ownable} from "@openzeppelin/access/Ownable.sol";

contract JoshVerifier is Ownable {
    mapping(address => bool) public isVerified;

    constructor(address _owner) Ownable(_owner) {}

    function addVerified(address _verifier) public onlyOwner {
        isVerified[_verifier] = true;
    }

    function removeVerified(address _verifier) public onlyOwner {
        isVerified[_verifier] = false;
    }

    function batchModifyVerified(address[] memory users, bool[] memory designations) external onlyOwner {
        require(users.length == designations.length, "Arrays not the same length");
        for(uint x = 0; x < users.length; x++) {
            isVerified[users[x]] = designations[x];
        }
    }
}
