// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

/// @dev The error is thrown when an address is not set.
error AddressIsZeroAddress();

/// @dev The error is thrown when the start timestamp is zero.
error StartTimeIsZero();

/// @dev The error is thrown when the start timestamp is greater than the end timestamp.
error StartTimeAfterEndTime(uint64 startTimestamp, uint64 endTimestamp);

/// @dev The error is thrown when the vesting period is zero.
error VestingPeriodIsZeroSeconds();

/// @dev The error is thrown when the caller of the method is not the expected owner.
error CallerIsNotOwner(address caller, address owner);

/// @dev The error is thrown when the contract is terminated, when it should not be.
error ContractIsTerminated();

/// @dev The error is thrown when the contract is not terminated, when it should be.
error ContractIsNotTerminated();