// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./MultisigBase.sol";

import {console} from "forge-std/console.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";

/**
 * @title NestedMultisigBuilder
 * @notice Modeled from Optimism's SafeBuilder, but built for nested safes (Safes where the signers are other Safes).
 */
abstract contract NestedMultisigBuilder is MultisigBase {
    /**
     * -----------------------------------------------------------
     * Virtual Functions
     * -----------------------------------------------------------
     */

    /**
     * @notice Returns the nested safe address to execute the final transaction from.
     */
    function _ownerSafe() internal view virtual returns (address);

    /**
     * @notice Creates the calldata for both signatures (`sign`) and execution (`run`).
     */
    function _buildCalls() internal view virtual returns (IMulticall3.Call3[] memory);

    /**
     * @notice Follow-up assertions to ensure the script ran to completion.
     * @dev Called after `sign` and `run`, but not `approve`.
     */
    function _postCheck(Vm.AccountAccess[] memory accesses, Simulation.Payload memory simPayload) internal virtual;

    /**
     * @notice Follow-up assertions on state and simulation after a `sign` call.
     */
    function _postSign(Vm.AccountAccess[] memory accesses, Simulation.Payload memory simPayload) internal virtual {}

    /**
     * @notice Follow-up assertions on state and simulation after an `approve` call.
     */
    function _postApprove(Vm.AccountAccess[] memory accesses, Simulation.Payload memory simPayload) internal virtual {}

    /**
     * @notice Follow-up assertions on state and simulation after a `run` call.
     */
    function _postRun(Vm.AccountAccess[] memory accesses, Simulation.Payload memory simPayload) internal virtual {}

    /**
     * -----------------------------------------------------------
     * Implemented Functions
     * -----------------------------------------------------------
     */

    /**
     * Step 1: Generate a transaction approval data to sign.
     * This method should be called by a threshold of members of each of the multisigs involved.
     * @param _signerSafe Address of the signer safe.
     */
    function sign(address _signerSafe) public {
        address nestedSafe = _ownerSafe();

        uint256 originalNonce = _getNonce(nestedSafe);
        uint256 originalSignerNonce = _getNonce(_signerSafe);

        IMulticall3.Call3[] memory nestedCalls = _buildCalls();
        IMulticall3.Call3 memory call = _generateApproveCall(nestedSafe, nestedCalls);

        (Vm.AccountAccess[] memory accesses, Simulation.Payload memory simPayload) =
            _simulateForSigner(_signerSafe, nestedSafe, nestedCalls);
        _postSign(accesses, simPayload);
        _postCheck(accesses, simPayload);

        // Restore the original nonce.
        vm.store(nestedSafe, SAFE_NONCE_SLOT, bytes32(originalNonce));
        vm.store(_signerSafe, SAFE_NONCE_SLOT, bytes32(originalSignerNonce));

        _printDataToSign(_signerSafe, _toArray(call));
    }

    /**
     * Step 1.1 (Optional): Verify that the signatures generated are valid.
     * @param _signerSafe Address of the signer safe.
     * @param _signatures Signatures to verify.
     */
    function verify(address _signerSafe, bytes memory _signatures) public view {
        IMulticall3.Call3[] memory nestedCalls = _buildCalls();
        IMulticall3.Call3 memory call = _generateApproveCall(_ownerSafe(), nestedCalls);
        _checkSignatures(_signerSafe, _toArray(call), _signatures);
    }

    /**
     * Step 2: Execute an approval transaction.
     * This method should be called by a facilitator after collecting signatures.
     * @param _signerSafe Address of the signer safe.
     * @param _signatures Signatures to use for the approval.
     */
    function approve(address _signerSafe, bytes memory _signatures) public {
        IMulticall3.Call3[] memory nestedCalls = _buildCalls();
        IMulticall3.Call3 memory call = _generateApproveCall(_ownerSafe(), nestedCalls);

        (Vm.AccountAccess[] memory accesses, Simulation.Payload memory simPayload) =
            _executeTransaction(_signerSafe, _toArray(call), _signatures, true);

        _postApprove(accesses, simPayload);
    }

    /**
     * Step 3: Execute the transaction.
     * This method should be called by a facilitator after all approvals are submitted on-chain.
     */
    function run() public {
        IMulticall3.Call3[] memory nestedCalls = _buildCalls();

        // Signatures are empty because `_executeTransaction` collects approved hashes internally.
        bytes memory signatures;

        (Vm.AccountAccess[] memory accesses, Simulation.Payload memory simPayload) =
            _executeTransaction(_ownerSafe(), nestedCalls, signatures, true);

        _postRun(accesses, simPayload);
        _postCheck(accesses, simPayload);
    }

    /**
     * Utility function to determine if SAFE_NONCE can be read.
     * @return Always false in this implementation.
     */
    function _readFrom_SAFE_NONCE() internal pure override returns (bool) {
        return false;
    }

    /**
     * Generates a call to approve a hash.
     * @param _safe The safe address.
     * @param _calls The calls to approve.
     * @return The generated call.
     */
    function _generateApproveCall(address _safe, IMulticall3.Call3[] memory _calls)
        internal
        view
        returns (IMulticall3.Call3 memory)
    {
        bytes32 hash = _getTransactionHash(_safe, _calls);

        console.log("---\nNested hash:");
        console.logBytes32(hash);

        return IMulticall3.Call3({
            target: _safe,
            allowFailure: false,
            callData: abi.encodeCall(IGnosisSafe(_safe).approveHash, (hash))
        });
    }

    // Additional functions for simulation, overrides, and array conversions omitted for brevity.
}
