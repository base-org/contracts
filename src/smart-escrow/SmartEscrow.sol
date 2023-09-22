// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @dev The error is thrown when an address is not set.
error AddressIsZeroAddress();

/// @dev The error is thrown when the start timestamp is zero.
error StartTimeIsZero();

/// @dev The error is thrown when the start timestamp is greater than the end timestamp.
error StartTimeAfterEndTime(uint256 startTimestamp, uint256 endTimestamp);

/// @dev The error is thrown when the vesting period is zero.
error VestingPeriodIsZeroSeconds();

/// @dev The error is thrown when the caller of the method is not the expected owner.
error CallerIsNotOwner(address caller, address owner);

/// @dev The error is thrown when the contract is terminated, when it should not be.
error ContractIsTerminated();

/// @dev The error is thrown when the contract is not terminated, when it should be.
error ContractIsNotTerminated();

/**
 * @title SmartEscrow contract
 * @dev Contract to handle payment of OP tokens over a period of vesting with
 * the ability to terminate the contract.
 * This contract is inspired by OpenZeppelin's VestingWallet contract, but had sufficiently
 * different requirements to where inheriting did not make sense.
 */
contract SmartEscrow is Ownable2Step {
    event OPTransfered(uint256 amount, address indexed recipient);
    event BeneficiaryOwnerUpdated(address indexed oldOwner, address indexed newOwner);
    event BeneficiaryUpdated(address indexed oldBeneficiary, address indexed newBeneficiary);
    event ContractTerminated();

    IERC20 public constant OP_TOKEN = IERC20(0x4200000000000000000000000000000000000042);

    address public beneficiaryOwner;
    address public beneficiary;
    uint256 public released;
    uint256 public immutable start;
    uint256 public immutable end;
    uint256 public immutable vestingPeriod;
    uint256 public immutable initialTokens;
    uint256 public immutable  vestingEventTokens;
    bool public contractTerminated;

    /**
     * @dev Set initial parameters.
     * @param beneficiaryOwnerAddress Address which can update the beneficiary address.
     * @param beneficiaryAddress Address which receives tokens that have vested.
     * @param escrowOwner Address which can terminate the contract.
     * @param startTimestamp Timestamp of the start of vesting period (or the cliff, if there is one).
     * @param endTimestamp Timestamp of the end of the vesting period.
     * @param vestingPeriodSeconds Period of time between each vesting event in seconds.
     * @param numInitialTokens Number of OP tokens which vest at start time.
     * @param numVestingEventTokens Number of OP tokens which vest upon each vesting event.
     */
    constructor(
        address beneficiaryOwnerAddress,
        address beneficiaryAddress,
        address escrowOwner,
        uint256 startTimestamp,
        uint256 endTimestamp,
        uint256 vestingPeriodSeconds,
        uint256 numInitialTokens,
        uint256 numVestingEventTokens
    ) {
        if (beneficiaryOwnerAddress == address(0) || beneficiaryAddress == address(0) || escrowOwner == address(0)) {
            revert AddressIsZeroAddress();
        }
        if (startTimestamp == 0) revert StartTimeIsZero();
        if (startTimestamp > endTimestamp) revert StartTimeAfterEndTime(startTimestamp, endTimestamp);
        if (vestingPeriodSeconds == 0) revert VestingPeriodIsZeroSeconds();

        beneficiary = beneficiaryAddress;
        beneficiaryOwner = beneficiaryOwnerAddress;
        start = startTimestamp;
        end = endTimestamp;
        vestingPeriod = vestingPeriodSeconds;
        initialTokens = numInitialTokens;
        vestingEventTokens = numVestingEventTokens;

        _transferOwnership(escrowOwner);
    }

    /**
     * @dev Allow escrow owner (2-of-2 multisig with beneficiary and benefactor
     * owners as signers) to terminate the contract.
     *
     * Emits a {ContractTerminated} event.
     */
    function terminate(address returnAddress) external onlyOwner {
        contractTerminated = true;
        emit ContractTerminated();
        withdrawUnvestedTokens(returnAddress);
    }

    /**
     * @dev Allow contract owner to update beneficiary owner address.
     *
     * Emits a {BeneficiaryOwnerUpdated} event.
     */
    function updateBeneficiaryOwner(address newBeneficiaryOwner) external onlyOwner {
        if (newBeneficiaryOwner == address(0)) revert AddressIsZeroAddress();
        if (beneficiaryOwner != newBeneficiaryOwner) {
            address oldBeneficiaryOwner = beneficiaryOwner;
            beneficiaryOwner = newBeneficiaryOwner;
            emit BeneficiaryOwnerUpdated(oldBeneficiaryOwner, newBeneficiaryOwner);
        }
    }

    /**
     * @dev Allow beneficiary owner to update beneficiary address.
     *
     * Emits a {BeneficiaryUpdated} event.
     */
    function updateBeneficiary(address newBeneficiary) external {
        if (msg.sender != beneficiaryOwner) revert CallerIsNotOwner(msg.sender, beneficiaryOwner);
        if (newBeneficiary == address(0)) revert AddressIsZeroAddress();
        if (beneficiary != newBeneficiary) {
            address oldBeneficiary = beneficiary;
            beneficiary = newBeneficiary;
            emit BeneficiaryUpdated(oldBeneficiary, newBeneficiary);
        }
    }

    /**
     * @dev Release OP tokens that have already vested.
     *
     * Emits a {OPTransfered} event.
     */
    function release() public {
        if (contractTerminated == true) revert ContractIsTerminated();
        uint256 amount = releasable();
        if (amount > 0) {
            released += amount;
            emit OPTransfered(amount, beneficiary);
            SafeERC20.safeTransfer(OP_TOKEN, beneficiary, amount);
        }
    }

    /**
     * @dev Allow withdrawal of remaining tokens to provided address if contract is terminated
     *
     * Emits a {OPTransfered} event.
     */
    function withdrawUnvestedTokens(address returnAddress) public onlyOwner {
        if (contractTerminated == false) revert ContractIsNotTerminated();
        if (returnAddress == address(0)) revert AddressIsZeroAddress();
        uint256 amount = OP_TOKEN.balanceOf(address(this));
        if (amount > 0) {
            emit OPTransfered(amount, returnAddress);
            SafeERC20.safeTransfer(OP_TOKEN, returnAddress, amount);
        }
    }

    /**
     * @dev Getter for the amount of releasable OP.
     */
    function releasable() public view returns (uint256) {
        return vestedAmount(block.timestamp) - released;
    }

    /**
     * @dev Calculates the amount of OP that has already vested.
     */
    function vestedAmount(uint256 timestamp) public view returns (uint256) {
        return _vestingSchedule(OP_TOKEN.balanceOf(address(this)) + released, timestamp);
    }

    /**
     * @dev Returns the amount vested as a function of time.
     */
    function _vestingSchedule(uint256 totalAllocation, uint256 timestamp) internal view returns (uint256) {
        if (timestamp < start) {
            return 0;
        } else if (timestamp > end) {
            return totalAllocation;
        } else {
            return initialTokens + ((timestamp - start) / vestingPeriod) * vestingEventTokens;
        }
    }
}
