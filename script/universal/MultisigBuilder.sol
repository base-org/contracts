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
    function _postCheck(address _target) internal virtual view;

    /**
     * @notice Creates the calldata
     */
    function buildCalldata(address _target) internal virtual view returns (bytes memory);

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
    function sign(address _safe, address _target) public returns (bool) {
        IMulticall3.Call3 memory call = _generateExecuteCall(_target);
        _printDataToSign(_safe, call);
        return true;
    }

    /**
     * Step 2
     * ======
     * Execute the transaction. This method should be called by the final member of the
     * multisig that will execute the transaction. Signatures from step 1 are required.
     */
    function run(address _safe, address _target, bytes memory _signatures) public returns (bool) {
        vm.startBroadcast();
        IMulticall3.Call3 memory call = _generateExecuteCall(_target);
        bool success = _executeTransaction(_safe, call, _signatures);
        if (success) _postCheck(_target);
        return success;
    }

    function _generateExecuteCall(address _target) internal returns (IMulticall3.Call3 memory) {
        bytes memory data = buildCalldata(_target);
        return IMulticall3.Call3({
            target: _target,
            allowFailure: false,
            callData: data
        });
    }
}
