// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { LynoAI } from "../../src/token/LynoAI.sol";

contract BatchMintFromJson is Script {
    function test() public {}
    function run() public {
        // Get the private key of the minter
        uint256 minterPrivateKey = vm.envUint("MINTER_PRIVATE_KEY");

        // Get the token contract address
        address tokenAddress = vm.envAddress("LYNO_TOKEN_ADDRESS");

        // Get the JSON file with recipients and amounts
        string memory json = vm.readFile("script/mint/mint_data.json");

        // Parse recipients and amounts from JSON
        address[] memory recipients = vm.parseJsonAddressArray(json, ".recipients");
        uint256[] memory amounts = vm.parseJsonUintArray(json, ".amounts");

        require(recipients.length == amounts.length, "length mismatch");

        console.log("Preparing to batch mint to %s recipients", recipients.length);
        for (uint256 i = 0; i < recipients.length; i++) {
            console.log("Recipient %s: %s tokens", recipients[i], amounts[i]);
        }

        // Start broadcasting transactions using the minter's private key
        vm.startBroadcast(minterPrivateKey);

        // Get the token contract instance
        LynoAI token = LynoAI(tokenAddress);

        // Batch mint tokens
        token.batchMint(recipients, amounts);

        vm.stopBroadcast();

        console.log("Batch minting successful!");

        // Print final balances
        console.log("Final balances:");
        for (uint256 i = 0; i < recipients.length; i++) {
            console.log("%s: %s", recipients[i], token.balanceOf(recipients[i]));
        }
    }
}
