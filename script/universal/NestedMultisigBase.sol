// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./MultisigBase.sol";

abstract contract NestedMultisigBase is MultisigBase {
    /**
     * -----------------------------------------------------------
     * Virtual Functions
     * -----------------------------------------------------------
     */

    /**
     * @notice Returns the nested safe address to execute the final transaction from
     */
    function _ownerSafe() internal view virtual returns (address);

    /**
     * @notice Creates the calldata for both signatures (`sign`) and execution (`run`)
     */
    function _buildCalls() internal view virtual returns (IMulticall3.Call3[] memory);

    /**
     * @notice Follow up assertions to ensure that the script ran to completion.
     * @dev Called after `sign` and `run`, but not `approve`.
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

    function _readFrom_SAFE_NONCE() internal pure override returns (bool) {
        return false;
    }

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

    function _simulateForSigner(address _signerSafe, address _safe, IMulticall3.Call3[] memory _calls)
        internal
        returns (Vm.AccountAccess[] memory, Simulation.Payload memory)
    {
        bytes memory data = abi.encodeCall(IMulticall3.aggregate3, (_calls));
        IMulticall3.Call3[] memory calls = _simulateForSignerCalls(_signerSafe, _safe, data);

        // Now define the state overrides for the simulation.
        Simulation.StateOverride[] memory overrides = _overrides(_signerSafe, _safe);

        bytes memory txData = abi.encodeCall(IMulticall3.aggregate3, (calls));
        console.log("---\nSimulation link:");
        Simulation.logSimulationLink({_to: MULTICALL3_ADDRESS, _data: txData, _from: msg.sender, _overrides: overrides});

        // Forge simulation of the data logged in the link. If the simulation fails
        // we revert to make it explicit that the simulation failed.
        Simulation.Payload memory simPayload =
            Simulation.Payload({to: MULTICALL3_ADDRESS, data: txData, from: msg.sender, stateOverrides: overrides});
        Vm.AccountAccess[] memory accesses = Simulation.simulateFromSimPayload(simPayload);
        return (accesses, simPayload);
    }

    function _simulateForSignerCalls(address _signerSafe, address _safe, bytes memory _data)
        internal
        view
        returns (IMulticall3.Call3[] memory)
    {
        IMulticall3.Call3[] memory calls = new IMulticall3.Call3[](2);
        bytes32 hash = _getTransactionHash(_safe, _data);

        // simulate an approveHash, so that signer can verify the data they are signing
        bytes memory approveHashData = abi.encodeCall(
            IMulticall3.aggregate3,
            (
                _toArray(
                    IMulticall3.Call3({
                        target: _safe,
                        allowFailure: false,
                        callData: abi.encodeCall(IGnosisSafe(_safe).approveHash, (hash))
                    })
                )
            )
        );
        bytes memory approveHashExec = _execTransationCalldata(
            _signerSafe, approveHashData, Signatures.genPrevalidatedSignature(MULTICALL3_ADDRESS)
        );
        calls[0] = IMulticall3.Call3({target: _signerSafe, allowFailure: false, callData: approveHashExec});

        // simulate the final state changes tx, so that signer can verify the final results
        bytes memory finalExec = _execTransationCalldata(_safe, _data, Signatures.genPrevalidatedSignature(_signerSafe));
        calls[1] = IMulticall3.Call3({target: _safe, allowFailure: false, callData: finalExec});

        return calls;
    }

    function _overrides(address _signerSafe, address _safe) internal view returns (Simulation.StateOverride[] memory) {
        Simulation.StateOverride[] memory simOverrides = _simulationOverrides();
        Simulation.StateOverride[] memory overrides = new Simulation.StateOverride[](2 + simOverrides.length);
        overrides[0] = _safeOverrides(_signerSafe, MULTICALL3_ADDRESS);
        overrides[1] = _safeOverrides(_safe, address(0));
        for (uint256 i = 0; i < simOverrides.length; i++) {
            overrides[i + 2] = simOverrides[i];
        }
        return overrides;
    }

    function _toArray(IMulticall3.Call3 memory call) internal pure returns (IMulticall3.Call3[] memory) {
        IMulticall3.Call3[] memory calls = new IMulticall3.Call3[](1);
        calls[0] = call;
        return calls;
    }
}
