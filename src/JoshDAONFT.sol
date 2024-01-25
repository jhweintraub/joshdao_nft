pragma solidity ^0.8.19;

import { ERC721 } from "@solmate/tokens/ERC721.sol";
import { Ownable } from "@openzeppelin/access/Ownable.sol";
import { JoshVerifier } from "./JoshVerifier.sol";
import { MetadataHandler } from "./MetadataHandler.sol";
import { GMJToken } from "./GMJToken.sol";

contract JoshDAONFT is ERC721, Ownable {

    mapping(uint => uint) public mintingTime;
    mapping(uint => string) public identifier;
    mapping(uint => uint) public lastClaimTime;

    address public verifier;
    address public metadataHandler;
    GMJToken public gmjToken;

    uint public FEE = 50;
    uint public constant DENOM = 1000;

    uint minimumClaimDelay;
    uint public epochLength;

    event verifierMigration(address indexed oldVerifier, address indexed newVerifier);
    event metadataHandlerMigration(address indexed oldMetadataHandler, address indexed newMetadataHandler);
    event feeModified(uint indexed oldFee, uint indexed newFee);
    event minimumClaimDelayModified(uint indexed oldMinimumClaimDelay, uint indexed newMinimumClaimDelay);
    event epochLengthModified(uint indexed oldEpochLength, uint indexed newEpochLength);

    constructor(address _owner, address _verifier, address _gmjToken, address _metadataHandler) ERC721("JoshDAO", "JOSH") Ownable(_owner) {
        verifier = _verifier;
        metadataHandler = _metadataHandler;
        gmjToken = GMJToken(_gmjToken);
    
        minimumClaimDelay = 1 weeks;
        epochLength = 1 days;
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
        lastClaimTime[tokenId] = block.timestamp;
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

    function setFee(uint _fee) public onlyOwner {
        require(_fee < DENOM, "FEE CANNOT BE MORE THAN 100%");
        uint oldFee = FEE;
        FEE = _fee;
        emit feeModified(oldFee, _fee);
    }

    function setMinimumClaimDelay(uint _minimumClaimDelay) public onlyOwner {
        uint oldMinimumClaimDelay = minimumClaimDelay;
        minimumClaimDelay = _minimumClaimDelay;
        emit minimumClaimDelayModified(oldMinimumClaimDelay, _minimumClaimDelay);
    }

    function setEpochLength(uint _epochLength) public onlyOwner {
        uint oldEpochLength = epochLength;
        epochLength = _epochLength;
        emit epochLengthModified(oldEpochLength, _epochLength);
    }

    function mintGMJ(uint tokenId) external {
        //Restrict minting to once a week maximum
        require(block.timestamp - lastClaimTime[tokenId] > minimumClaimDelay, "CANNOT_MINT_YET");

        address nftOwner = ownerOf(tokenId);
        //Number of Days that has passed since last mint
        uint daysPassed = (block.timestamp - lastClaimTime[tokenId]) / 1 days;
        lastClaimTime[tokenId] = block.timestamp;

        //Calculate GMJ to mint
        uint amountBeforeFee = 1 ether * daysPassed;
        uint fee = amountBeforeFee * FEE / DENOM;
        uint amountAfterFee = amountBeforeFee - fee;

        //Mint GMJ
        gmjToken.mint(nftOwner, amountAfterFee);
        gmjToken.mint(owner(), fee);
    }
}
