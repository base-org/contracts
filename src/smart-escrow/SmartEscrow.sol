// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/AccessControlDefaultAdminRules.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title SmartEscrow contract
/// @notice Contract to handle payment of OP tokens over a period of vesting with
///         the ability to terminate the contract.
/// @notice This contract is inspired by OpenZeppelin's VestingWallet contract, but had
///         sufficiently different requirements to where inheriting did not make sense.
contract SmartEscrow is AccessControlDefaultAdminRules {
    /// @notice OP token contract.
    IERC20 public constant OP_TOKEN = IERC20(0x4200000000000000000000000000000000000042);

    /// @notice Role which can update benefactor address.
    bytes32 public constant BENEFACTOR_OWNER_ROLE = keccak256("smartescrow.roles.benefactorowner");

    /// @notice Role which can update beneficiary address.
    bytes32 public constant BENEFICIARY_OWNER_ROLE = keccak256("smartescrow.roles.beneficiaryowner");

    /// @notice Role which can update call terminate.
    bytes32 public constant TERMINATOR_ROLE = keccak256("smartescrow.roles.terminator");

    /// @notice Timestamp of the start of vesting period.
    uint256 public immutable start;

    /// @notice Timestamp of the cliff.
    uint256 public immutable cliffStart;

    /// @notice Timestamp of the end of the vesting period.
    uint256 public immutable end;

    /// @notice Period of time between each vesting event in seconds.
    uint256 public immutable vestingPeriod;

    /// @notice Number of OP tokens which vest at start time.
    uint256 public immutable initialTokens;

    /// @notice Number of OP tokens which vest upon each vesting event.
    uint256 public immutable vestingEventTokens;

    /// @notice Address which receives funds back in case of contract termination.
    address public benefactor;

    /// @notice Address which receives tokens that have vested.
    address public beneficiary;

    /// @notice Number of OP tokens which have been released to the beneficiary.
    uint256 public released;

    /// @notice Flag for whether the contract is terminated or active.
    bool public contractTerminated;

    /// @notice Event emitted when tokens are withdrawn from the contract.
    /// @param benefactor The address which received the withdrawn tokens.
    /// @param amount The amount of tokens withdrawn.
    event TokensWithdrawn(address indexed benefactor, uint256 amount);

    /// @notice Event emitted when tokens are released to the beneficiary.
    /// @param beneficiary The address which received the released tokens.
    /// @param amount The amount of tokens released.
    event TokensReleased(address indexed beneficiary, uint256 amount);

    /// @notice Event emitted when the benefactor is updated.
    /// @param oldBenefactor The address of the old benefactor.
    /// @param newBenefactor The address of the new benefactor.
    event BenefactorUpdated(address indexed oldBenefactor, address indexed newBenefactor);

    /// @notice Event emitted when the beneficiary is updated.
    /// @param oldBeneficiary The address of the old beneficiary.
    /// @param newBeneficiary The address of the new beneficiary.
    event BeneficiaryUpdated(address indexed oldBeneficiary, address indexed newBeneficiary);

    /// @notice Event emitted when the contract is terminated.
    event ContractTerminated();

    /// @notice Event emitted when the contract was terminated and is no longer.
    event ContractResumed();

    /// @notice The error is thrown when an address is not set.
    error AddressIsZeroAddress();

    /// @notice The error is thrown when the start timestamp is greater than the end timestamp.
    /// @param startTimestamp The provided start time of the contract.
    /// @param endTimestamp The provided end time of the contract.
    error StartTimeAfterEndTime(uint256 startTimestamp, uint256 endTimestamp);

    /// @notice The error is thrown when the cliffStart timestamp is less than the start time.
    /// @param cliffStartTimestamp The provided start time of the contract.
    /// @param startTime The start time
    error CliffStartTimeInvalid(uint256 cliffStartTimestamp, uint256 startTime);

    /// @notice The error is thrown when the cliffStart timestamp is greater than the end timestamp.
    /// @param cliffStartTimestamp The provided start time of the contract.
    /// @param endTimestamp The provided end time of the contract.
    error CliffStartTimeAfterEndTime(uint256 cliffStartTimestamp, uint256 endTimestamp);

    /// @notice The error is thrown when the vesting period is zero.
    error VestingPeriodIsZeroSeconds();

    /// @notice The error is thrown when the number of vesting event tokens is zero.
    error VestingEventTokensIsZero();

    /// @notice The error is thrown when vesting period is longer than the contract duration.
    /// @param vestingPeriodSeconds The provided vesting period in seconds.
    error VestingPeriodExceedsContractDuration(uint256 vestingPeriodSeconds);

    /// @notice The error is thrown when the vesting period does not evenly divide the contract duration.
    /// @param vestingPeriodSeconds The provided vesting period in seconds.
    /// @param startTimestamp The provided start time of the contract.
    /// @param endTimestamp The provided end time of the contract.
    error UnevenVestingPeriod(uint256 vestingPeriodSeconds, uint256 startTimestamp, uint256 endTimestamp);

    /// @notice The error is thrown when the contract is terminated, when it should not be.
    error ContractIsTerminated();

    /// @notice The error is thrown when the contract is not terminated, when it should be.
    error ContractIsNotTerminated();

    /// @notice Set initial parameters.
    /// @param _benefactor Address which receives tokens back in case of contract termination.
    /// @param _beneficiary Address which receives tokens that have vested.
    /// @param _benefactorOwner Address which represents the benefactor entity.
    /// @param _beneficiaryOwner Address which represents the beneficiary entity.
    /// @param _escrowOwner Address which represents both the benefactor and the beneficiary entities.
    /// @param _start Timestamp of the start of vesting period (or the cliff, if there is one).
    /// @param _end Timestamp of the end of the vesting period.
    /// @param _vestingPeriodSeconds Period of time between each vesting event in seconds.
    /// @param _initialTokens Number of OP tokens which vest at start time.
    /// @param _vestingEventTokens Number of OP tokens which vest upon each vesting event.
    constructor(
        address _benefactor,
        address _beneficiary,
        address _benefactorOwner,
        address _beneficiaryOwner,
        address _escrowOwner,
        uint256 _start,
        uint256 _cliffStart,
        uint256 _end,
        uint256 _vestingPeriodSeconds,
        uint256 _initialTokens,
        uint256 _vestingEventTokens
    ) AccessControlDefaultAdminRules(5 days, _escrowOwner) {
        if (
            _benefactor == address(0) || _beneficiary == address(0) || _beneficiaryOwner == address(0)
                || _benefactorOwner == address(0)
        ) {
            revert AddressIsZeroAddress();
        }
        if (_start >= _end) revert StartTimeAfterEndTime(_start, _end);
        if (_cliffStart < _start) revert CliffStartTimeInvalid(_cliffStart, _start);
        if (_cliffStart >= _end) revert CliffStartTimeAfterEndTime(_cliffStart, _end);
        if (_vestingPeriodSeconds == 0) revert VestingPeriodIsZeroSeconds();
        if (_vestingEventTokens == 0) revert VestingEventTokensIsZero();
        if ((_end - _start) < _vestingPeriodSeconds) {
            revert VestingPeriodExceedsContractDuration(_vestingPeriodSeconds);
        }
        if ((_end - _start) % _vestingPeriodSeconds != 0) {
            revert UnevenVestingPeriod(_vestingPeriodSeconds, _start, _end);
        }

        benefactor = _benefactor;
        beneficiary = _beneficiary;
        start = _start;
        cliffStart = _cliffStart;
        end = _end;
        vestingPeriod = _vestingPeriodSeconds;
        initialTokens = _initialTokens;
        vestingEventTokens = _vestingEventTokens;

        _grantRole(BENEFACTOR_OWNER_ROLE, _benefactorOwner);
        _grantRole(TERMINATOR_ROLE, _benefactorOwner);
        _grantRole(BENEFICIARY_OWNER_ROLE, _beneficiaryOwner);
        _grantRole(TERMINATOR_ROLE, _beneficiaryOwner);
    }

    /// @notice Terminates the contract if called by address with TERMINATOR_ROLE.
    /// @notice Releases any vested token to the beneficiary before terminating.
    /// @notice Emits a {ContractTerminated} event.
    function terminate() external onlyRole(TERMINATOR_ROLE) {
        release();
        contractTerminated = true;
        emit ContractTerminated();
    }

    /// @notice Resumes the contract on the original vesting schedule.
    /// @notice Must be called by address with DEFAULT_ADMIN_ROLE role.
    /// @notice Emits a {ContractResumed} event.
    function resume() external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (!contractTerminated) revert ContractIsNotTerminated();
        contractTerminated = false;
        emit ContractResumed();
    }

    /// @notice Allow benefactor owner to update benefactor address.
    /// @dev This method does not adjust the BENEFACTOR_OWNER_ROLE. Ensure to pair calling this
    /// with a role change by DEFAULT_ADMIN if this is the desired outcome.
    /// @param _newBenefactor New benefactor address.
    /// @notice Emits a {BenefactorUpdated} event.
    function updateBenefactor(address _newBenefactor) external onlyRole(BENEFACTOR_OWNER_ROLE) {
        if (_newBenefactor == address(0)) revert AddressIsZeroAddress();
        address oldBenefactor = benefactor;
        if (oldBenefactor != _newBenefactor) {
            benefactor = _newBenefactor;
            emit BenefactorUpdated(oldBenefactor, _newBenefactor);
        }
    }

    /// @notice Allow beneficiary owner to update beneficiary address.
    /// @dev This method does not adjust the BENEFICIARY_OWNER_ROLE. Ensure to pair calling this
    /// with a role change by DEFAULT_ADMIN if this is the desired outcome.
    /// @param _newBeneficiary New beneficiary address.
    /// @notice Emits a {BeneficiaryUpdated} event.
    function updateBeneficiary(address _newBeneficiary) external onlyRole(BENEFICIARY_OWNER_ROLE) {
        if (_newBeneficiary == address(0)) revert AddressIsZeroAddress();
        address oldBeneficiary = beneficiary;
        if (oldBeneficiary != _newBeneficiary) {
            beneficiary = _newBeneficiary;
            emit BeneficiaryUpdated(oldBeneficiary, _newBeneficiary);
        }
    }

    /// @notice Allow withdrawal of remaining tokens to benefactor address if contract is terminated.
    /// @notice Emits a {Transfer} event and a {TokensWithdrawn} event.
    function withdrawUnvestedTokens() external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (!contractTerminated) revert ContractIsNotTerminated();
        uint256 amount = OP_TOKEN.balanceOf(address(this));
        if (amount > 0) {
            OP_TOKEN.transfer(benefactor, amount);
            emit TokensWithdrawn(benefactor, amount);
        }
    }

    /// @notice Release OP tokens that have already vested.
    /// @notice Emits a {Transfer} event and a {TokensReleased} event.
    function release() public {
        if (contractTerminated) revert ContractIsTerminated();
        uint256 amount = releasable();
        if (amount > 0) {
            released += amount;
            OP_TOKEN.transfer(beneficiary, amount);
            emit TokensReleased(beneficiary, amount);
        }
    }

    /// @notice Getter for the amount of releasable OP.
    function releasable() public view returns (uint256) {
        return vestedAmount(block.timestamp) - released;
    }

    /// @notice Calculates the amount of OP that has already vested.
    /// @param _timestamp The timestamp to at which to get the vested amount
    function vestedAmount(uint256 _timestamp) public view returns (uint256) {
        return _vestingSchedule(_timestamp);
    }

    /// @notice Returns the amount vested as a function of time.
    /// @param _timestamp The timestamp to at which to get the vested amount
    function _vestingSchedule(uint256 _timestamp) internal view returns (uint256) {
        if (_timestamp < cliffStart) {
            return 0;
        } else if (_timestamp > end) {
            return OP_TOKEN.balanceOf(address(this)) + released;
        } else {
            return initialTokens + ((_timestamp - start) / vestingPeriod) * vestingEventTokens;
        }
    }
}
