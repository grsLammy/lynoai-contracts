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

    function setUp() public virtual {
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

contract BatchMintTest is LynoAITest {
    // Define test addresses and amounts
    address[] recipients;
    uint256[] amounts;
    address[] invalidRecipients;
    uint256[] invalidAmounts;
    uint256[] mismatchedAmounts;

    function setUp() public override {
        super.setUp();

        // Initialize valid recipients and amounts
        recipients = new address[](3);
        recipients[0] = address(0x100);
        recipients[1] = address(0x101);
        recipients[2] = address(0x102);

        amounts = new uint256[](3);
        amounts[0] = 100 ether;
        amounts[1] = 200 ether;
        amounts[2] = 300 ether;

        // Initialize invalid data for testing
        invalidRecipients = new address[](3);
        invalidRecipients[0] = address(0x100);
        invalidRecipients[1] = address(0); // Zero address
        invalidRecipients[2] = address(0x102);

        invalidAmounts = new uint256[](3);
        invalidAmounts[0] = 100 ether;
        invalidAmounts[1] = 0; // Zero amount
        invalidAmounts[2] = 300 ether;

        mismatchedAmounts = new uint256[](2); // Different length
        mismatchedAmounts[0] = 100 ether;
        mismatchedAmounts[1] = 200 ether;
    }

    function test_BatchMint_MinterMint_Succeeds() external {
        // Mint tokens as the minter
        vm.prank(minter);
        token.batchMint(recipients, amounts);

        // Check balances for all recipients
        assertEq(token.balanceOf(recipients[0]), amounts[0]);
        assertEq(token.balanceOf(recipients[1]), amounts[1]);
        assertEq(token.balanceOf(recipients[2]), amounts[2]);

        // Check total supply
        uint256 totalMinted = amounts[0] + amounts[1] + amounts[2];
        assertEq(token.totalSupply(), totalMinted);
    }

    function test_BatchMint_SingleRecipient_Succeeds() external {
        // Test with a single recipient
        address[] memory singleRecipient = new address[](1);
        singleRecipient[0] = address(0x500);

        uint256[] memory singleAmount = new uint256[](1);
        singleAmount[0] = 555 ether;

        vm.prank(minter);
        token.batchMint(singleRecipient, singleAmount);

        assertEq(token.balanceOf(singleRecipient[0]), singleAmount[0]);
        assertEq(token.totalSupply(), singleAmount[0]);
    }

    function test_BatchMint_EmptyArrays_Succeeds() external {
        // Test with empty arrays (should do nothing)
        address[] memory emptyRecipients = new address[](0);
        uint256[] memory emptyAmounts = new uint256[](0);

        vm.prank(minter);
        token.batchMint(emptyRecipients, emptyAmounts);

        assertEq(token.totalSupply(), 0);
    }

    function test_BatchMint_LargeNumberOfRecipients_Succeeds() external {
        // Test with a large number of recipients (10)
        address[] memory largeRecipients = new address[](10);
        uint256[] memory largeAmounts = new uint256[](10);

        uint256 totalExpectedMint = 0;

        for (uint256 i = 0; i < 10; i++) {
            largeRecipients[i] = address(uint160(0x1000 + i));
            largeAmounts[i] = (i + 1) * 100 ether;
            totalExpectedMint += largeAmounts[i];
        }

        vm.prank(minter);
        token.batchMint(largeRecipients, largeAmounts);

        for (uint256 i = 0; i < 10; i++) {
            assertEq(token.balanceOf(largeRecipients[i]), largeAmounts[i]);
        }

        assertEq(token.totalSupply(), totalExpectedMint);
    }

    function test_BatchMint_MultipleBatches_Succeeds() external {
        // Test minting multiple batches
        vm.startPrank(minter);

        // First batch
        token.batchMint(recipients, amounts);

        // Second batch (different recipients)
        address[] memory secondBatchRecipients = new address[](2);
        secondBatchRecipients[0] = address(0x200);
        secondBatchRecipients[1] = address(0x201);

        uint256[] memory secondBatchAmounts = new uint256[](2);
        secondBatchAmounts[0] = 400 ether;
        secondBatchAmounts[1] = 500 ether;

        token.batchMint(secondBatchRecipients, secondBatchAmounts);

        vm.stopPrank();

        // Check all balances
        assertEq(token.balanceOf(recipients[0]), amounts[0]);
        assertEq(token.balanceOf(recipients[1]), amounts[1]);
        assertEq(token.balanceOf(recipients[2]), amounts[2]);
        assertEq(token.balanceOf(secondBatchRecipients[0]), secondBatchAmounts[0]);
        assertEq(token.balanceOf(secondBatchRecipients[1]), secondBatchAmounts[1]);

        // Check total supply
        uint256 totalMinted = amounts[0] + amounts[1] + amounts[2] + secondBatchAmounts[0] + secondBatchAmounts[1];
        assertEq(token.totalSupply(), totalMinted);
    }

    function test_BatchMint_MintToSameAddressMultipleTimes_Succeeds() external {
        // Create arrays with the same recipient multiple times
        address[] memory repeatedRecipients = new address[](3);
        repeatedRecipients[0] = address(0x300);
        repeatedRecipients[1] = address(0x300); // Same as first
        repeatedRecipients[2] = address(0x300); // Same as first

        uint256[] memory repeatedAmounts = new uint256[](3);
        repeatedAmounts[0] = 100 ether;
        repeatedAmounts[1] = 200 ether;
        repeatedAmounts[2] = 300 ether;

        vm.prank(minter);
        token.batchMint(repeatedRecipients, repeatedAmounts);

        // The balance should be the sum of all amounts
        assertEq(token.balanceOf(address(0x300)), 600 ether);
        assertEq(token.totalSupply(), 600 ether);
    }

    function test_BatchMint_ExceedCap_Reverts() external {
        // Try to mint more than the cap
        address[] memory capRecipients = new address[](1);
        capRecipients[0] = address(0x400);

        uint256[] memory capExceedingAmounts = new uint256[](1);
        capExceedingAmounts[0] = exceedCapAmount;

        vm.prank(minter);
        vm.expectRevert();
        token.batchMint(capRecipients, capExceedingAmounts);
    }

    function test_BatchMint_ArrayLengthMismatch_Reverts() external {
        vm.prank(minter);
        vm.expectRevert(LynoAI.ArrayLengthMismatch.selector);
        token.batchMint(recipients, mismatchedAmounts);
    }

    function test_BatchMint_ZeroAddress_Reverts() external {
        vm.prank(minter);
        vm.expectRevert(LynoAI.InvalidAddress.selector);
        token.batchMint(invalidRecipients, amounts);
    }

    function test_BatchMint_ZeroAmount_Reverts() external {
        vm.prank(minter);
        vm.expectRevert(LynoAI.InvalidAmount.selector);
        token.batchMint(recipients, invalidAmounts);
    }

    function test_BatchMint_NonMinterMint_Reverts() external {
        // When owner tries to batch mint (not the minter)
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSignature("UnauthorizedMinter(address)", owner));
        token.batchMint(recipients, amounts);

        // When charlie tries to batch mint (not the minter)
        vm.prank(charlie);
        vm.expectRevert(abi.encodeWithSignature("UnauthorizedMinter(address)", charlie));
        token.batchMint(recipients, amounts);
    }

    function test_BatchMint_WhenPaused_Reverts() external {
        // Pause the contract
        vm.prank(owner);
        token.pause();

        // Try to batch mint when paused
        vm.prank(minter);
        vm.expectRevert();
        token.batchMint(recipients, amounts);
    }

    function test_BatchMint_AfterUnpause_Succeeds() external {
        // Pause the contract
        vm.prank(owner);
        token.pause();

        // Unpause the contract
        vm.prank(owner);
        token.unpause();

        // Should be able to batch mint after unpausing
        vm.prank(minter);
        token.batchMint(recipients, amounts);

        // Check balances
        assertEq(token.balanceOf(recipients[0]), amounts[0]);
        assertEq(token.balanceOf(recipients[1]), amounts[1]);
        assertEq(token.balanceOf(recipients[2]), amounts[2]);
    }

    function test_BatchMint_AlmostReachingCap_Succeeds() external {
        // Mint tokens that approach but don't exceed the cap
        address[] memory capRecipients = new address[](1);
        capRecipients[0] = address(0x400);

        uint256[] memory largeAmounts = new uint256[](1);
        largeAmounts[0] = tokenCap - 1000 ether; // Just under the cap

        vm.prank(minter);
        token.batchMint(capRecipients, largeAmounts);

        assertEq(token.balanceOf(capRecipients[0]), largeAmounts[0]);
        assertEq(token.totalSupply(), largeAmounts[0]);
    }
}
