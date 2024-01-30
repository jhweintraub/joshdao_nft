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
        vm.createSelectFork("optimism");

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

        vm.expectRevert(bytes("RECIPIENT_NOT_VERIFIED"));
        nft.mint(bob, tokenId, "HI");

        //Mint to Alice and Unlock it
        nft.mint(alice, tokenId, "HI");
        nft.unlock(tokenId);

        vm.stopPrank();

        assertEq(nft.ownerOf(tokenId), alice, "Alice not the owner");

        assertEq(nft.mintingTime(tokenId), block.timestamp, "minting time incorrect");
        assertEq(nft.lastClaimTime(tokenId), block.timestamp, "last claim time incorrects");

        hoax(alice, alice);
        vm.expectRevert(bytes("RECIPIENT_NOT_VERIFIED"));
        nft.transferFrom(alice, bob, tokenId);

        startHoax(multisig, multisig);
        verifier.addVerified(bob);
        vm.stopPrank();

        hoax(alice, alice);
        nft.transferFrom(alice, bob, tokenId);

        assertEq(nft.ownerOf(tokenId), bob, "nft owner should be bob");
    }

    function testBatchMint() public {
        address[] memory users = new address[](2);
        users[0] = alice;
        users[1] = bob;

        bool[] memory designations = new bool[](2);
        designations[0] = true;
        designations[1] = true;

        uint[] memory tokenIds = new uint[](2);
        tokenIds[0] = 0;
        tokenIds[1] = 1;

        string[] memory identifiers = new string[](2);
        identifiers[0] = "test";
        identifiers[1] = "testing";

        startHoax(multisig, multisig);
        verifier.batchModifyVerified(users, designations);

        nft.batchMint(users, tokenIds, identifiers);
        assertEq(nft.ownerOf(0), alice, "tokenId 0 owner should be alice");
        assertEq(nft.ownerOf(1), bob, "tokenId 1 owner should be bob");
    
        vm.expectRevert(bytes("Arrays not same length"));
        nft.batchMint(users, tokenIds, new string[](3));
    }

    function testGMJMint() public {
        uint256 tokenId = 0;

        startHoax(multisig, multisig);
        verifier.addVerified(alice);
        nft.mint(alice, tokenId, "HI");

        uint daysElapsed = 7;
        changePrank(alice, alice);

        vm.expectRevert(bytes("CANNOT_MINT_YET"));
        nft.claimGMJ(tokenId);

        skip(1 weeks);
        nft.claimGMJ(tokenId);

        uint fee = (daysElapsed * 1e18) * nft.FEE() / nft.DENOM();
        uint amountAfterFee = (daysElapsed * 1e18) - fee;

        assertEq(gmj.balanceOf(alice), amountAfterFee, "Alice amount after fee incorrect");
        assertEq(gmj.balanceOf(multisig), fee, "fee recipient balance incorrect");
        assertEq(gmj.totalSupply(), amountAfterFee + fee, "total supply of GMJ Incorrect");
    }

    function testMigrations() public {
        uint tokenId = 0;

        JoshVerifier newVerifier = new JoshVerifier(multisig);
        MetadataHandler newMetadataHandler = new MetadataHandler(address(gmj));

        startHoax(multisig, multisig);
        nft.setVerifier(address(newVerifier));//Set verifier
        nft.setMetadataHandler(address(newMetadataHandler));//Set metadata handler
        
        uint denom = nft.DENOM();
        vm.expectRevert(bytes("FEE CANNOT BE MORE THAN 100%"));
        nft.setFee(denom + 1);//Set fee >100%

        nft.setFee(100);//Set fee to 10%
        nft.setMinimumClaimDelay(2 weeks);//Set minimum claim delay to 2 weeks
        nft.setEpochLength(2 days);//Set epoch length to 2 days
        vm.stopPrank();

        assertEq(nft.verifier(), address(newVerifier), "verifier not migrated");
        assertEq(nft.metadataHandler(), address(newMetadataHandler), "metadata handler not migrated");
        assertEq(nft.FEE(), 100, "fee not migrated");
        assertEq(nft.minimumClaimDelay(), 2 weeks, "minimum claim delay not migrated");
        assertEq(nft.epochLength(), 2 days, "epoch length not migrated");

        //Mint an NFT To Alice to test reverting without permissions
        startHoax(multisig, multisig);
        newVerifier.addVerified(alice);
        nft.mint(alice, tokenId, "HI");
    
        //Should revert name change because Bob is not the owner
        changePrank(bob, bob);
        vm.expectRevert(bytes("NOT_OWNER"));
        nft.setTokenName(tokenId, "Howdy Partner");

        //Should Revert on burning because Bob is not the owner
        vm.expectRevert(bytes("NOT_OWNER"));
        nft.burn(tokenId);

        //Test changing the identifier
        changePrank(alice, alice);
        nft.setTokenName(tokenId, "My name is Alice");
        assertEq(nft.identifier(tokenId), "My name is Alice", "identifier not set correctly");

        //Test changing the identifier as the owner to prevent profanity
        changePrank(multisig, multisig);
        nft.changeIdentifier(tokenId);
        assertEq(nft.identifier(tokenId), "I AM JOSH", "identifier not changed correctly");
    
        //Test external facing NFT Burn Function
        changePrank(alice, alice);
        nft.burn(tokenId);
        assertEq(nft.balanceOf(alice), 0, "Alice balance should be 0");
    
        //Test removing a verified user
        changePrank(multisig, multisig);
        verifier.removeVerified(alice);
        assertTrue(!verifier.isVerified(alice), "Alice should not be verified");
    
        //Test batch modifying verified users
        address[] memory users = new address[](2);
        bool[] memory designations = new bool[](3);
        vm.expectRevert(bytes("Arrays not the same length"));
        verifier.batchModifyVerified(users, designations);
    }

    function testTransferWithLock() public {
        uint tokenId = 0;

        startHoax(multisig, multisig);
        verifier.addVerified(alice);
        verifier.addVerified(bob);
        
        nft.mint(alice, tokenId, "HI");

        nft.lock(tokenId);
        
        changePrank(alice, alice);
        vm.expectRevert(bytes("LOCKED SOULBOUND NFT CANNOT BE TRANSFERED"));
        nft.transferFrom(alice, bob, tokenId);

        changePrank(multisig, multisig);
        nft.unlock(tokenId);

        changePrank(alice, alice);
        nft.transferFrom(alice, bob, tokenId);
        assertEq(nft.ownerOf(tokenId), bob, "Bob should be the owner of the NFT");
    }
}
