// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./SmartEscrow.sol";

/// @title DelegatableTokenRelease contract
/// @notice TODO
contract DelegatableTokenRelease is SmartEscrow {
    /// @notice Timestamp of when the tokens vest
    uint256 public immutable vestingTime;

    /// @notice The error is thrown when the vesting timestamp is zero.
    error VestingTimeIsZero();

    /// @notice Set initial parameters.
    /// @param _beneficiaryOwner Address which can update the beneficiary address.
    /// @param _beneficiary Address which receives tokens that have vested.
    /// @param _escrowOwner Address which can terminate the contract.
    /// @param _vestingTime Timestamp of when the tokens vest
    constructor(
        address _beneficiaryOwner,
        address _beneficiary,
        address _escrowOwner,
        uint256 _vestingTime
    ) SmartEscrow(_beneficiaryOwner, _beneficiary, _escrowOwner) {
        if (_vestingTime == 0) revert VestingTimeIsZero();
        vestingTime = _vestingTime;
    }

    // TODO: function to allow for delegating unvested tokens up to 9%

    /// @notice Returns the amount vested as a function of time.
    /// @param _totalAllocation The total amount of OP allocated to the contract
    /// @param _timestamp The timestamp to at which to get the vested amount
    function _vestingSchedule(uint256 _totalAllocation, uint256 _timestamp) internal override view returns (uint256) {
        if (_timestamp > vestingTime) {
            return _totalAllocation;
        } else {
            return 0;
        }
    }
}
