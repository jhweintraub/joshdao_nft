pragma solidity ^0.8.19;

import { IERC20 } from "@openzeppelin/interfaces/IERC20.sol";
import { IERC721 } from "@openzeppelin/interfaces/IERC721.sol";

contract MetadataHandler {

    IERC20 public immutable GMJToken;
    IERC721 public immutable JoshDAONFT;

    constructor(address _GMJToken, address _JoshDAONFT) {
        GMJToken = IERC20(_GMJToken);
        JoshDAONFT = IERC721(_JoshDAONFT);
    }

    function tokenURI(uint256 id) public view virtual returns (string memory) {
        address tokenOwner = JoshDAONFT.ownerOf(id);
        uint256 balance = GMJToken.balanceOf(tokenOwner);

        return "TODO";
    }
}