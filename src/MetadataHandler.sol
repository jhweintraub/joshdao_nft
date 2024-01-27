pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/interfaces/IERC20.sol";
import {IERC721} from "@openzeppelin/interfaces/IERC721.sol";
import {Ownable} from "@openzeppelin/access/Ownable.sol";

contract MetadataHandler is Ownable {
    IERC20 public immutable GMJToken;
    IERC721 public JoshDAONFT;

    constructor(address _GMJToken) Ownable(msg.sender) {
        GMJToken = IERC20(_GMJToken);
    }

    function tokenURI(uint256 id) public view virtual returns (string memory) {
        address tokenOwner = JoshDAONFT.ownerOf(id);
        uint256 balance = GMJToken.balanceOf(tokenOwner);

        return "TODO";
    }

    function setNFT(address _nft) external onlyOwner {
        require(address(JoshDAONFT) == address(0));

        JoshDAONFT = IERC721(_nft);
    }
}
