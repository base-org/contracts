// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./MultisigBase.sol";

import { console } from "forge-std/console.sol";
import { IMulticall3 } from "forge-std/interfaces/IMulticall3.sol";

/**
 * @title MultisigBuilder
 * @notice Modeled from Optimism's SafeBuilder, but using signatures instead of approvals.
 */
abstract contract MultisigBuilder is MultisigBase {
    /**
     * -----------------------------------------------------------
     * Virtual Functions
     * -----------------------------------------------------------
     */

    /**
     * @notice Follow up assertions to ensure that the script ran to completion.
     */
    function _postCheck() internal virtual view;

    /**
     * @notice Creates the calldata
     */
    function _buildCalls() internal virtual view returns (IMulticall3.Call3[] memory);

    /**
     * @notice Returns the safe address to execute the transaction from
     */
    function _ownerSafe() internal virtual view returns (address);

    /**
     * -----------------------------------------------------------
     * Implemented Functions
     * -----------------------------------------------------------
     */

    /**
     * Step 1
     * ======
     * Generate a transaction execution data to sign. This method should be called by a threshold-1
     * of members of the multisig that will execute the transaction. Signers will pass their
     * signature to the final signer of this multisig.
     *
     * Alternatively, this method can be called by a threshold of signers, and those signatures
     * used by a separate tx executor address in step 2, which doesn't have to be a signer.
     */
    function sign() public view returns (bool) {
        _printDataToSign(_ownerSafe(), _buildCalls());
        return true;
    }

    /**
     * Step 2
     * ======
     * Execute the transaction. This method should be called by the final member of the multisig
     * that will execute the transaction. Signatures from step 1 are required.
     *
     * Alternatively, this method can be called after a threshold of signatures is collected from
     * step 1. In this scenario, the caller doesn't need to be a signer of the multisig.
     */
    function run(bytes memory _signatures) public returns (bool) {
        vm.startBroadcast();
        bool success = _executeTransaction(_ownerSafe(), _buildCalls(), _signatures);
        if (success) _postCheck();
        return success;
    }
}
