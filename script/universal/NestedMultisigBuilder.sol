// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./MultisigBase.sol";

import { console } from "forge-std/console.sol";
import { IMulticall3 } from "forge-std/interfaces/IMulticall3.sol";

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
     * @notice Follow up assertions to ensure that the script ran to completion
     */
    function _postCheck(Vm.AccountAccess[] memory accesses, SimulationPayload memory simPayload) internal virtual;

    /**
     * @notice Creates the calldata
     */
    function _buildCalls() internal virtual view returns (IMulticall3.Call3[] memory);

    /**
     * @notice Returns the nested safe address to execute the final transaction from
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
     * Generate a transaction approval data to sign. This method should be called by a threshold
     * of members of each of the multisigs involved in the nested multisig. Signers will pass
     * their signature to a facilitator, who will execute the approval transaction for each
     * multisig (see step 2).
     */
    function sign(IGnosisSafe _signerSafe) public {
        IGnosisSafe nestedSafe = IGnosisSafe(_ownerSafe());

        // Snapshot and restore Safe nonce after simulation, otherwise the data logged to sign
        // would not match the actual data we need to sign, because the simulation
        // would increment the nonce.
        uint256 originalNonce = _getNonce(nestedSafe);
        uint256 originalSignerNonce = _getNonce(_signerSafe);

        IMulticall3.Call3[] memory nestedCalls = _buildCalls();
        IMulticall3.Call3 memory call = _generateApproveCall(nestedSafe, nestedCalls);
        bytes32 hash = _getTransactionHash(_signerSafe, toArray(call));

        console.log("---\nIf submitting onchain, call Safe.approveHash on %s with the following hash:", address(_signerSafe));
        console.logBytes32(hash);

        (Vm.AccountAccess[] memory accesses, SimulationPayload memory simPayload) = _simulateForSigner(_signerSafe, nestedSafe, nestedCalls);
        _postCheck(accesses, simPayload);

        // Restore the original nonce.
        vm.store(address(nestedSafe), SAFE_NONCE_SLOT, bytes32(uint256(originalNonce)));
        vm.store(address(_signerSafe), SAFE_NONCE_SLOT, bytes32(uint256(originalSignerNonce)));

        _printDataToSign(_signerSafe, toArray(call));
    }

    /**
     * Step 2
     * ======
     * Execute an approval transaction. This method should be called by a facilitator
     * (non-signer), once for each of the multisigs involved in the nested multisig,
     * after collecting a threshold of signatures for each multisig (see step 1).
     */
    function approve(IGnosisSafe _signerSafe, bytes memory _signatures) public {
        IGnosisSafe nestedSafe = IGnosisSafe(_ownerSafe());
        IMulticall3.Call3[] memory nestedCalls = _buildCalls();
        IMulticall3.Call3 memory call = _generateApproveCall(nestedSafe, nestedCalls);

        vm.startBroadcast();
        (Vm.AccountAccess[] memory accesses, SimulationPayload memory simPayload) = _executeTransaction(_signerSafe, toArray(call), _signatures);
        vm.stopBroadcast();
    }

    /**
     * Step 3
     * ======
     * Execute the transaction. This method should be called by a facilitator (non-signer), after
     * all of the approval transactions have been submitted onchain (see step 2).
     */
    function run() public {
        IGnosisSafe nestedSafe = IGnosisSafe(_ownerSafe());
        IMulticall3.Call3[] memory nestedCalls = _buildCalls();

        // signatures is empty, because `_executeTransaction` internally collects all of the approvedHash addresses
        bytes memory signatures;

        vm.startBroadcast();
        (Vm.AccountAccess[] memory accesses, SimulationPayload memory simPayload) = _executeTransaction(nestedSafe, nestedCalls, signatures);
        vm.stopBroadcast();

        _postCheck(accesses, simPayload);
    }

    function _readFrom_SAFE_NONCE() internal pure override returns (bool) {
        return false;
    }

    function _generateApproveCall(IGnosisSafe _safe, IMulticall3.Call3[] memory _calls) internal view returns (IMulticall3.Call3 memory) {
        bytes32 hash = _getTransactionHash(_safe, _calls);

        console.log("---\nNested hash:");
        console.logBytes32(hash);

        return IMulticall3.Call3({
            target: address(_safe),
            allowFailure: false,
            callData: abi.encodeCall(_safe.approveHash, (hash))
        });
    }

    function _simulateForSigner(IGnosisSafe _signerSafe, IGnosisSafe _safe, IMulticall3.Call3[] memory _calls)
        internal
        returns (Vm.AccountAccess[] memory, SimulationPayload memory)
    {
        bytes memory data = abi.encodeCall(IMulticall3.aggregate3, (_calls));
        IMulticall3.Call3[] memory calls = _simulateForSignerCalls(_signerSafe, _safe, data);

        // For each safe, determine if a nonce override is needed. At this point,
        // no state overrides (i.e. vm.store) have been applied to the Foundry VM,
        // meaning the nonce is not yet overriden. Therefore these calls to
        // `safe.nonce()` will correctly return the current nonce of the safe.
        bool safeNonceOverride = _getNonce(_safe) != _safe.nonce();
        bool signerSafeNonceOverride = _getNonce(_signerSafe) != _signerSafe.nonce();

        // Now define the state overrides for the simulation.
        SimulationStateOverride[] memory overrides = new SimulationStateOverride[](2);
        // The state change simulation sets the multisig threshold to 1 in the
        // simulation to enable an approver to see what the final state change
        // will look like upon transaction execution. The multisig threshold
        // will not actually change in the transaction execution.
        if (safeNonceOverride) {
            overrides[0] = overrideSafeThresholdAndNonce(address(_safe), _getNonce(_safe));
        } else {
            overrides[0] = overrideSafeThreshold(address(_safe));
        }
        // Set the signer safe threshold to 1, and set the owner to multicall.
        // This is a little hacky; reason is to simulate both the approve hash
        // and the final tx in a single Tenderly tx, using multicall. Given an
        // EOA cannot DELEGATECALL, multicall needs to own the signer safe.
        if (signerSafeNonceOverride) {
            overrides[1] = overrideSafeThresholdOwnerAndNonce(address(_signerSafe), MULTICALL3_ADDRESS, _getNonce(_signerSafe));
        } else {
            overrides[1] = overrideSafeThresholdAndOwner(address(_signerSafe), MULTICALL3_ADDRESS);
        }

        bytes memory txData = abi.encodeCall(IMulticall3.aggregate3, (calls));
        console.log("---\nSimulation link:");
        logSimulationLink({
            _to: MULTICALL3_ADDRESS,
            _data: txData,
            _from: msg.sender,
            _overrides: overrides
        });

        // Forge simulation of the data logged in the link. If the simulation fails
        // we revert to make it explicit that the simulation failed.
        SimulationPayload memory simPayload = SimulationPayload({
            to: MULTICALL3_ADDRESS,
            data: txData,
            from: msg.sender,
            stateOverrides: overrides
        });
        Vm.AccountAccess[] memory accesses = simulateFromSimPayload(simPayload);
        return (accesses, simPayload);
    }

    function _simulateForSignerCalls(IGnosisSafe _signerSafe, IGnosisSafe _safe, bytes memory _data)
        internal view
        returns (IMulticall3.Call3[] memory)
    {
        IMulticall3.Call3[] memory calls = new IMulticall3.Call3[](2);
        bytes32 hash = _getTransactionHash(_safe, _data);

        // simulate an approveHash, so that signer can verify the data they are signing
        bytes memory approveHashData = abi.encodeCall(IMulticall3.aggregate3, (toArray(
            IMulticall3.Call3({
                target: address(_safe),
                allowFailure: false,
                callData: abi.encodeCall(_safe.approveHash, (hash))
            })
        )));
        bytes memory approveHashExec = _execTransationCalldata(_signerSafe, approveHashData, genPrevalidatedSignature(MULTICALL3_ADDRESS));
        calls[0] = IMulticall3.Call3({
            target: address(_signerSafe),
            allowFailure: false,
            callData: approveHashExec
        });

        // simulate the final state changes tx, so that signer can verify the final results
        bytes memory finalExec = _execTransationCalldata(_safe, _data, genPrevalidatedSignature(address(_signerSafe)));
        calls[1] = IMulticall3.Call3({
            target: address(_safe),
            allowFailure: false,
            callData: finalExec
        });

        return calls;
    }
}
