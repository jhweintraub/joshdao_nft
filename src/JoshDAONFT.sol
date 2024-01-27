pragma solidity ^0.8.19;

import {ERC721} from "@solmate/tokens/ERC721.sol";
import {Ownable} from "@openzeppelin/access/Ownable.sol";
import {JoshVerifier} from "./JoshVerifier.sol";
import {MetadataHandler} from "./MetadataHandler.sol";
import {GMJToken} from "./GMJToken.sol";

import {ERC5192} from "./ERC5192.sol";

import { console2 as console } from "forge-std/console2.sol";

contract JoshDAONFT is ERC721, Ownable, ERC5192 {
    mapping(uint256 => uint256) public mintingTime;
    mapping(uint256 => string) public identifier;
    mapping(uint256 => uint256) public lastClaimTime;

    address public verifier;
    address public metadataHandler;
    GMJToken public gmjToken;

    uint256 public FEE = 50;
    uint256 public constant DENOM = 1000;

    uint256 minimumClaimDelay;
    uint256 public epochLength;

    event verifierMigration(address indexed oldVerifier, address indexed newVerifier);
    event metadataHandlerMigration(address indexed oldMetadataHandler, address indexed newMetadataHandler);
    event feeModified(uint256 indexed oldFee, uint256 indexed newFee);
    event minimumClaimDelayModified(uint256 indexed oldMinimumClaimDelay, uint256 indexed newMinimumClaimDelay);
    event epochLengthModified(uint256 indexed oldEpochLength, uint256 indexed newEpochLength);

    constructor(address _owner, address _verifier, address _gmjToken, address _metadataHandler)
        ERC721("JoshDAO", "JOSH")
        Ownable(_owner)
    {
        verifier = _verifier;
        metadataHandler = _metadataHandler;
        gmjToken = GMJToken(_gmjToken);

        minimumClaimDelay = 1 weeks;
        epochLength = 1 days;
    }

    //To turn it into a soulbound NFT just remove transfer ability
    function transferFrom(address from, address to, uint256 id) public override {
        require(!locked[id] && JoshVerifier(verifier).isVerified(to), "SOULBOUND NFT CANNOT BE TRANSFERED");
        super.transferFrom(from, to, id);
    }

    //Mint and Burn Function
    function burn(uint256 id) public {
        require(ownerOf(id) == msg.sender, "NOT_OWNER");
        _burn(id);

        emit Unlocked(id);
    }

    function batchMint(address[] memory recipients, uint256[] memory tokenIds, string[] memory _identifiers)
        external
        onlyOwner
    {
        require(recipients.length == tokenIds.length && tokenIds.length == _identifiers.length, "Arrays not same length");
        for (uint256 x = 0; x < recipients.length; x++) {
            mint(recipients[x], tokenIds[x], _identifiers[x]);
        }
    }

    //Mint function with identifier
    function mint(address to, uint256 tokenId, string memory _identifier) public onlyOwner {
        require(JoshVerifier(verifier).isVerified(to), "NOT_VERIFIED");
        _mint(to, tokenId);
        mintingTime[tokenId] = block.timestamp;
        lastClaimTime[tokenId] = block.timestamp;
        identifier[tokenId] = _identifier;

        locked[tokenId] = true;

        emit Locked(tokenId);
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

    function setFee(uint256 _fee) public onlyOwner {
        require(_fee < DENOM, "FEE CANNOT BE MORE THAN 100%");
        uint256 oldFee = FEE;
        FEE = _fee;
        emit feeModified(oldFee, _fee);
    }

    function setMinimumClaimDelay(uint256 _minimumClaimDelay) public onlyOwner {
        uint256 oldMinimumClaimDelay = minimumClaimDelay;
        minimumClaimDelay = _minimumClaimDelay;
        emit minimumClaimDelayModified(oldMinimumClaimDelay, _minimumClaimDelay);
    }

    function setEpochLength(uint256 _epochLength) public onlyOwner {
        uint256 oldEpochLength = epochLength;
        epochLength = _epochLength;
        emit epochLengthModified(oldEpochLength, _epochLength);
    }

    function claimGMJ(uint256 tokenId) external {
        //Restrict minting to once a week maximum
        require(block.timestamp - lastClaimTime[tokenId] >=  minimumClaimDelay, "CANNOT_MINT_YET");

        address nftOwner = ownerOf(tokenId);
        //Number of Days that has passed since last mint
        uint256 daysPassed = (block.timestamp - lastClaimTime[tokenId]) / 1 days;
        lastClaimTime[tokenId] = block.timestamp;

        //Calculate GMJ to mint
        uint256 amountBeforeFee = 1 ether * daysPassed;
        uint256 fee = amountBeforeFee * FEE / DENOM;
        uint256 amountAfterFee = amountBeforeFee - fee;

        //Mint GMJ
        gmjToken.mint(nftOwner, amountAfterFee);
        gmjToken.mint(owner(), fee);
    }
}
