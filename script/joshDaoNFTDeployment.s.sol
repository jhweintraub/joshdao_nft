pragma solidity ^0.8.19;

import { JoshDAONFT } from "src/JoshDAONFT.sol";
import { JoshVerifier } from "src/JoshVerifier.sol";
import { GMJToken } from "src/GMJToken.sol";
import { MetadataHandler } from "src/MetadataHandler.sol";

import { Script } from "forge-std/Script.sol";

contract JoshDAONFTDeployment is Script {

    address deployer;
    address multisig = address(0xdead);

    JoshDAONFT public nft;
    JoshVerifier public verifier;
    GMJToken public gmj;
    MetadataHandler public metadataHandler;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        deployer = vm.rememberKey(deployerPrivateKey);

        vm.startBroadcast(deployer);

        gmj = new GMJToken(deployer);
        verifier = new JoshVerifier(multisig);
        metadataHandler = new MetadataHandler(address(gmj));
        nft = new JoshDAONFT(multisig, address(verifier), address(gmj), address (metadataHandler));

        metadataHandler.setNFT(address(nft));
        metadataHandler.transferOwnership(multisig);

        //Transfer minting permissioons to the NFT contract
        gmj.transferOwnership(address(nft));


        vm.stopBroadcast(); 

        require(gmj.owner() == address(nft), "GMJ ownership not transferred to NFT contract");
        require(verifier.owner() == multisig, "Verifier ownership not transferred to multisig");
        require(metadataHandler.owner() == multisig, "MetadataHandler ownership not transferred to multisig");
        require(nft.owner() == multisig, "NFT ownership not transferred to multisig");
    }



}