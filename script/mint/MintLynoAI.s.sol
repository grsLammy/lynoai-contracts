// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { LynoAI } from "../../src/token/LynoAI.sol";

contract MintLynoAI is Script {
    function test() public {}
    function run() public {
        // Get the private key of the minter
        uint256 minterPrivateKey = vm.envUint("MINTER_PRIVATE_KEY");

        // Get the token contract address
        address tokenAddress = vm.envAddress("LYNO_TOKEN_ADDRESS");

        // Replace with actual recipient address and amount to mint
        address recipient = 0xSampleAddress;
        uint256 amountInEth = 1000;

        // Convert mint amount (add 18 decimals)
        uint256 amountInWei = amountInEth * 10 ** 18;

        console.log("Minting %s tokens to %s", amountInWei, recipient);

        // Start broadcasting transactions using the minter's private key
        vm.startBroadcast(minterPrivateKey);

        // Get the token contract instance
        LynoAI token = LynoAI(tokenAddress);

        // Mint tokens
        token.mint(recipient, amountInWei);

        vm.stopBroadcast();

        console.log("Minting successful!");
        console.log("New balance of recipient: %s", token.balanceOf(recipient));
    }
}
