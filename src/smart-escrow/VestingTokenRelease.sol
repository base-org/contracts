// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./SmartEscrow.sol";

/// @title VestingTokenRelease contract
/// @notice Contract to handle payment of OP tokens over a period of vesting with
///         the ability to terminate the contract.
contract VestingTokenRelease is SmartEscrow {
    /// @notice Timestamp of the start of vesting period (or the cliff, if there is one).
    uint256 public immutable start;

    /// @notice Timestamp of the end of the vesting period.
    uint256 public immutable end;

    /// @notice Period of time between each vesting event in seconds.
    uint256 public immutable vestingPeriod;

    /// @notice Number of OP tokens which vest at start time.
    uint256 public immutable initialTokens;

    /// @notice Number of OP tokens which vest upon each vesting event.
    uint256 public immutable  vestingEventTokens;

    /// @notice The error is thrown when the start timestamp is zero.
    error StartTimeIsZero();

    /// @notice The error is thrown when the start timestamp is greater than the end timestamp.
    /// @param startTimestamp The provided start time of the contract
    /// @param endTimestamp The provided end time of the contract
    error StartTimeAfterEndTime(uint256 startTimestamp, uint256 endTimestamp);

    /// @notice The error is thrown when the vesting period is zero.
    error VestingPeriodIsZeroSeconds();

    /// @notice Set initial parameters.
    /// @param _beneficiaryOwner Address which can update the beneficiary address.
    /// @param _beneficiary Address which receives tokens that have vested.
    /// @param _escrowOwner Address which can terminate the contract.
    /// @param _start Timestamp of the start of vesting period (or the cliff, if there is one).
    /// @param _end Timestamp of the end of the vesting period.
    /// @param _vestingPeriodSeconds Period of time between each vesting event in seconds.
    /// @param _initialTokens Number of OP tokens which vest at start time.
    /// @param _vestingEventTokens Number of OP tokens which vest upon each vesting event.
    constructor(
        address _beneficiaryOwner,
        address _beneficiary,
        address _escrowOwner,
        uint256 _start,
        uint256 _end,
        uint256 _vestingPeriodSeconds,
        uint256 _initialTokens,
        uint256 _vestingEventTokens
    ) SmartEscrow(_beneficiaryOwner, _beneficiary, _escrowOwner) {
        if (_start == 0) revert StartTimeIsZero();
        if (_start > _end) revert StartTimeAfterEndTime(_start, _end);
        if (_vestingPeriodSeconds == 0) revert VestingPeriodIsZeroSeconds();

        start = _start;
        end = _end;
        vestingPeriod = _vestingPeriodSeconds;
        initialTokens = _initialTokens;
        vestingEventTokens = _vestingEventTokens;
    }

    /// @notice Returns the amount vested as a function of time.
    /// @param _totalAllocation The total amount of OP allocated to the contract
    /// @param _timestamp The timestamp to at which to get the vested amount
    function _vestingSchedule(uint256 _totalAllocation, uint256 _timestamp) internal override view returns (uint256) {
        if (_timestamp < start) {
            return 0;
        } else if (_timestamp > end) {
            return _totalAllocation;
        } else {
            return initialTokens + ((_timestamp - start) / vestingPeriod) * vestingEventTokens;
        }
    }
}
