pragma solidity ^0.8.19;

import { ERC721 } from "@solmate/tokens/ERC721.sol";
import { Ownable } from "@openzeppelin/access/Ownable.sol";
import { JoshVerifier } from "./JoshVerifier.sol";
import { MetadataHandler } from "./MetadataHandler.sol";

contract JoshDAONFT is ERC721, Ownable {

    mapping(uint => uint) public mintingTime;
    mapping(uint => string) public identifier;

    address public verifier;
    address public metadataHandler;

    event verifierMigration(address indexed oldVerifier, address indexed newVerifier);
    event metadataHandlerMigration(address indexed oldMetadataHandler, address indexed newMetadataHandler);

    constructor(address _owner, address _verifier, address _metadataHandler) ERC721("JoshDAO", "JOSH") Ownable(_owner) {
        verifier = _verifier;
        metadataHandler = _metadataHandler;
    }

    //To turn it into a soulbound NFT just remove transfer ability
    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public override {
        require(to == address(0), "SOULBOUND NFT CANNOT BE TRANSFERED");
        super.transferFrom(from, to, id);
    }

    //Mint and Burn Function
    function burn(uint256 id) public {
        require(ownerOf(id) == msg.sender, "NOT_OWNER");
        _burn(id);
    }

    //Mint function with identifier
    function mint(address to, uint256 tokenId, string calldata _identifier) public onlyOwner {
        require(JoshVerifier(verifier).isVerified(to), "NOT_VERIFIED");
        _mint(to, tokenId);
        mintingTime[tokenId] = block.timestamp;
        identifier[tokenId] = _identifier;
    }

    //Get the URI of the NFT
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return MetadataHandler(metadataHandler).tokenURI(tokenId);
    }

    //Allow user to change the name displayed on their NFT
    function setTokenName(uint256 tokenId, string memory _name) public {
        require(ownerOf(tokenId) == msg.sender, "NOT_OWNER");
        identifier[tokenId] = _name;
    }

    //ADMIN FUNCTIONS TO CHANGE VERIFIER AND METADATA HANDLER
    function setMetadataHandler(address _metadataHandler) public onlyOwner {
        address oldMetadataHandler = metadataHandler;
        metadataHandler = _metadataHandler;
        emit metadataHandlerMigration(oldMetadataHandler, _metadataHandler);
    }

    function setVerifier(address _verifier) public onlyOwner {
        address oldVerifier = verifier;
        verifier = _verifier;
        emit verifierMigration(oldVerifier, _verifier);
    }

    //Admin function to prevent unnecessary profanity on NFTs
    function changeIdentifier(uint256 tokenId) public onlyOwner {
        identifier[tokenId] = "I AM JOSH";
    }
}
