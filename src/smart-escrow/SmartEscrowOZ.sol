// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/finance/VestingWallet.sol";

/**
 * @title SmartEscrow contract
 * @dev Contract to handle payment of OP tokens over a period of vesting with
 * the ability to terminate the contract.
 */
contract SmartEscrow is VestingWallet, AccessControl {
    event OPTransfered(uint256 amount, address recipient);
    event BeneficiaryUpdated(address oldBeneficiary, address newBeneficiary);
    event BenefactorUpdated(address oldBenefactor, address newBenefactor);
    event ContractTerminated();

    IERC20 public constant OP_TOKEN = IERC20(0x4200000000000000000000000000000000000042);
    bytes32 public constant BENEFICIARY_OWNER = keccak256("smartescrow.roles.beneficiary");
    bytes32 public constant BENEFACTOR_OWNER = keccak256("smartescrow.roles.benefactor");
    bytes32 public constant ESCROW_OWNER = keccak256("smartescrow.roles.escrowowner");
    
    address private _recipient;
    address private _benefactor;
    uint256 private _released;
    uint64 private immutable _vestingPeriod;
    uint64 private immutable _initialTokens;
    uint64 private immutable  _vestingEventTokens;
    bool private _contractTerminated;

    /**
     * @dev Set initial parameters.
     * @param beneficiaryOwner Address which can update the beneficiary address.
     * @param benefactorOwner Address which can update the benefactor address.
     * @param escrowOwner Address which can terminate the contract.
     * @param beneficiaryAddress Address which receives tokens that have vested.
     * @param benefactorAddress Address which receives remaining tokens if contract is terminated.
     * @param startTimestamp Timestamp of the start of vesting period (or the cliff, if there is one).
     * @param durationSeconds Duration from start to end of vesting in seconds.
     * @param vestingPeriodSeconds Period of time between each vesting event in seconds.
     * @param numInitialTokens Number of OP tokens which vest at start time.
     * @param numVestingEventTokens Number of OP tokens which vest upon each vesting event.
     */
    constructor(
        address beneficiaryOwner,
        address benefactorOwner,
        address escrowOwner,
        address beneficiaryAddress,
        address benefactorAddress,
        uint64 startTimestamp,
        uint64 durationSeconds,
        uint64 vestingPeriodSeconds,
        uint64 numInitialTokens,
        uint64 numVestingEventTokens
    ) VestingWallet(beneficiaryAddress, startTimestamp, durationSeconds) {
        require(beneficiaryOwner != address(0), "SmartEscrow: beneficiaryOwner is zero address");
        require(benefactorOwner != address(0), "SmartEscrow: benefactorOwner is zero address");
        require(escrowOwner != address(0), "SmartEscrow: escrowOwner is zero address");
        require(benefactorAddress != address(0), "SmartEscrow: benefactorAddress is zero address");

        require(startTimestamp > 0, "SmartEscrow: start time is zero");
        require(vestingPeriodSeconds > 0, "SmartEscrow: vestingPeriodSeconds is zero");

        // TODO: could add a check that checks the owners of the escrowOwner are beneficiaryOwner and benefactorOwner
        _grantRole(DEFAULT_ADMIN_ROLE, escrowOwner);
        _grantRole(ESCROW_OWNER, escrowOwner);
        _grantRole(BENEFICIARY_OWNER, beneficiaryOwner);
        _grantRole(BENEFACTOR_OWNER, benefactorOwner);

        _recipient = beneficiaryAddress;
        _benefactor = benefactorAddress;
        _vestingPeriod = vestingPeriodSeconds;
        _initialTokens = numInitialTokens;
        _vestingEventTokens = numVestingEventTokens;
    }

    /**
     * @dev Allow escrow owner (likely a 2-of-2 multisig with beneficiary and benefactor
     * owners as signers) to terminate the contract.
     *
     * Emits a {ContractTerminated} event.
     */
    function terminate() external virtual onlyRole(ESCROW_OWNER) {
        _contractTerminated = true;
        emit ContractTerminated();
        withdrawUnvestedTokens();
    }

    /**
     * @dev Allow beneficiary owner to update beneficiary address
     *
     * Emits a {BeneficiaryUpdated} event.
     */
    function updateBeneficiary(address newBeneficiary) external virtual onlyRole(BENEFICIARY_OWNER) {
        require(newBeneficiary != address(0), "SmartEscrow: newBeneficiary is zero address");
        if (recipient() != newBeneficiary) {
            address oldBeneficiary = recipient();
            _recipient = newBeneficiary;
            emit BeneficiaryUpdated(oldBeneficiary, recipient());
        }
    }

    /**
     * @dev Allow benefactor owner to update benefactor address
     *
     * Emits a {BenefactorUpdated} event.
     */
    function updateBenefactor(address newBenefactor) external virtual onlyRole(BENEFACTOR_OWNER) {
        require(newBenefactor != address(0), "SmartEscrow: newBenefactor is zero address");
        if (_benefactor != newBenefactor) {
            address oldBenefactor = _benefactor;
            _benefactor = newBenefactor;
            emit BenefactorUpdated(oldBenefactor, _benefactor);
        }
    }

    /**
     * @dev Getter for the recipient address.
     */
    function recipient() public view virtual returns (address) {
        return _recipient;
    }

    /**
     * @dev Getter for the benefactor address.
     */
    function benefactor() public view virtual returns (address) {
        return _benefactor;
    }
    
    /**
     * @dev Getter for the vesting period.
     */
    function vestingPeriod() public view virtual returns (uint256) {
        return _vestingPeriod;
    }

    /**
     * @dev Getter for number of tokens that vest at start time.
     */
    function initialTokens() public view virtual returns (uint256) {
        return _initialTokens;
    }

    /**
     * @dev Getter for number of tokens that vest after each vesting period
     */
    function vestingEventTokens() public view virtual returns (uint256) {
        return _vestingEventTokens;
    }

    /**
     * @dev Getter for whether the contract is terminated
     */
    function contractTerminated() public view virtual returns (bool) {
        return _contractTerminated;
    }

    /**
     * @dev Getter for the amount of releasable OP.
     */
    function releasable() public view virtual returns (uint256) {
        return vestedAmount(uint64(block.timestamp)) - released();
    }

    /**
     * @dev Release OP tokens that have already vested.
     *
     * Emits a {OPTransfered} event.
     */
    function release() public virtual override {
        require (contractTerminated() == false, "SmartEscrow: Contract is terminated.");
        uint256 amount = releasable();
        _released += amount;
        emit OPTransfered(amount, recipient());
        SafeERC20.safeTransfer(OP_TOKEN, recipient(), amount);
    }

    /**
     * @dev Allow withdrawal of remaining tokens back to benefactor address if contract is terminated
     *
     * Emits a {OPTransfered} event.
     */
    function withdrawUnvestedTokens() public virtual {
        require (contractTerminated() == true, "SmartEscrow: Contract is not terminated.");
        uint256 amount = OP_TOKEN.balanceOf(address(this));
        emit OPTransfered(amount, benefactor());
        SafeERC20.safeTransfer(OP_TOKEN, benefactor(), amount);
    }

    /**
     * @dev Calculates the amount of OP that has already vested. Default implementation is a linear vesting curve.
     */
    function vestedAmount(uint64 timestamp) public view virtual override returns (uint256) {
        return _vestingSchedule(OP_TOKEN.balanceOf(address(this)) + released(), timestamp);
    }

    /**
     * @dev This returns the amount vested, as a function of time.
     */
    function _vestingSchedule(uint256 totalAllocation, uint64 timestamp) internal view virtual override returns (uint256) {
        if (timestamp < start()) {
            return 0;
        } else if (timestamp > start() + duration()) {
            return totalAllocation;
        } else {
            return initialTokens() + ((timestamp - start()) / vestingPeriod()) * vestingEventTokens();
        }
    }
}
