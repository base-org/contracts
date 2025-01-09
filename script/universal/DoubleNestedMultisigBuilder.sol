// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./NestedMultisigBase.sol";

/**
 * @title DoubleNestedMultisigBuilder
 * @notice Modeled from Optimism's SafeBuilder, but built for double nested safes (Safes where
 * the signers are other Safes with signers that are other Safes).
 *
 * There are three safes involved in a double nested multisig:
 * 1. The top-level safe, which should be returned by `_ownerSafe()`.
 * 2. One or more intermediate safes, which are signers for the top-level safe.
 * 3. Signer safes, which are signers for the intermediate safes. There should be at least one signer safe per intermediate safe.
 */
abstract contract DoubleNestedMultisigBuilder is NestedMultisigBase {
    /**
     * Step 1
     * ======
     * Generate a transaction approval data to sign. This method should be called by a threshold
     * of members of each of the signer safes involved in the nested multisig. Signers will pass
     * their signature to a facilitator, who will execute the approval transaction for each
     * signer safe (see step 2).
     */
    function sign(address signerSafe, address intermediateSafe) public {
        address topSafe = _ownerSafe();

        // Snapshot and restore Safe nonce after simulation, otherwise the data logged to sign
        // would not match the actual data we need to sign, because the simulation
        // would increment the nonce.
        uint256 originalTopNonce = _getNonce(topSafe);
        uint256 originalIntermediateNonce = _getNonce(intermediateSafe);
        uint256 originalSignerNonce = _getNonce(signerSafe);

        (Vm.AccountAccess[] memory accesses, Simulation.Payload memory simPayload) =
            _simulateForSigner(intermediateSafe, topSafe, _buildCalls());

        _postSign(accesses, simPayload);
        _postCheck(accesses, simPayload);

        // Restore the original nonce.
        vm.store(topSafe, SAFE_NONCE_SLOT, bytes32(originalTopNonce));
        vm.store(intermediateSafe, SAFE_NONCE_SLOT, bytes32(originalIntermediateNonce));
        vm.store(signerSafe, SAFE_NONCE_SLOT, bytes32(originalSignerNonce));

        _printDataToSign(signerSafe, _generateIntermediateSafeApprovalCall(intermediateSafe));
    }

    /**
     * Step 1.1 (optional)
     * ======
     * Verify the signatures generated from step 1 are valid.
     * This allow transactions to be pre-signed and stored safely before execution.
     */
    function verify(address signerSafe, address intermediateSafe, bytes memory signatures) public view {
        IMulticall3.Call3[] memory calls = _generateIntermediateSafeApprovalCall(intermediateSafe);
        _checkSignatures(signerSafe, calls, signatures);
    }

    /**
     * Step 2
     * ======
     * Execute an approval transaction for a signer safe. This method should be called by a facilitator
     * (non-signer), once for each of the signer safes involved in the nested multisig,
     * after collecting a threshold of signatures for each signer safe (see step 1).
     */
    function approveInit(address signerSafe, address intermediateSafe, bytes memory signatures) public {
        IMulticall3.Call3[] memory calls = _generateIntermediateSafeApprovalCall(intermediateSafe);

        (Vm.AccountAccess[] memory accesses, Simulation.Payload memory simPayload) =
            _executeTransaction(signerSafe, calls, signatures, true);

        _postApprove(signerSafe, intermediateSafe);
    }

    /**
     * Step 3
     * ======
     * Execute an approval transaction for an intermediate safe. This method should be called by a
     * facilitator (non-signer), for each of the intermediate safes after all of their approval
     * transactions have been submitted onchain by their signer safes (see step 2).
     */
    function runInit(address intermediateSafe) public {
        IMulticall3.Call3[] memory calls = _generateTopSafeApprovalCall();

        // signatures is empty, because `_executeTransaction` internally collects all of the approvedHash addresses
        bytes memory signatures;

        (Vm.AccountAccess[] memory accesses, Simulation.Payload memory simPayload) =
            _executeTransaction(intermediateSafe, calls, signatures, true);

        _postRunInit(intermediateSafe);
    }

    /**
     * Step 4
     * ======
     * Execute the final transaction. This method should be called by a facilitator (non-signer), after
     * all of the intermediate safe approval transactions have been submitted onchain (see step 3).
     */
    function run() public {
        IMulticall3.Call3[] memory calls = _buildCalls();

        // signatures is empty, because `_executeTransaction` internally collects all of the approvedHash addresses
        bytes memory signatures;

        (Vm.AccountAccess[] memory accesses, Simulation.Payload memory simPayload) =
            _executeTransaction(_ownerSafe(), calls, signatures, true);

        _postRun(accesses, simPayload);
        _postCheck(accesses, simPayload);
    }

    /**
     * @dev Follow up assertions on state and simulation after an `approve` call.
     */
    function _postApprove(address signerSafe, address intermediateSafe) private view {
        IMulticall3.Call3 memory topSafeApprovalCall = _generateApproveCall(_ownerSafe(), _buildCalls());
        bytes memory data = abi.encodeCall(IMulticall3.aggregate3, _toArray(topSafeApprovalCall));
        bytes32 approvedHash = _getTransactionHash(intermediateSafe, data);

        uint256 isApproved = IGnosisSafe(intermediateSafe).approvedHashes(signerSafe, approvedHash);
        require(isApproved == 1, "DoubleNestedMultisigBuilder::_postApprove: Approval failed");
    }

    /**
     * @dev Follow up assertions on state and simulation after an `init` call.
     */
    function _postRunInit(address intermediateSafe) private view {
        bytes memory data = abi.encodeCall(IMulticall3.aggregate3, _buildCalls());
        bytes32 approvedHash = _getTransactionHash(_ownerSafe(), data);

        uint256 isApproved = IGnosisSafe(_ownerSafe()).approvedHashes(intermediateSafe, approvedHash);
        require(isApproved == 1, "DoubleNestedMultisigBuilder::_postRunInit: Init transaction failed");
    }

    function _generateIntermediateSafeApprovalCall(address intermediateSafe)
        private
        view
        returns (IMulticall3.Call3[] memory)
    {
        IMulticall3.Call3[] memory topCalls = _generateTopSafeApprovalCall();
        IMulticall3.Call3 memory intermediateCall = _generateApproveCall(intermediateSafe, topCalls);
        return _toArray(intermediateCall);
    }

    function _generateTopSafeApprovalCall() private view returns (IMulticall3.Call3[] memory) {
        IMulticall3.Call3[] memory dstCalls = _buildCalls();
        IMulticall3.Call3 memory topSafeApprovalCall = _generateApproveCall(_ownerSafe(), dstCalls);
        return _toArray(topSafeApprovalCall);
    }
}
