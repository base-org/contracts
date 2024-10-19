// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {SystemConfig} from "@eth-optimism-bedrock/src/L1/SystemConfig.sol";
import {
    MultisigBuilder,
    IMulticall3,
    IGnosisSafe
} from "../../universal/MultisigBuilder.sol";
import { Vm } from "forge-std/Vm.sol";

abstract contract SetGasLimitBuilder is MultisigBuilder {
    address internal SYSTEM_CONFIG_OWNER = vm.envAddress("SYSTEM_CONFIG_OWNER");
    address internal L1_SYSTEM_CONFIG = vm.envAddress("L1_SYSTEM_CONFIG_ADDRESS");

    /**
     * -----------------------------------------------------------
     * Virtual Functions
     * -----------------------------------------------------------
     */

    function _fromGasLimit() internal virtual view returns (uint64);

    function _toGasLimit() internal virtual view returns (uint64);

    function _nonceOffset() internal virtual view returns (uint64);

    /**
     * -----------------------------------------------------------
     * Implemented Functions
     * -----------------------------------------------------------
     */

    function _postCheck(Vm.AccountAccess[] memory, SimulationPayload memory) internal override view {
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

    function _getNonce(IGnosisSafe safe) internal view override returns (uint256 nonce) {
        nonce = safe.nonce() + _nonceOffset();
    }

    function _addOverrides(address _safe) internal view override returns (SimulationStateOverride memory) {
        IGnosisSafe safe = IGnosisSafe(payable(_safe));
        uint256 _nonce = _getNonce(safe);
        return overrideSafeThresholdOwnerAndNonce(_safe, DEFAULT_SENDER, _nonce);
    }

    // We need to expect that the gas limit will have been updated previously in our simulation
    // Use this override to specifically set the gas limit to the expected update value.
    function _addGenericOverrides() internal view override returns (SimulationStateOverride memory) {
        SimulationStorageOverride[] memory _stateOverrides = new SimulationStorageOverride[](1);
        _stateOverrides[0] = SimulationStorageOverride({
            key: 0x0000000000000000000000000000000000000000000000000000000000000068, // slot of gas limit
            value: bytes32(uint(_fromGasLimit()))
        });
        return SimulationStateOverride({contractAddress: L1_SYSTEM_CONFIG, overrides: _stateOverrides});
    }
}