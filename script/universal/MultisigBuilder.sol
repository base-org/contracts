// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

// solhint-disable no-console
import {console} from "forge-std/console.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";
import {Vm} from "forge-std/Vm.sol";

import {IGnosisSafe} from "./IGnosisSafe.sol";
import {MultisigBase} from "./MultisigBase.sol";
import {Signatures} from "./Signatures.sol";
import {Simulation} from "./Simulation.sol";

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
     * @notice Returns the safe address to execute the transaction from
     */
    function _ownerSafe() internal view virtual returns (address);

    /**
     * @notice Creates the calldata for both signatures (`sign`) and execution (`run`)
     */
    function _buildCalls() internal view virtual returns (IMulticall3.Call3[] memory);

    /**
     * @notice Follow up assertions to ensure that the script ran to completion.
     */
    function _postCheck(Vm.AccountAccess[] memory accesses, Simulation.Payload memory simPayload) internal virtual;

    /**
     * @notice Follow up assertions on state and simulation after a `sign` call.
     */
    function _postSign(Vm.AccountAccess[] memory accesses, Simulation.Payload memory simPayload) internal virtual {}

    /**
     * @notice Follow up assertions on state and simulation after a `run` call.
     */
    function _postRun(Vm.AccountAccess[] memory accesses, Simulation.Payload memory simPayload) internal virtual {}

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
    function sign() public {
        address safe = _ownerSafe();

        // Snapshot and restore Safe nonce after simulation, otherwise the data logged to sign
        // would not match the actual data we need to sign, because the simulation
        // would increment the nonce.
        uint256 _nonce = _getNonce(safe);

        IMulticall3.Call3[] memory calls = _buildCalls();
        (Vm.AccountAccess[] memory accesses, Simulation.Payload memory simPayload) = _simulateForSigner(safe, calls);
        _postSign(accesses, simPayload);
        _postCheck(accesses, simPayload);

        // Restore the original nonce.
        vm.store(safe, SAFE_NONCE_SLOT, bytes32(_nonce));

        _printDataToSign(safe, calls);
    }

    /**
     * Step 1.1 (optional)
     * ======
     * Verify the signatures generated from step 1 are valid.
     * This allow transactions to be pre-signed and stored safely before execution.
     */
    function verify(bytes memory _signatures) public view {
        _checkSignatures(_ownerSafe(), _buildCalls(), _signatures);
    }

    /**
     * Step 1.2 (optional)
     * ======
     * Simulate the transaction. This method can be called by the final member of the multisig
     * that will execute the transaction. Signatures from step 1 are required.
     *
     * Differs from `run` in that you can override the safe nonce for simulation purposes.
     */
    function simulate(bytes memory _signatures) public {
        address safe = _ownerSafe();
        vm.store(safe, SAFE_NONCE_SLOT, bytes32(_getNonce(safe)));

        (Vm.AccountAccess[] memory accesses, Simulation.Payload memory simPayload) =
            _executeTransaction(safe, _buildCalls(), _signatures, false);

        _postRun(accesses, simPayload);
        _postCheck(accesses, simPayload);
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
    function run(bytes memory _signatures) public {
        (Vm.AccountAccess[] memory accesses, Simulation.Payload memory simPayload) =
            _executeTransaction(_ownerSafe(), _buildCalls(), _signatures, true);

        _postRun(accesses, simPayload);
        _postCheck(accesses, simPayload);
    }

    /**
     * Print the current safe nonce.
     */
    function nonce() public view {
        IGnosisSafe safe = IGnosisSafe(_ownerSafe());
        console.log("Nonce:", safe.nonce());
    }

    function _readFrom_SAFE_NONCE() internal pure override returns (bool) {
        return true;
    }

    function _simulateForSigner(address _safe, IMulticall3.Call3[] memory _calls)
        internal
        returns (Vm.AccountAccess[] memory, Simulation.Payload memory)
    {
        bytes memory data = abi.encodeCall(IMulticall3.aggregate3, (_calls));

        Simulation.StateOverride[] memory overrides = _overrides(_safe);

        bytes memory txData = _execTransactionCalldata(_safe, data, Signatures.genPrevalidatedSignature(msg.sender));
        Simulation.logSimulationLink({_to: _safe, _data: txData, _from: msg.sender, _overrides: overrides});

        // Forge simulation of the data logged in the link. If the simulation fails
        // we revert to make it explicit that the simulation failed.
        Simulation.Payload memory simPayload =
            Simulation.Payload({to: _safe, data: txData, from: msg.sender, stateOverrides: overrides});
        Vm.AccountAccess[] memory accesses = Simulation.simulateFromSimPayload(simPayload);
        return (accesses, simPayload);
    }

    function _overrides(address _safe) internal view returns (Simulation.StateOverride[] memory) {
        Simulation.StateOverride[] memory simOverrides = _simulationOverrides();
        Simulation.StateOverride[] memory overrides = new Simulation.StateOverride[](1 + simOverrides.length);
        overrides[0] = _safeOverrides(_safe, msg.sender);
        for (uint256 i = 0; i < simOverrides.length; i++) {
            overrides[i + 1] = simOverrides[i];
        }
        return overrides;
    }
}
