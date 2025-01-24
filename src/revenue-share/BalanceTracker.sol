// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import {SafeCall} from "@eth-optimism-bedrock/src/libraries/SafeCall.sol";

/**
 * @title BalanceTracker
 * @dev Funds system addresses and sends the remaining profits to the profit wallet.
 */
contract BalanceTracker is ReentrancyGuardUpgradeable {
    using Address for address;
    /*//////////////////////////////////////////////////////////////
                            Constants
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev The maximum number of system addresses that can be funded.
     */

    uint256 public constant MAX_SYSTEM_ADDRESS_COUNT = 20;

    /*//////////////////////////////////////////////////////////////
                            Immutables
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev The address of the wallet receiving profits.
     */
    address payable public immutable PROFIT_WALLET;

    /*//////////////////////////////////////////////////////////////
                            VARIABLES
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev The system addresses being funded.
     */
    address payable[] public systemAddresses;
    /**
     * @dev The target balances for system addresses.
     */
    uint256[] public targetBalances;

    /*//////////////////////////////////////////////////////////////
                            Events
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev Emitted when the BalanceTracker sends funds to a system address.
     * @param _systemAddress The system address being funded.
     * @param _success A boolean denoting whether a fund send occurred and its success or failure.
     * @param _balanceNeeded The amount of funds the given system address needs to reach its target balance.
     * @param _balanceSent The amount of funds sent to the system address.
     */
    event ProcessedFunds(
        address indexed _systemAddress, bool indexed _success, uint256 _balanceNeeded, uint256 _balanceSent
    );
    /**
     * @dev Emitted when the BalanceTracker attempts to send funds to the profit wallet.
     * @param _profitWallet The address of the profit wallet.
     * @param _success A boolean denoting the success or failure of fund send.
     * @param _balanceSent The amount of funds sent to the profit wallet.
     */
    event SentProfit(address indexed _profitWallet, bool indexed _success, uint256 _balanceSent);
    /**
     * @dev Emitted when funds are received.
     * @param _sender The address sending funds.
     * @param _amount The amount of funds received from the sender.
     */
    event ReceivedFunds(address indexed _sender, uint256 _amount);

    /*//////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev Constructor for the BalanceTracker contract that sets an immutable variable.
     * @param _profitWallet The address to send remaining ETH profits to.
     */
    constructor(address payable _profitWallet) {
        require(_profitWallet != address(0), "BalanceTracker: PROFIT_WALLET cannot be address(0)");

        PROFIT_WALLET = _profitWallet;

        _disableInitializers();
    }

    /*//////////////////////////////////////////////////////////////
                            External Functions
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev Initializes the BalanceTracker contract.
     * @param _systemAddresses The system addresses being funded.
     * @param _targetBalances The target balances for system addresses.
     */
    function initialize(address payable[] memory _systemAddresses, uint256[] memory _targetBalances)
        external
        reinitializer(2)
    {
        uint256 systemAddressesLength = _systemAddresses.length;
        require(systemAddressesLength > 0, "BalanceTracker: systemAddresses cannot have a length of zero");
        require(
            systemAddressesLength <= MAX_SYSTEM_ADDRESS_COUNT,
            "BalanceTracker: systemAddresses cannot have a length greater than 20"
        );
        require(
            systemAddressesLength == _targetBalances.length,
            "BalanceTracker: systemAddresses and targetBalances length must be equal"
        );
        for (uint256 i; i < systemAddressesLength;) {
            require(_systemAddresses[i] != address(0), "BalanceTracker: systemAddresses cannot contain address(0)");
            require(_targetBalances[i] > 0, "BalanceTracker: targetBalances cannot contain 0 target");
            unchecked {
                i++;
            }
        }

        systemAddresses = _systemAddresses;
        targetBalances = _targetBalances;

        __ReentrancyGuard_init();
    }

    /**
     * @dev Funds system addresses and sends remaining profits to the profit wallet.
     *
     */
    function processFees() external nonReentrant {
        uint256 systemAddressesLength = systemAddresses.length;
        require(systemAddressesLength > 0, "BalanceTracker: systemAddresses cannot have a length of zero");
        // Refills balances of systems addresses up to their target balances
        for (uint256 i; i < systemAddressesLength;) {
            refillBalanceIfNeeded(systemAddresses[i], targetBalances[i]);
            unchecked {
                i++;
            }
        }

        // Send remaining profits to profit wallet
        uint256 valueToSend = address(this).balance;
        bool success = SafeCall.send(PROFIT_WALLET, gasleft(), valueToSend);
        emit SentProfit(PROFIT_WALLET, success, valueToSend);
    }

    /**
     * @dev Fallback function to receive funds from L2 fee withdrawals and additional top up funds if
     *      L2 fees are insufficient to fund L1 system addresses.
     */
    receive() external payable {
        emit ReceivedFunds(msg.sender, msg.value);
    }

    /*//////////////////////////////////////////////////////////////
                            Internal Functions
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev Checks the balance of the target address and refills it back up to the target balance if needed.
     * @param _systemAddress The system address being funded.
     * @param _targetBalance The target balance for the system address being funded.
     */
    function refillBalanceIfNeeded(address _systemAddress, uint256 _targetBalance) internal {
        uint256 systemAddressBalance = _systemAddress.balance;
        if (systemAddressBalance >= _targetBalance) {
            emit ProcessedFunds(_systemAddress, false, 0, 0);
            return;
        }

        uint256 valueNeeded = _targetBalance - systemAddressBalance;
        uint256 balanceTrackerBalance = address(this).balance;
        uint256 valueToSend = valueNeeded > balanceTrackerBalance ? balanceTrackerBalance : valueNeeded;

        bool success = SafeCall.send(_systemAddress, gasleft(), valueToSend);
        emit ProcessedFunds(_systemAddress, success, valueNeeded, valueToSend);
    }
}
