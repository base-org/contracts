// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

/// @title FeeVault
/// @notice The FeeVault contract is intended to:
///         1. Be upgraded to by the Base FeeVault contracts
///         2. Set `totalProcessed` to the correct value
///         3. Be upgraded from to back to Optimism's FeeVault
contract FeeVault {
    /// @notice Total amount of wei processed by the contract.
    uint256 public totalProcessed;

    /**
     * @notice Sets total processed to its correct value.
     * @param _correctTotalProcessed The correct total processed value.
     */
    function setTotalProcessed(uint256 _correctTotalProcessed) external {
        totalProcessed = _correctTotalProcessed;
    }

    /**
     * @notice Allow the contract to receive ETH.
     */
    receive() external payable {}
}