// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./MultisigBase.sol";

import { console } from "forge-std/console.sol";
import { IMulticall3 } from "forge-std/interfaces/IMulticall3.sol";

import { EnhancedScript } from "@eth-optimism-bedrock/scripts/universal/EnhancedScript.sol";
import { GlobalConstants } from "@eth-optimism-bedrock/scripts/universal/GlobalConstants.sol";

/**
 * @title MultisigBuilder
 * @notice Modeled from Optimism's SafeBuilder, but using signatures instead of approvals.
 */
abstract contract MultisigBuilder is EnhancedScript, GlobalConstants, MultisigBase {
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
     */
    function sign(address _safe) public returns (bool) {
        _printDataToSign(_safe, _buildCalls());
        return true;
    }

    /**
     * Step 2
     * ======
     * Execute the transaction. This method should be called by the final member of the
     * multisig that will execute the transaction. Signatures from step 1 are required.
     */
    function run(address _safe, bytes memory _signatures) public returns (bool) {
        vm.startBroadcast();
        bool success = _executeTransaction(_safe, _buildCalls(), _signatures);
        if (success) _postCheck();
        return success;
    }
}
