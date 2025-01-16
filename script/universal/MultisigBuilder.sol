// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./MultisigBase.sol";
import {console} from "forge-std/console.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";
import {Vm} from "forge-std/Vm.sol";

/**
 * @title MultisigBuilder
 * @notice Designed for managing multisig transactions using signatures instead of approvals.
 *         Inspired by Optimism's SafeBuilder.
 */
abstract contract MultisigBuilder is MultisigBase {
    /**
     * -----------------------------------------------------------
     * Virtual Functions (to be implemented by child contracts)
     * -----------------------------------------------------------
     */

    /**
     * @notice Returns the address of the safe contract that executes transactions.
     */
    function _ownerSafe() internal view virtual returns (address);

    /**
     * @notice Creates calldata for both signing (`sign`) and execution (`run`).
     */
    function _buildCalls() internal view virtual returns (IMulticall3.Call3[] memory);

    /**
     * @notice Post-execution assertions to ensure transaction correctness.
     */
    function _postCheck(Vm.AccountAccess[] memory accesses, Simulation.Payload memory simPayload) internal virtual;

    /**
     * @notice Post-signing assertions to validate state and simulation.
     */
    function _postSign(Vm.AccountAccess[] memory accesses, Simulation.Payload memory simPayload) internal virtual {}

    /**
     * @notice Post-run assertions to validate state and simulation.
     */
    function _postRun(Vm.AccountAccess[] memory accesses, Simulation.Payload memory simPayload) internal virtual {}

    /**
     * -----------------------------------------------------------
     * Implemented Functions
     * -----------------------------------------------------------
     */

    /**
     * @notice Step 1: Generates transaction execution data for signing.
     *         Should be called by a threshold-1 of multisig members to collect signatures.
     */
    function sign() public {
        address safe = _ownerSafe();

        // Snapshot the current nonce to ensure accurate signing data.
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
     * @notice Verifies the validity of signatures generated in step 1.
     *         Useful for pre-signing and storing transactions.
     */
    function verify(bytes memory _signatures) public view {
        _checkSignatures(_ownerSafe(), _buildCalls(), _signatures);
    }

    /**
     * @notice Step 1.2: Simulates the transaction execution with provided signatures.
     *         Useful for ensuring transaction validity before actual execution.
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
     * @notice Step 2: Executes the transaction with collected signatures.
     *         Can be called by the final signer or a delegate.
     */
    function run(bytes memory _signatures) public {
        (Vm.AccountAccess[] memory accesses, Simulation.Payload memory simPayload) =
            _executeTransaction(_ownerSafe(), _buildCalls(), _signatures, true);

        _postRun(accesses, simPayload);
        _postCheck(accesses, simPayload);
    }

    /**
     * @notice Prints the current nonce of the safe.
     */
    function nonce() public view {
        IGnosisSafe safe = IGnosisSafe(_ownerSafe());
        console.log("Nonce:", safe.nonce());
    }

    /**
     * @notice Indicates if SAFE_NONCE is used in simulations.
     */
    function _readFrom_SAFE_NONCE() internal pure override returns (bool) {
        return true;
    }

    /**
     * @notice Simulates a transaction for the signer.
     */
    function _simulateForSigner(address _safe, IMulticall3.Call3[] memory _calls)
        internal
        returns (Vm.AccountAccess[] memory, Simulation.Payload memory)
    {
        bytes memory data = abi.encodeCall(IMulticall3.aggregate3, (_calls));
        Simulation.StateOverride[] memory overrides = _overrides(_safe);

        bytes memory txData = _execTransationCalldata(_safe, data, Signatures.genPrevalidatedSignature(msg.sender));
        Simulation.logSimulationLink({_to: _safe, _data: txData, _from: msg.sender, _overrides: overrides});

        Simulation.Payload memory simPayload =
            Simulation.Payload({to: _safe, data: txData, from: msg.sender, stateOverrides: overrides});
        Vm.AccountAccess[] memory accesses = Simulation.simulateFromSimPayload(simPayload);
        return (accesses, simPayload);
    }

    /**
     * @notice Combines simulation overrides with safe-specific overrides.
     */
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
