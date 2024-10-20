// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./MultisigBase.sol";

import { console } from "forge-std/console.sol";
import { IMulticall3 } from "forge-std/interfaces/IMulticall3.sol";
import { Vm } from "forge-std/Vm.sol";

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
    function _postCheck(Vm.AccountAccess[] memory accesses, SimulationPayload memory simPayload) internal virtual;

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
    function sign() public {
        IGnosisSafe safe = IGnosisSafe(_ownerSafe());

        // Snapshot and restore Safe nonce after simulation, otherwise the data logged to sign
        // would not match the actual data we need to sign, because the simulation
        // would increment the nonce.
        uint256 originalNonce = _getNonce(safe);

        IMulticall3.Call3[] memory calls = _buildCalls();
        (Vm.AccountAccess[] memory accesses, SimulationPayload memory simPayload) = _simulateForSigner(safe, calls);
        _postCheck(accesses, simPayload);

        // Restore the original nonce.
        vm.store(address(safe), SAFE_NONCE_SLOT, bytes32(uint256(originalNonce)));

        _printDataToSign(safe, calls);
    }

    /**
     * Step 2
     * ======
     * Verify the signatures generated from step 1 are valid.
     * This allow transactions to be pre-signed and stored safely before execution.
     */
    function verify(bytes memory _signatures) public view {
        _checkSignatures(IGnosisSafe(_ownerSafe()), _buildCalls(), _signatures);
    }

    function nonce() public view {
        IGnosisSafe safe = IGnosisSafe(_ownerSafe());
        console.log("Nonce:", safe.nonce());
    }

    /**
     * Step 3
     * ======
     * Simulate the transaction. This method should be called by the final member of the multisig
     * that will execute the transaction. Signatures from step 1 are required.
     */
    function simulate(bytes memory _signatures) public {
        IGnosisSafe safe = IGnosisSafe(_ownerSafe());
        uint256 _nonce = _getNonce(safe);
        vm.store(address(safe), SAFE_NONCE_SLOT, bytes32(uint256(_nonce)));
        (Vm.AccountAccess[] memory accesses, SimulationPayload memory simPayload) = _executeTransaction(safe, _buildCalls(), _signatures);
        _postCheck(accesses, simPayload);
    }

    /**
     * Step 4
     * ======
     * Execute the transaction. This method should be called by the final member of the multisig
     * that will execute the transaction. Signatures from step 1 are required.
     *
     * Alternatively, this method can be called after a threshold of signatures is collected from
     * step 1. In this scenario, the caller doesn't need to be a signer of the multisig.
     */
    function run(bytes memory _signatures) public {
        vm.startBroadcast();
        (Vm.AccountAccess[] memory accesses, SimulationPayload memory simPayload) = _executeTransaction(IGnosisSafe(_ownerSafe()), _buildCalls(), _signatures);
        vm.stopBroadcast();

        _postCheck(accesses, simPayload);
    }

    function _simulateForSigner(IGnosisSafe _safe, IMulticall3.Call3[] memory _calls)
        internal
        returns (Vm.AccountAccess[] memory, SimulationPayload memory)
    {
        bytes memory data = abi.encodeCall(IMulticall3.aggregate3, (_calls));

        SimulationStateOverride[] memory overrides = _setOverrides(_safe);

        bytes memory txData = abi.encodeCall(_safe.execTransaction,
            (
                MULTICALL3_ADDRESS,
                0,
                data,
                Enum.Operation.DelegateCall,
                0,
                0,
                0,
                address(0),
                payable(address(0)),
                genPrevalidatedSignature(msg.sender)
            )
        );

        logSimulationLink({
            _to: address(_safe),
            _data: txData,
            _from: msg.sender,
            _overrides: overrides
        });

        // Forge simulation of the data logged in the link. If the simulation fails
        // we revert to make it explicit that the simulation failed.
        SimulationPayload memory simPayload = SimulationPayload({
            to: address(_safe),
            data: txData,
            from: msg.sender,
            stateOverrides: overrides
        });
        Vm.AccountAccess[] memory accesses = simulateFromSimPayload(simPayload);
        return (accesses, simPayload);
    }

    // The state change simulation can set the threshold, owner address and/or nonce.
    // This allows a non-signing owner to simulate the transaction
    // State changes reflected in the simulation as a result of these overrides
    // will not be reflected in the prod execution.
    // This particular implementation can be overwritten by an inheriting script. The
    // default logic is vestigial for backwards compatibility.
    function _addOverrides(IGnosisSafe _safe) internal virtual view returns (SimulationStateOverride memory) {
        uint256 _nonce = _getNonce(_safe);
        return overrideSafeThresholdAndNonce(address(_safe), _nonce);
    }

    // Tenderly simulations can accept generic state overrides. This hook enables this functionality.
    // By default, an empty (no-op) override is returned
    function _addGenericOverrides() internal virtual view returns (SimulationStateOverride memory override_) {}

    function _addMultipleGenericOverrides()
        internal
        view
        virtual
        returns (SimulationStateOverride[] memory overrides_)
    {}

    function _setOverrides(IGnosisSafe _safe) internal virtual returns (SimulationStateOverride[] memory) {
        SimulationStateOverride[] memory extraOverrides = _addMultipleGenericOverrides();
        SimulationStateOverride[] memory overrides = new SimulationStateOverride[](2 + extraOverrides.length);
        overrides[0] = _addOverrides(_safe);
        overrides[1] = _addGenericOverrides();
        for (uint256 i = 0; i < extraOverrides.length; i++) {
            overrides[i + 2] = extraOverrides[i];
        }
        return overrides;
    }
}
