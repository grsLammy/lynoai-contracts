// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;
import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { LynoAI } from "../src/token/LynoAI.sol";

contract LynoAIScript is Script {
    function test() public {}
    function run() public {
        // Retrieve deployer's private key from environment variables
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Replace these with actual addresses or use environment variables
        address initialOwner = vm.envAddress("OWNER_ADDRESS");
        address minter = vm.envAddress("MINTER_ADDRESS");

        // Start broadcasting transactions using the deployer's private key
        vm.startBroadcast(deployerPrivateKey);

        // Deploy the contract (LynoAI)
        LynoAI lynoai = new LynoAI(initialOwner, minter);

        vm.stopBroadcast();

        console.log("Deployment successful!");
        console.log("LynoAI Contract Address: ", address(lynoai));
    }
}
