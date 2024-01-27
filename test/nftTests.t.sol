pragma solidity >=0.8.19;

import {GMJToken} from "src/GMJToken.sol";
import {JoshDAONFT} from "src/JoshDAONFT.sol";
import {JoshVerifier} from "src/JoshVerifier.sol";
import {MetadataHandler} from "src/MetadataHandler.sol";

import {Test} from "forge-std/Test.sol";
import {console2 as console} from "forge-std/console2.sol";

contract nftTests is Test {
    GMJToken public gmj;
    JoshDAONFT public nft;
    JoshVerifier public verifier;
    MetadataHandler public metadataHandler;

    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public charlie = makeAddr("charlie");
    address public multisig = makeAddr("multisig");

    constructor() {
        vm.createSelectFork("arbitrum");

        gmj = new GMJToken(multisig);
        verifier = new JoshVerifier(multisig);
        metadataHandler = new MetadataHandler(address(gmj));
        nft = new JoshDAONFT(multisig, address(verifier), address(gmj), address (metadataHandler));

        metadataHandler.setNFT(address(nft));
        hoax(multisig, multisig);

        //Transfer minting permissioons to the NFT contract
        gmj.transferOwnership(address(nft));
    }

    function testMintAndTransfer() public {
        uint256 tokenId = 1;

        startHoax(multisig, multisig);
        verifier.addVerified(alice);
        nft.mint(alice, tokenId, "HI");

        vm.stopPrank();

        assertTrue(nft.locked(tokenId), "nft should be soulbound");
        assertEq(nft.ownerOf(tokenId), alice, "Alice not the owner");

        assertEq(nft.mintingTime(tokenId), block.timestamp, "minting time incorrect");
        assertEq(nft.lastClaimTime(tokenId), block.timestamp, "last claim time incorrects");

        hoax(alice, alice);
        vm.expectRevert(bytes("SOULBOUND NFT CANNOT BE TRANSFERED"));
        nft.transferFrom(alice, bob, tokenId);

        startHoax(multisig, multisig);
        verifier.addVerified(bob);
        nft.unlock(tokenId);
        vm.stopPrank();

        hoax(alice, alice);
        nft.transferFrom(alice, bob, tokenId);

        assertEq(nft.ownerOf(tokenId), bob, "nft owner should be bob");

        startHoax(bob, bob);
        vm.expectRevert(bytes("SOULBOUND NFT CANNOT BE TRANSFERED"));
        nft.transferFrom(bob, charlie, tokenId);
    }

    function testBatchMint() public {
        address[] memory users = address[](2);
        users[0] = alice;
        users[1] = bob;

        bool[] memory designations = address[](2);
        designations[0] = true;
        designations[1] = true;

        startHoax(multisig, multisig);
        verifier.batchModifyVerified()
    }
}
