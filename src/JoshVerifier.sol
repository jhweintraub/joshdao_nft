pragma solidity ^0.8.19;

import { Ownable } from "@openzeppelin/access/Ownable.sol";

contract JoshVerifier is Ownable {
    mapping(address => bool) public isVerified;

    constructor(address _owner) Ownable(_owner) {}

    function addVerifier(address _verifier) public onlyOwner {
        isVerified[_verifier] = true;
    }

    function removeVerifier(address _verifier) public onlyOwner {
        isVerified[_verifier] = false;
    }
}