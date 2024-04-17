// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title Vetoer1of2
 * @dev This contract serves the role of the Vetoer, defined in DelayedVetoable.sol:
 * https://github.com/ethereum-optimism/optimism/blob/d72fb46daf3a6831cb01a78931f8c6e0d52ae243/packages/contracts-bedrock/src/L1/DelayedVetoable.sol
 * It enforces a simple 1 of 2 design, where neither party can remove the other's
 * permissions to execute a Veto call.
 */
contract Vetoer1of2 {
    using Address for address;

    /*//////////////////////////////////////////////////////////////
                            CONSTANTS
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev The address of Optimism's signer (likely a multisig)
     */
    address public immutable opSigner;

    /**
     * @dev The address of counter party's signer (likely a multisig)
     */
    address public immutable otherSigner;

    /*//////////////////////////////////////////////////////////////
                            EVENTS
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev Emitted when a Veto call is made by a signer.
     * @param caller The signer making the call.
     * @param data The data of the call being made.
     * @param result The result of the call being made.
     */
    event VetoCallExecuted(address indexed caller, bytes data, bytes result);

    /*//////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev Constructor to set the values of the constants.
     * @param opSigner_ Address of Optimism signer.
     * @param otherSigner_ Address of counter party signer.
     */
    constructor(address opSigner_, address otherSigner_) {
        require(opSigner_ != address(0), "Vetoer1of2: opSigner cannot be zero address");
        require(otherSigner_ != address(0), "Vetoer1of2: otherSigner cannot be zero address");

        opSigner = opSigner_;
        otherSigner = otherSigner_;
    }

    /*//////////////////////////////////////////////////////////////
                        External Functions
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev Executes a call as the Vetoer (must be called by
     * Optimism or counter party signer).
     * @param data Data for function call.
     * @param delayedVetoable Address of the DelayedVetoable contract to call.
     */
    function execute(bytes memory data, address delayedVetoable) external {
        require(
            msg.sender == otherSigner || msg.sender == opSigner, "Vetoer1of2: must be an approved signer to execute"
        );

        bytes memory result = Address.functionCall(delayedVetoable, data, "Vetoer1of2: failed to execute");

        emit VetoCallExecuted(msg.sender, data, result);
    }
}
