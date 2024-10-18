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

    // Virtual method which can be overwritten.
    // This allows different nonce overrides for each safe in the nested multisig case.
    // IMPORTANT: this method is used in the sign, simulate, AND execution contexts
    // If you override it, ensure that the behavior is correct for all contexts
    // As an example, if you are pre-signing a message that needs safe.nonce+1 (before safe.nonce is executed),
    // you should explicitly set the nonce value with an env var.
    // Overwriting this method with safe.nonce + 1 will cause issues upon execution because the transaction
    // hash will differ from the one signed.
    function _getNonce(IGnosisSafe safe) internal view override virtual returns (uint256 nonce) {
        string memory safeAddrStr = vm.toString(address(safe));
        nonce = safe.nonce();
        console.log("Safe", safeAddrStr, "current nonce:", nonce);

        // In this overridden method, the process for determining the nonce is as follows:
        //   1. We look for an env var of the name SAFE_NONCE_{UPPERCASE_SAFE_ADDRESS}. For example,
        //      SAFE_NONCE_0X6DF4742A3C28790E63FE933F7D108FE9FCE51EA4.
        //   2. If it exists, we use it as the nonce override for the safe.
        //   3. If it does not exist, we use the current nonce of the safe.
        //   4. We explicitly do not use SAFE_NONCE as a fallback, because in the nested case it is
        //      ambiguous which safe it refers to.
        string memory safeNonceEnvVarName = string.concat("SAFE_NONCE_", vm.toUppercase(safeAddrStr));
        try vm.envUint(safeNonceEnvVarName) {
            nonce = vm.envUint(safeNonceEnvVarName);
            console.log("Creating transaction with nonce:", nonce);
        }
        catch {}
    }

    /**
     * Step 1
     * ======
     * Generate a transaction approval data to sign. This method should be called by a threshold
     * of members of each of the multisigs involved in the nested multisig. Signers will pass
     * their signature to a facilitator, who will execute the approval transaction for each
     * multisig (see step 2).
     */
    function sign(address _signerSafe) public {
        address nestedSafeAddress = _ownerSafe();

        // Snapshot and restore Safe nonce after simulation, otherwise the data logged to sign
        // would not match the actual data we need to sign, because the simulation
        // would increment the nonce.
        uint256 originalNonce = _getNonce(IGnosisSafe(nestedSafeAddress));
        uint256 originalSignerNonce = _getNonce(IGnosisSafe(_signerSafe));

        IMulticall3.Call3[] memory nestedCalls = _buildCalls();
        IMulticall3.Call3 memory call = _generateApproveCall(nestedSafeAddress, nestedCalls);
        bytes32 hash = _getTransactionHash(_signerSafe, toArray(call));

        console.log("---\nIf submitting onchain, call Safe.approveHash on %s with the following hash:", _signerSafe);
        console.logBytes32(hash);
        (Vm.AccountAccess[] memory accesses, SimulationPayload memory simPayload) = _simulateForSigner(_signerSafe, nestedSafeAddress, nestedCalls);
        _postCheck(accesses, simPayload);

        // Restore the original nonce.
        vm.store(nestedSafeAddress, SAFE_NONCE_SLOT, bytes32(uint256(originalNonce)));
        vm.store(_signerSafe, SAFE_NONCE_SLOT, bytes32(uint256(originalSignerNonce)));

        _printDataToSign(_signerSafe, toArray(call));
    }

    /**
     * Step 2
     * ======
     * Execute an approval transaction. This method should be called by a facilitator
     * (non-signer), once for each of the multisigs involved in the nested multisig,
     * after collecting a threshold of signatures for each multisig (see step 1).
     */
    function approve(address _signerSafe, bytes memory _signatures) public {
        address nestedSafeAddress = _ownerSafe();
        IMulticall3.Call3[] memory nestedCalls = _buildCalls();
        IMulticall3.Call3 memory call = _generateApproveCall(nestedSafeAddress, nestedCalls);

        address[] memory approvers = _getApprovers(_signerSafe, toArray(call));
        _signatures = bytes.concat(_signatures, prevalidatedSignatures(approvers));

        vm.startBroadcast();
        (Vm.AccountAccess[] memory accesses, SimulationPayload memory simPayload) = _executeTransaction(_signerSafe, toArray(call), _signatures);
        vm.stopBroadcast();

        _postCheck(accesses, simPayload);
    }

    /**
     * Step 3
     * ======
     * Execute the transaction. This method should be called by a facilitator (non-signer), after
     * all of the approval transactions have been submitted onchain (see step 2).
     */
    function run() public {
        address nestedSafeAddress = _ownerSafe();
        IMulticall3.Call3[] memory nestedCalls = _buildCalls();
        address[] memory approvers = _getApprovers(nestedSafeAddress, nestedCalls);
        bytes memory signatures = prevalidatedSignatures(approvers);

        vm.startBroadcast();
        (Vm.AccountAccess[] memory accesses, SimulationPayload memory simPayload) = _executeTransaction(nestedSafeAddress, nestedCalls, signatures);
        vm.stopBroadcast();

        _postCheck(accesses, simPayload);
    }

    function _generateApproveCall(address _safe, IMulticall3.Call3[] memory _calls) internal view returns (IMulticall3.Call3 memory) {
        IGnosisSafe safe = IGnosisSafe(payable(_safe));
        bytes32 hash = _getTransactionHash(_safe, _calls);

        console.log("---\nNested hash:");
        console.logBytes32(hash);

        return IMulticall3.Call3({
            target: _safe,
            allowFailure: false,
            callData: abi.encodeCall(safe.approveHash, (hash))
        });
    }

    function _getApprovers(address _safe, IMulticall3.Call3[] memory _calls) internal view returns (address[] memory) {
        IGnosisSafe safe = IGnosisSafe(payable(_safe));
        bytes32 hash = _getTransactionHash(_safe, _calls);

        // get a list of owners that have approved this transaction
        uint256 threshold = safe.getThreshold();
        address[] memory owners = safe.getOwners();
        address[] memory approvers = new address[](threshold);
        uint256 approverIndex;
        for (uint256 i; i < owners.length; i++) {
            address owner = owners[i];
            uint256 approved = safe.approvedHashes(owner, hash);
            if (approved == 1) {
                approvers[approverIndex] = owner;
                approverIndex++;
                if (approverIndex == threshold) {
                    return approvers;
                }
            }
        }
        address[] memory subset = new address[](approverIndex);
        for (uint256 i; i < approverIndex; i++) {
            subset[i] = approvers[i];
        }
        return subset;
    }

    function _simulateForSigner(address _signerSafe, address _safe, IMulticall3.Call3[] memory _calls)
        internal
        returns (Vm.AccountAccess[] memory, SimulationPayload memory)
    {
        IGnosisSafe safe = IGnosisSafe(payable(_safe));
        IGnosisSafe signerSafe = IGnosisSafe(payable(_signerSafe));
        bytes memory data = abi.encodeCall(IMulticall3.aggregate3, (_calls));
        bytes32 hash = _getTransactionHash(_safe, data);
        IMulticall3.Call3[] memory calls = new IMulticall3.Call3[](2);

        // simulate an approveHash, so that signer can verify the data they are signing
        bytes memory approveHashData = abi.encodeCall(IMulticall3.aggregate3, (toArray(
            IMulticall3.Call3({
                target: _safe,
                allowFailure: false,
                callData: abi.encodeCall(safe.approveHash, (hash))
            })
        )));
        bytes memory approveHashExec = abi.encodeCall(
            signerSafe.execTransaction,
            (
                address(multicall),
                0,
                approveHashData,
                Enum.Operation.DelegateCall,
                0,
                0,
                0,
                address(0),
                payable(address(0)),
                prevalidatedSignature(address(multicall))
            )
        );
        calls[0] = IMulticall3.Call3({
            target: _signerSafe,
            allowFailure: false,
            callData: approveHashExec
        });

        // simulate the final state changes tx, so that signer can verify the final results
        bytes memory finalExec = abi.encodeCall(
            safe.execTransaction,
            (
                address(multicall),
                0,
                data,
                Enum.Operation.DelegateCall,
                0,
                0,
                0,
                address(0),
                payable(address(0)),
                prevalidatedSignature(_signerSafe)
            )
        );
        calls[1] = IMulticall3.Call3({
            target: _safe,
            allowFailure: false,
            callData: finalExec
        });

        // For each safe, determine if a nonce override is needed. At this point,
        // no state overrides (i.e. vm.store) have been applied to the Foundry VM,
        // meaning the nonce is not yet overriden. Therefore these calls to
        // `safe.nonce()` will correctly return the current nonce of the safe.
        bool safeNonceOverride = _getNonce(safe) != safe.nonce();
        bool signerSafeNonceOverride = _getNonce(signerSafe) != signerSafe.nonce();

        // Now define the state overrides for the simulation.
        SimulationStateOverride[] memory overrides = new SimulationStateOverride[](2);
        // The state change simulation sets the multisig threshold to 1 in the
        // simulation to enable an approver to see what the final state change
        // will look like upon transaction execution. The multisig threshold
        // will not actually change in the transaction execution.
        if (safeNonceOverride) {
            overrides[0] = overrideSafeThresholdAndNonce(_safe, _getNonce(safe));
        } else {
            overrides[0] = overrideSafeThreshold(_safe);
        }
        // Set the signer safe threshold to 1, and set the owner to multicall.
        // This is a little hacky; reason is to simulate both the approve hash
        // and the final tx in a single Tenderly tx, using multicall. Given an
        // EOA cannot DELEGATECALL, multicall needs to own the signer safe.
        if (signerSafeNonceOverride) {
            overrides[1] = overrideSafeThresholdOwnerAndNonce(_signerSafe, address(multicall), _getNonce(signerSafe));
        } else {
            overrides[1] = overrideSafeThresholdAndOwner(_signerSafe, address(multicall));
        }

        bytes memory txData = abi.encodeCall(IMulticall3.aggregate3, (calls));
        console.log("---\nSimulation link:");
        logSimulationLink({
            _to: address(multicall),
            _data: txData,
            _from: msg.sender,
            _overrides: overrides
        });

        // Forge simulation of the data logged in the link. If the simulation fails
        // we revert to make it explicit that the simulation failed.
        SimulationPayload memory simPayload = SimulationPayload({
            to: address(multicall),
            data: txData,
            from: msg.sender,
            stateOverrides: overrides
        });
        Vm.AccountAccess[] memory accesses = simulateFromSimPayload(simPayload);
        return (accesses, simPayload);
    }
}
