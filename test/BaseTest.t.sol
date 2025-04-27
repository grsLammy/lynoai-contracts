// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Test } from "forge-std/Test.sol";
import { LynoAI } from "../src/token/LynoAI.sol";

contract BaseTest is Test {
    LynoAI public sampleToken;
    address public owner;
    address public minter;
    address public nonOwner;

    error EnforcedPause();

    function test() public virtual {}

    function setUp() public virtual {
        owner = address(0x1);
        minter = address(0x2);
        nonOwner = address(0x6);

        vm.startBroadcast(owner);
        sampleToken = new LynoAI(owner, minter);
        vm.label(address(sampleToken), "sampleToken");

        vm.stopBroadcast();

        vm.prank(minter);
        sampleToken.mint(owner, 20000 ether);
    }
}
