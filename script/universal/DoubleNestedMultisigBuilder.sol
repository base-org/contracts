// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./NestedMultisigBase.sol";

/**
 * @title DoubleNestedMultisigBuilder
 * @notice Modeled from Optimism's SafeBuilder, but built for double nested safes (Safes where the signers are other Safes with signers that are other Safes).
 */
abstract contract DoubleNestedMultisigBuilder is NestedMultisigBase {
    /**
     * @notice Returns the intermediate safe address to execute the final approval transaction from
     */
    function _intermediateSafe() internal view virtual returns (address);

    /**
     * @notice Returns the signer safe address to execute the initial approval transaction from
     */
    function _signerSafe() internal view virtual returns (address);

    /**
     * Step 1
     * ======
     * Generate a transaction approval data to sign. This method should be called by a threshold
     * of members of each of the multisigs involved in the nested multisig. Signers will pass
     * their signature to a facilitator, who will execute the approval transaction for each
     * multisig (see step 2).
     */
    function sign() public {
        address signerSafe = _signerSafe();
        address intermediateSafe = _intermediateSafe();
        address topSafe = _ownerSafe();

        // Snapshot and restore Safe nonce after simulation, otherwise the data logged to sign
        // would not match the actual data we need to sign, because the simulation
        // would increment the nonce.
        uint256 originalTopNonce = _getNonce(topSafe);
        uint256 originalIntermediateNonce = _getNonce(intermediateSafe);
        uint256 originalSignerNonce = _getNonce(signerSafe);

        IMulticall3.Call3[] memory dstCalls = _buildCalls();
        IMulticall3.Call3 memory topSafeApprovalCall = _generateApproveCall(topSafe, dstCalls);
        IMulticall3.Call3 memory intermediateSafeApprovalCall =
            _generateApproveCall(intermediateSafe, _toArray(topSafeApprovalCall));

        (Vm.AccountAccess[] memory accesses, Simulation.Payload memory simPayload) =
            _simulateForSigner(intermediateSafe, topSafe, dstCalls);
        _postSign(accesses, simPayload);
        _postCheck(accesses, simPayload);

        // Restore the original nonce.
        vm.store(topSafe, SAFE_NONCE_SLOT, bytes32(originalTopNonce));
        vm.store(intermediateSafe, SAFE_NONCE_SLOT, bytes32(originalIntermediateNonce));
        vm.store(signerSafe, SAFE_NONCE_SLOT, bytes32(originalSignerNonce));

        _printDataToSign(signerSafe, _toArray(intermediateSafeApprovalCall));
    }

    /**
     * Step 1.1 (optional)
     * ======
     * Verify the signatures generated from step 1 are valid.
     * This allow transactions to be pre-signed and stored safely before execution.
     */
    function verify(bytes memory _signatures) public view {
        IMulticall3.Call3 memory topSafeApprovalCall = _generateApproveCall(_ownerSafe(), _buildCalls());
        IMulticall3.Call3 memory intermediateSafeApprovalCall =
            _generateApproveCall(_intermediateSafe(), _toArray(topSafeApprovalCall));
        _checkSignatures(_signerSafe(), _toArray(intermediateSafeApprovalCall), _signatures);
    }

    /**
     * Step 2
     * ======
     * Execute an approval transaction. This method should be called by a facilitator
     * (non-signer), once for each of the multisigs involved in the nested multisig,
     * after collecting a threshold of signatures for each multisig (see step 1).
     */
    function approveInit(bytes memory _signatures) public {
        IMulticall3.Call3[] memory dstCalls = _buildCalls();
        IMulticall3.Call3 memory topSafeApprovalCall = _generateApproveCall(_ownerSafe(), dstCalls);
        IMulticall3.Call3 memory intermediateSafeApprovalCall =
            _generateApproveCall(_intermediateSafe(), _toArray(topSafeApprovalCall));

        (Vm.AccountAccess[] memory accesses, Simulation.Payload memory simPayload) =
            _executeTransaction(_signerSafe(), _toArray(intermediateSafeApprovalCall), _signatures, true);

        _postApprove();
    }

    /**
     * Step 3
     * ======
     * Execute the transaction. This method should be called by a facilitator (non-signer), after
     * all of the approval transactions have been submitted onchain (see step 2).
     */
    function runInit() public {
        IMulticall3.Call3[] memory dstCalls = _buildCalls();
        IMulticall3.Call3 memory topSafeApprovalCall = _generateApproveCall(_ownerSafe(), dstCalls);

        // signatures is empty, because `_executeTransaction` internally collects all of the approvedHash addresses
        bytes memory signatures;

        (Vm.AccountAccess[] memory accesses, Simulation.Payload memory simPayload) =
            _executeTransaction(_intermediateSafe(), _toArray(topSafeApprovalCall), signatures, true);

        _postRunInit();
    }

    function run() public {
        IMulticall3.Call3[] memory dstCalls = _buildCalls();

        // signatures is empty, because `_executeTransaction` internally collects all of the approvedHash addresses
        bytes memory signatures;

        (Vm.AccountAccess[] memory accesses, Simulation.Payload memory simPayload) =
            _executeTransaction(_ownerSafe(), dstCalls, signatures, true);

        _postRun(accesses, simPayload);
        _postCheck(accesses, simPayload);
    }

    /**
     * @dev Follow up assertions on state and simulation after an `approve` call.
     */
    function _postApprove() private view {
        IMulticall3.Call3 memory topSafeApprovalCall = _generateApproveCall(_ownerSafe(), _buildCalls());
        bytes memory data = abi.encodeCall(IMulticall3.aggregate3, _toArray(topSafeApprovalCall));
        bytes32 approvedHash = _getTransactionHash(_intermediateSafe(), data);

        uint256 isApproved = IGnosisSafe(_intermediateSafe()).approvedHashes(_signerSafe(), approvedHash);
        require(isApproved == 1, "DoubleNestedMultisigBuilder::_postApprove: Approval failed");
    }

    /**
     * @dev Follow up assertions on state and simulation after an `approve` call.
     */
    function _postRunInit() private view {
        bytes memory data = abi.encodeCall(IMulticall3.aggregate3, _buildCalls());
        bytes32 approvedHash = _getTransactionHash(_ownerSafe(), data);

        uint256 isApproved = IGnosisSafe(_ownerSafe()).approvedHashes(_intermediateSafe(), approvedHash);
        require(isApproved == 1, "DoubleNestedMultisigBuilder::_postApprove: Approval failed");
    }
}
