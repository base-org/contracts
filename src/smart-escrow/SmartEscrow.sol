// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title SmartEscrow contract
/// @notice Contract to handle payment of OP tokens over a period of vesting with
///         the ability to terminate the contract.
/// @notice This contract is inspired by OpenZeppelin's VestingWallet contract, but had
///         sufficiently different requirements to where inheriting did not make sense.
contract SmartEscrow is Ownable2Step {
    /// @notice OP token contract.
    IERC20 public constant OP_TOKEN = IERC20(0x4200000000000000000000000000000000000042);

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

    /// @notice Address which represents the benefactor entity.
    address public benefactorOwner;

    /// @notice Address which represents the beneficiary entity.
    address public beneficiaryOwner;

    /// @notice Address which receives funds back in case of contract termination.
    address public benefactor;

    /// @notice Address which receives tokens that have vested.
    address public beneficiary;

    /// @notice Number of OP tokens which have be released to the beneficiary.
    uint256 public released;

    /// @notice Flag for whether the contract is terminated or active.
    bool public contractTerminated;

    /// @notice Event emitted when the benefactor owner is updated.
    /// @param oldOwner The address of the old benefactor owner
    /// @param newOwner The address of the new benefactor owner
    event BenefactorOwnerUpdated(address indexed oldOwner, address indexed newOwner);

    /// @notice Event emitted when the beneficiary owner is updated.
    /// @param oldOwner The address of the old beneficiary owner
    /// @param newOwner The address of the new beneficiary owner
    event BeneficiaryOwnerUpdated(address indexed oldOwner, address indexed newOwner);

    /// @notice Event emitted when the benefactor is updated.
    /// @param oldBenefactor The address of the old benefactor
    /// @param newBenefactor The address of the new benefactor
    event BenefactorUpdated(address indexed oldBenefactor, address indexed newBenefactor);

    /// @notice Event emitted when the beneficiary is updated.
    /// @param oldBeneficiary The address of the old beneficiary
    /// @param newBeneficiary The address of the new beneficiary
    event BeneficiaryUpdated(address indexed oldBeneficiary, address indexed newBeneficiary);

    /// @notice Event emitted when the contract is terminated.
    event ContractTerminated();

    /// @notice Event emitted when the contract was terminated and is no longer.
    event ContractResumed();

    /// @notice The error is thrown when an address is not set.
    error AddressIsZeroAddress();

    /// @notice The error is thrown when the start timestamp is zero.
    error StartTimeIsZero();

    /// @notice The error is thrown when the start timestamp is greater than the end timestamp.
    /// @param startTimestamp The provided start time of the contract
    /// @param endTimestamp The provided end time of the contract
    error StartTimeAfterEndTime(uint256 startTimestamp, uint256 endTimestamp);

    /// @notice The error is thrown when the vesting period is zero.
    error VestingPeriodIsZeroSeconds();

    /// @notice The error is thrown when the caller of the method is not the expected owner.
    /// @param caller The address of the caller
    error CallerIsNotOwner(address caller);

    /// @notice The error is thrown when the contract is terminated, when it should not be.
    error ContractIsTerminated();

    /// @notice The error is thrown when the contract is not terminated, when it should be.
    error ContractIsNotTerminated();

    /// @notice Set initial parameters.
    /// @param _benefactorOwner Address which represents the benefactor entity.
    /// @param _beneficiaryOwner Address which represents the beneficiary entity.
    /// @param _benefactor Address which receives tokens back in case of contract termination.
    /// @param _beneficiary Address which receives tokens that have vested.
    /// @param _escrowOwner Address which represents both the benefactor and the beneficiary entities.
    /// @param _start Timestamp of the start of vesting period (or the cliff, if there is one).
    /// @param _end Timestamp of the end of the vesting period.
    /// @param _vestingPeriodSeconds Period of time between each vesting event in seconds.
    /// @param _initialTokens Number of OP tokens which vest at start time.
    /// @param _vestingEventTokens Number of OP tokens which vest upon each vesting event.
    constructor(
        address _benefactorOwner,
        address _beneficiaryOwner,
        address _benefactor,
        address _beneficiary,
        address _escrowOwner,
        uint256 _start,
        uint256 _end,
        uint256 _vestingPeriodSeconds,
        uint256 _initialTokens,
        uint256 _vestingEventTokens
    ) {
        if (_benefactor == address(0) || _beneficiary == address(0) ||
        _beneficiaryOwner == address(0) || _benefactorOwner == address(0) ||
        _escrowOwner == address(0)) {
            revert AddressIsZeroAddress();
        }
        if (_start == 0) revert StartTimeIsZero();
        if (_start > _end) revert StartTimeAfterEndTime(_start, _end);
        if (_vestingPeriodSeconds == 0) revert VestingPeriodIsZeroSeconds();

        beneficiary = _beneficiary;
        beneficiaryOwner = _beneficiaryOwner;
        benefactor = _benefactor;
        benefactorOwner = _benefactorOwner;
        start = _start;
        end = _end;
        vestingPeriod = _vestingPeriodSeconds;
        initialTokens = _initialTokens;
        vestingEventTokens = _vestingEventTokens;

        _transferOwnership(_escrowOwner);
    }

    /// @notice Terminates the contract if called by either beneficiary or benefactor entity.
    /// @notice Emits a {ContractTerminated} event.
    function terminate() external {
        if (msg.sender != benefactorOwner && msg.sender != beneficiaryOwner) revert CallerIsNotOwner(msg.sender);
        contractTerminated = true;
        emit ContractTerminated();
    }

    /// @notice Resumes the contract if called by the owner.
    /// @notice Emits a {ContractResumed} event.
    function resume() external onlyOwner {
        contractTerminated = false;
        emit ContractResumed();
    }

    /// @notice Allow contract owner to update benefactor owner address.
    /// @param _newBenefactorOwner Address to send remaining contract holdings to after termination
    /// @notice Emits a {BenefactorOwnerUpdated} event.
    function updateBenefactorOwner(address _newBenefactorOwner) external onlyOwner {
        if (_newBenefactorOwner == address(0)) revert AddressIsZeroAddress();
        address oldBenefactorOwner = benefactorOwner;
        if (oldBenefactorOwner != _newBenefactorOwner) {
            benefactorOwner = _newBenefactorOwner;
            emit BenefactorOwnerUpdated(oldBenefactorOwner, _newBenefactorOwner);
        }
    }

    /// @notice Allow benefactor owner to update benefactor address.
    /// @param _newBenefactor New benefactor address
    /// @notice Emits a {BenefactorUpdated} event.
    function updateBenefactor(address _newBenefactor) external {
        if (msg.sender != benefactorOwner) revert CallerIsNotOwner(msg.sender);
        if (_newBenefactor == address(0)) revert AddressIsZeroAddress();
        address oldBenefactor = benefactor;
        if (oldBenefactor != _newBenefactor) {
            benefactor = _newBenefactor;
            emit BenefactorUpdated(oldBenefactor, _newBenefactor);
        }
    }

    /// @notice Allow contract owner to update beneficiary owner address.
    /// @param _newBeneficiaryOwner Address to send remaining contract holdings to after termination
    /// @notice Emits a {BeneficiaryOwnerUpdated} event.
    function updateBeneficiaryOwner(address _newBeneficiaryOwner) external onlyOwner {
        if (_newBeneficiaryOwner == address(0)) revert AddressIsZeroAddress();
        address oldBeneficiaryOwner = beneficiaryOwner;
        if (oldBeneficiaryOwner != _newBeneficiaryOwner) {
            beneficiaryOwner = _newBeneficiaryOwner;
            emit BeneficiaryOwnerUpdated(oldBeneficiaryOwner, _newBeneficiaryOwner);
        }
    }

    /// @notice Allow beneficiary owner to update beneficiary address.
    /// @param _newBeneficiary New beneficiary address
    /// @notice Emits a {BeneficiaryUpdated} event.
    function updateBeneficiary(address _newBeneficiary) external {
        if (msg.sender != beneficiaryOwner) revert CallerIsNotOwner(msg.sender);
        address oldBeneficiary = beneficiary;
        if (oldBeneficiary != _newBeneficiary) {
            beneficiary = _newBeneficiary;
            emit BeneficiaryUpdated(oldBeneficiary, _newBeneficiary);
        }
    }

    /// @notice Release OP tokens that have already vested.
    /// @notice Emits a {Transfer} event.
    function release() public {
        if (contractTerminated) revert ContractIsTerminated();
        uint256 amount = releasable();
        if (amount > 0) {
            released += amount;
            SafeERC20.safeTransfer(OP_TOKEN, beneficiary, amount);
        }
    }

    /// @notice Allow withdrawal of remaining tokens to benefactor address if contract is terminated
    /// @notice Emits a {Transfer} event.
    function withdrawUnvestedTokens() public onlyOwner {
        if (!contractTerminated) revert ContractIsNotTerminated();
        uint256 amount = OP_TOKEN.balanceOf(address(this));
        if (amount > 0) {
            SafeERC20.safeTransfer(OP_TOKEN, benefactor, amount);
        }
    }

    /// @notice Getter for the amount of releasable OP.
    function releasable() public view returns (uint256) {
        return vestedAmount(block.timestamp) - released;
    }

    /// @notice Calculates the amount of OP that has already vested.
    /// @param _timestamp The timestamp to at which to get the vested amount
    function vestedAmount(uint256 _timestamp) public view returns (uint256) {
        return _vestingSchedule(OP_TOKEN.balanceOf(address(this)) + released, _timestamp);
    }

    /// @notice Returns the amount vested as a function of time.
    /// @param _totalAllocation The total amount of OP allocated to the contract
    /// @param _timestamp The timestamp to at which to get the vested amount
    function _vestingSchedule(uint256 _totalAllocation, uint256 _timestamp) internal view returns (uint256) {
        if (_timestamp < start) {
            return 0;
        } else if (_timestamp > end) {
            return _totalAllocation;
        } else {
            return initialTokens + ((_timestamp - start) / vestingPeriod) * vestingEventTokens;
        }
    }
}
