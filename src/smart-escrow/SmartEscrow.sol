// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title SmartEscrow contract
/// @notice Contract to handle payment of OP tokens over vesting periods.
/// @notice This contract is inspired by OpenZeppelin's VestingWallet contract, but had
///         sufficiently different requirements to where inheriting did not make sense.
abstract contract SmartEscrow is Ownable2Step {
    /// @notice OP token contract.
    IERC20 public constant OP_TOKEN = IERC20(0x4200000000000000000000000000000000000042);

    /// @notice Address which can update the beneficiary address.
    address public beneficiaryOwner;

    /// @notice Address which receives tokens that have vested.
    address public beneficiary;

    /// @notice Number of OP tokens which have be released to the beneficiary.
    uint256 public released;

    /// @notice Flag for whether the contract is terminated or active.
    bool public contractTerminated;

    /// @notice Event emitted when the beneficiary owner is updated.
    /// @param oldOwner The address of the old beneficiary owner
    /// @param newOwner The address of the new beneficiary owner
    event BeneficiaryOwnerUpdated(address indexed oldOwner, address indexed newOwner);

    /// @notice Event emitted when the beneficiary is updated.
    /// @param oldBeneficiary The address of the old beneficiary
    /// @param newBeneficiary The address of the new beneficiary
    event BeneficiaryUpdated(address indexed oldBeneficiary, address indexed newBeneficiary);

    /// @notice Event emitted when the contract is terminated.
    event ContractTerminated();

    /// @notice The error is thrown when an address is not set.
    error AddressIsZeroAddress();

    /// @notice The error is thrown when the caller of the method is not the expected owner.
    /// @param caller The address of the caller
    /// @param owner The address of the owner
    error CallerIsNotOwner(address caller, address owner);

    /// @notice The error is thrown when the contract is terminated, when it should not be.
    error ContractIsTerminated();

    /// @notice The error is thrown when the contract is not terminated, when it should be.
    error ContractIsNotTerminated();

    /// @notice Set initial parameters.
    /// @param _beneficiaryOwner Address which can update the beneficiary address.
    /// @param _beneficiary Address which receives tokens that have vested.
    /// @param _escrowOwner Address which can terminate the contract.
    constructor(
        address _beneficiaryOwner,
        address _beneficiary,
        address _escrowOwner
    ) {
        if (_beneficiaryOwner == address(0) || _beneficiary == address(0) || _escrowOwner == address(0)) {
            revert AddressIsZeroAddress();
        }
        beneficiary = _beneficiary;
        beneficiaryOwner = _beneficiaryOwner;
        _transferOwnership(_escrowOwner);
    }

    /// @notice Allow escrow owner (2-of-2 multisig with beneficiary and benefactor
    ///         owners as signers) to terminate the contract.
    /// @param _returnAddress Address to send remaining contract holdings to after termination
    /// @notice Emits a {ContractTerminated} event.
    function terminate(address _returnAddress) external onlyOwner {
        contractTerminated = true;
        withdrawUnvestedTokens(_returnAddress);
        emit ContractTerminated();
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
        if (msg.sender != beneficiaryOwner) revert CallerIsNotOwner(msg.sender, beneficiaryOwner);
        if (_newBeneficiary == address(0)) revert AddressIsZeroAddress();
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

    /// @notice Allow withdrawal of remaining tokens to provided address if contract is terminated
    /// @param _returnAddress Address to withdraw remaining contract holdings to
    /// @notice Emits a {Transfer} event.
    function withdrawUnvestedTokens(address _returnAddress) public onlyOwner {
        if (!contractTerminated) revert ContractIsNotTerminated();
        if (_returnAddress == address(0)) revert AddressIsZeroAddress();
        uint256 amount = OP_TOKEN.balanceOf(address(this));
        if (amount > 0) {
            SafeERC20.safeTransfer(OP_TOKEN, _returnAddress, amount);
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
    function _vestingSchedule(uint256 _totalAllocation, uint256 _timestamp) internal virtual view returns (uint256);
}
