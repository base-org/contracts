// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {SystemConfig} from "@eth-optimism-bedrock/src/L1/SystemConfig.sol";
import {MultisigBuilder, IMulticall3, IGnosisSafe, Simulation} from "../../universal/MultisigBuilder.sol";
import {Vm} from "forge-std/Vm.sol";

contract SetGasLimit is MultisigBuilder {
    address internal SYSTEM_CONFIG_OWNER = vm.envAddress("SYSTEM_CONFIG_OWNER");
    address internal L1_SYSTEM_CONFIG = vm.envAddress("L1_SYSTEM_CONFIG_ADDRESS");

    /**
     * -----------------------------------------------------------
     * Implemented Functions
     * -----------------------------------------------------------
     */
    function _fromGasLimit() internal view returns (uint64) {
        return uint64(vm.envUint("FROM_GAS_LIMIT"));
    }

    function _toGasLimit() internal view returns (uint64) {
        return uint64(vm.envUint("TO_GAS_LIMIT"));
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {
        assert(SystemConfig(L1_SYSTEM_CONFIG).gasLimit() == _toGasLimit());
    }

    function _buildCalls() internal view override returns (IMulticall3.Call3[] memory) {
        IMulticall3.Call3[] memory calls = new IMulticall3.Call3[](1);

        calls[0] = IMulticall3.Call3({
            target: L1_SYSTEM_CONFIG,
            allowFailure: false,
            callData: abi.encodeCall(SystemConfig.setGasLimit, (_toGasLimit()))
        });

        return calls;
    }

    function _ownerSafe() internal view override returns (address) {
        return SYSTEM_CONFIG_OWNER;
    }

    // We need to expect that the gas limit will have been updated previously in our simulation
    // Use this override to specifically set the gas limit to the expected update value.
    function _simulationOverrides() internal view override returns (Simulation.StateOverride[] memory) {
        Simulation.StateOverride[] memory _stateOverrides = new Simulation.StateOverride[](1);
        Simulation.StorageOverride[] memory _storageOverrides = new Simulation.StorageOverride[](1);
        _storageOverrides[0] = Simulation.StorageOverride({
            key: 0x0000000000000000000000000000000000000000000000000000000000000068, // slot of gas limit
            value: bytes32(uint256(_fromGasLimit()))
        });
        // solhint-disable-next-line max-line-length
        _stateOverrides[0] = Simulation.StateOverride({contractAddress: L1_SYSTEM_CONFIG, overrides: _storageOverrides});
        return _stateOverrides;
    }
}
