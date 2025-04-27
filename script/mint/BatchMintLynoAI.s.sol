// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { LynoAI } from "../../src/token/LynoAI.sol";

contract BatchMintLynoAI is Script {
    function test() public {}
    function run() public {
        // Get the private key of the minter
        uint256 minterPrivateKey = vm.envUint("MINTER_PRIVATE_KEY");

        // Get the token contract address
        address tokenAddress = vm.envAddress("LYNO_TOKEN_ADDRESS");

        // Replace with actual recipient addresses
        address[] memory recipients = new address[](3);
        recipients[0] = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
        recipients[1] = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
        recipients[2] = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;

        // Replace with actual token amounts to mint (in ETH)
        uint256[] memory amountsInEth = new uint256[](3);
        amountsInEth[0] = 1000;
        amountsInEth[1] = 2000;
        amountsInEth[2] = 3000;

        // Convert amounts to wei (with 18 decimals)
        uint256[] memory amountsInWei = new uint256[](3);
        for (uint256 i = 0; i < amountsInEth.length; i++) {
            amountsInWei[i] = amountsInEth[i] * 10 ** 18;
        }

        console.log("Preparing to batch mint to %s recipients", recipients.length);
        for (uint256 i = 0; i < recipients.length; i++) {
            console.log("Recipient %s: %s tokens", recipients[i], amountsInWei[i]);
        }

        // Start broadcasting transactions using the minter's private key
        vm.startBroadcast(minterPrivateKey);

        // Get the token contract instance
        LynoAI token = LynoAI(tokenAddress);

        // Batch mint tokens
        token.batchMint(recipients, amountsInWei);

        vm.stopBroadcast();

        console.log("Batch minting successful!");

        // Print final balances
        console.log("Final balances:");
        for (uint256 i = 0; i < recipients.length; i++) {
            console.log("%s: %s", recipients[i], token.balanceOf(recipients[i]));
        }
    }
}
