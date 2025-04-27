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
    /// @param owner Initial owner address.
    /// @param minterAddress Address authorized to mint tokens.
    constructor(
        address owner,
        address minterAddress
    ) ERC20(_NAME, _SYMBOL) ERC20Capped(_TOTAL_SUPPLY_CAP) Ownable(owner) {
        if (owner == address(0) || minterAddress == address(0)) revert InvalidAddress();

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
