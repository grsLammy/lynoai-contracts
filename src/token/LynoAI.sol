// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/// @title LynoAI ERC20 Token
/// @author LynoAI
/// @notice ERC20 token with capped supply, pausability, and ownership.
/// @dev Uses OpenZeppelin contracts for modularity and security.
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC20Capped } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Ownable2Step } from "@openzeppelin/contracts/access/Ownable2Step.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";

contract LynoAI is ERC20Capped, Pausable, Ownable2Step {
    /// @notice Thrown when an unauthorized address attempts to mint tokens.
    /// @param caller The address that attempted the unauthorized action.
    error UnauthorizedMinter(address caller);

    /// @notice Thrown when an invalid address is provided.
    error InvalidAddress();

    /// @notice Thrown when an invalid amount is provided.
    error InvalidAmount();

    /// @notice Thrown when arrays have different lengths.
    error ArrayLengthMismatch();

    string private constant _NAME = "Lyno AI";
    string private constant _SYMBOL = "LYNO";
    uint256 private constant _TOTAL_SUPPLY_CAP = 500_000_000 ether;

    /// @notice Address authorized to mint new tokens.
    address private _minter;

    /// @notice Emitted when the minter role is reassigned.
    /// @param oldMinter The address of the previous minter.
    /// @param newMinter The address of the new minter.
    event MinterChanged(address indexed oldMinter, address indexed newMinter);

    /// @notice Initializes the contract with core parameters.
    /// @param initialOwner Initial owner address.
    /// @param minterAddress Address authorized to mint tokens.
    constructor(
        address initialOwner,
        address minterAddress
    ) ERC20(_NAME, _SYMBOL) ERC20Capped(_TOTAL_SUPPLY_CAP) Ownable(initialOwner) {
        if (initialOwner == address(0) || minterAddress == address(0)) revert InvalidAddress();

        _minter = minterAddress;
    }

    /// @dev Restricts function access to the minter.
    modifier onlyMinter() {
        if (msg.sender != _minter) revert UnauthorizedMinter(msg.sender);
        _;
    }

    /// @notice Mints tokens to a specified address.
    /// @param to Recipient address.
    /// @param amount Number of tokens to mint.
    function mint(address to, uint256 amount) external onlyMinter whenNotPaused {
        if (amount == 0) revert InvalidAmount();
        _mint(to, amount);
    }

    /// @notice Mints tokens to multiple addresses in a single transaction.
    /// @param recipients Array of recipient addresses.
    /// @param amounts Array of token amounts to mint to each recipient.
    function batchMint(address[] calldata recipients, uint256[] calldata amounts) external onlyMinter whenNotPaused {
        // Check that the arrays have the same length
        if (recipients.length != amounts.length) revert ArrayLengthMismatch();

        // Process each mint operation
        for (uint256 i = 0; i < recipients.length; i++) {
            // Validate recipient address and amount
            if (recipients[i] == address(0)) revert InvalidAddress();
            if (amounts[i] == 0) revert InvalidAmount();

            // Mint tokens to the current recipient
            _mint(recipients[i], amounts[i]);
        }
    }

    /// @notice Updates the minter address.
    /// @param newMinter New minter address.
    function setMinter(address newMinter) external onlyOwner {
        if (newMinter == address(0)) revert InvalidAddress();
        if (newMinter == _minter) revert InvalidAddress();

        address oldMinter = _minter;
        _minter = newMinter;
        emit MinterChanged(oldMinter, newMinter);
    }

    /// @notice Pauses all transfers and minting operations.
    /// @dev Can only be called by the owner.
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Resumes token transfers and minting.
    /// @dev Can only be called by the owner.
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @dev Checks if contract is paused before allowing transfers and enforces the cap.
    function _update(address from, address to, uint256 amount) internal virtual override whenNotPaused {
        super._update(from, to, amount);
    }
}
