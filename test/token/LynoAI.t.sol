// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Test } from "forge-std/Test.sol";
import { LynoAI } from "../../src/token/LynoAI.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC20Capped } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";
import { console } from "forge-std/console.sol";

contract LynoAITest is Test {
    LynoAI token;

    address owner = address(0x1);
    address minter = address(0x2);
    address charlie = address(0x6);
    address newMinter = address(0x7);
    address newOwner = address(0x8);

    string tokenName = "Lyno AI";
    string symbol = "LYNO";
    uint256 tokenDecimals = 18;
    uint256 tokenCap = 500_000_000 ether;

    uint256 amount = 1000 ether;
    uint256 exceedCapAmount = 500_000_000_000 ether;

    event MinterChanged(address indexed oldMinter, address indexed newMinter);

    function test() public {}

    function setUp() external {
        owner = address(0x1);
        minter = address(0x2);
        charlie = address(0x6);
        newMinter = address(0x7);

        vm.prank(owner);
        token = new LynoAI(owner, minter);
        vm.label(address(token), "token");
    }
}

contract TokenDeploymentTest is LynoAITest {
    function test_Deployment_Succeeds() external view {
        assertEq(token.owner(), owner);
        assertEq(token.name(), tokenName);
        assertEq(token.symbol(), symbol);
        assertEq(token.decimals(), tokenDecimals);
        assertEq(token.totalSupply(), 0);
        assertEq(token.cap(), tokenCap);
        assertEq(token.paused(), false);
        assertEq(token.pendingOwner(), address(0));
    }

    function test_Deployment_ZeroAddress_Reverts() external {
        // Zero owner address reverts with Ownable error
        vm.expectRevert(abi.encodeWithSignature("OwnableInvalidOwner(address)", address(0)));
        new LynoAI(address(0), minter);

        // Zero minter address reverts with our custom error
        vm.expectRevert(LynoAI.InvalidAddress.selector);
        new LynoAI(owner, address(0));

        // Both zero addresses will revert with the first error (Ownable)
        vm.expectRevert(abi.encodeWithSignature("OwnableInvalidOwner(address)", address(0)));
        new LynoAI(address(0), address(0));
    }
}

contract MintTest is LynoAITest {
    function test_Mint_MinterMint_Succeeds() external {
        vm.prank(minter);
        token.mint(owner, amount);
        assertEq(token.balanceOf(owner), amount);
    }

    function test_Mint_ExceedCap_Reverts() external {
        vm.prank(minter);
        vm.expectRevert();
        token.mint(owner, exceedCapAmount);
    }

    function test_Mint_NonMinterMint_Reverts() public {
        // When owner tries to mint (not the minter)
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSignature("UnauthorizedMinter(address)", owner));
        token.mint(owner, amount);

        // When charlie tries to mint (not the minter)
        vm.prank(charlie);
        vm.expectRevert(abi.encodeWithSignature("UnauthorizedMinter(address)", charlie));
        token.mint(owner, amount);
    }

    function test_Mint_ZeroAmount_Reverts() external {
        uint256 amount = 0;
        vm.prank(minter);
        vm.expectRevert(LynoAI.InvalidAmount.selector);
        token.mint(owner, amount);
    }

    function test_Mint_ZeroAddress_Reverts() external {
        vm.prank(minter);
        vm.expectRevert();
        token.mint(address(0), amount);
    }
}

contract SetMinterTest is LynoAITest {
    function test_SetMinter_OwnerSet_Succeeds() external {
        vm.prank(owner);
        vm.expectEmit(true, true, false, true);
        emit MinterChanged(minter, newMinter);
        token.setMinter(newMinter);
        vm.prank(newMinter);
        token.mint(owner, 1000 ether);
        assertEq(token.balanceOf(owner), 1000 ether);
    }

    function test_SetMinter_NonOwnerSet_Reverts() external {
        vm.prank(minter);
        vm.expectRevert();
        token.setMinter(owner);

        vm.prank(charlie);
        vm.expectRevert();
        token.setMinter(charlie);
    }

    function test_SetMinter_ZeroAddress_Reverts() external {
        vm.prank(owner);
        vm.expectRevert(LynoAI.InvalidAddress.selector);
        token.setMinter(address(0));
    }

    function test_SetMinter_SameMinter_Reverts() external {
        vm.prank(owner);
        vm.expectRevert(LynoAI.InvalidAddress.selector);
        token.setMinter(minter);
    }
}

contract PauseTest is LynoAITest {
    function test_Pause_OwnerPause_Succeeds() external {
        vm.prank(owner);
        token.pause();
        assertEq(token.paused(), true);

        vm.prank(minter);
        vm.expectRevert();
        token.mint(owner, amount);
    }

    function test_Pause_NonOwnerPause_Reverts() external {
        vm.prank(charlie);
        vm.expectRevert();
        token.pause();

        vm.prank(minter);
        vm.expectRevert();
        token.pause();
    }

    function test_Pause_Mint_Reverts() external {
        vm.prank(owner);
        token.pause();

        vm.prank(minter);
        vm.expectRevert();
        token.mint(minter, amount);

        vm.prank(owner);
        vm.expectRevert();
        token.mint(owner, amount);

        vm.prank(charlie);
        vm.expectRevert();
        token.mint(owner, amount);
    }

    function test_Pause_Transfer_Reverts() external {
        vm.startBroadcast(minter);
        token.mint(owner, amount);
        token.mint(charlie, amount);
        vm.stopBroadcast();

        vm.prank(owner);
        token.pause();

        vm.prank(owner);
        vm.expectRevert();
        token.transfer(charlie, amount);

        vm.prank(charlie);
        vm.expectRevert();
        token.transfer(owner, amount);
    }
}

contract UnpauseTest is LynoAITest {
    function test_Unpaused_OwnerUnpause_Succeeds() external {
        vm.prank(owner);
        token.pause();
        assertEq(token.paused(), true);

        vm.prank(owner);
        token.unpause();
        assertEq(token.paused(), false);
    }

    function test_UnPaused_Mint_Succeeds() external {
        vm.prank(owner);
        token.pause();
        assertEq(token.paused(), true);

        vm.prank(owner);
        token.unpause();
        assertEq(token.paused(), false);

        vm.prank(minter);
        token.mint(charlie, amount);
        assertEq(token.balanceOf(charlie), amount);
    }

    function test_Unpaused_Transfer_Succeeds() external {
        vm.prank(owner);
        token.pause();
        assertEq(token.paused(), true);

        vm.prank(owner);
        token.unpause();
        assertEq(token.paused(), false);

        vm.prank(minter);
        token.mint(charlie, amount);
        assertEq(token.balanceOf(charlie), amount);

        vm.prank(charlie);
        token.transfer(owner, amount);
        assertEq(token.balanceOf(charlie), 0);
        assertEq(token.balanceOf(owner), amount);

        vm.prank(owner);
        token.transfer(charlie, amount);
        assertEq(token.balanceOf(owner), 0);
        assertEq(token.balanceOf(charlie), amount);
    }

    function test_Unpause_NonOwnerUnpause_Reverts() external {
        vm.prank(owner);
        token.pause();

        vm.prank(charlie);
        vm.expectRevert();
        token.unpause();

        vm.prank(minter);
        vm.expectRevert();
        token.unpause();
    }
}

contract OwnershipTest is LynoAITest {
    function test_Ownership_Transfer_Succeeds() external {
        vm.prank(owner);
        token.transferOwnership(newOwner);
        assertEq(token.owner(), owner);
        assertEq(token.pendingOwner(), newOwner);

        vm.prank(newOwner);
        token.acceptOwnership();
        assertEq(token.owner(), newOwner);
    }

    function test_Ownership_Renounce_Succeeds() external {
        vm.prank(owner);
        token.renounceOwnership();

        assertEq(token.owner(), address(0));
    }

    function test_Ownership_Transfer_Reverts() external {
        vm.prank(charlie);
        vm.expectRevert();
        token.transferOwnership(newOwner);
        assertEq(token.owner(), owner);

        vm.prank(minter);
        vm.expectRevert();
        token.transferOwnership(newOwner);
        assertEq(token.owner(), owner);

        vm.prank(charlie);
        vm.expectRevert();
        token.acceptOwnership();
        assertEq(token.owner(), owner);

        vm.prank(minter);
        vm.expectRevert();
        token.acceptOwnership();
        assertEq(token.owner(), owner);
    }

    function test_Ownership_Renounce_Reverts() external {
        vm.prank(charlie);
        vm.expectRevert();
        token.renounceOwnership();
        assertEq(token.owner(), owner);

        vm.prank(minter);
        vm.expectRevert();
        token.renounceOwnership();
        assertEq(token.owner(), owner);
    }
}
