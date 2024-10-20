// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { console } from "forge-std/console.sol";
import { CommonBase } from "forge-std/Base.sol";
import { Vm } from "forge-std/Vm.sol";

abstract contract Simulator is CommonBase {
    struct SimulationStateOverride {
        address contractAddress;
        SimulationStorageOverride[] overrides;
    }

    struct SimulationStorageOverride {
        bytes32 key;
        bytes32 value;
    }

    struct SimulationPayload {
        address from;
        address to;
        bytes data;
        SimulationStateOverride[] stateOverrides;
    }

    function simulateFromSimPayload(SimulationPayload memory simPayload) internal returns (Vm.AccountAccess[] memory) {
        require(simPayload.from != address(0), "Simulator::simulateFromSimPayload: from address cannot be zero address");
        require(simPayload.to != address(0), "Simulator::simulateFromSimPayload: to address cannot be zero address");

        // Apply state overrides.
        SimulationStateOverride[] memory stateOverrides = simPayload.stateOverrides;
        for (uint256 i; i < stateOverrides.length; i++) {
            SimulationStateOverride memory stateOverride = stateOverrides[i];
            SimulationStorageOverride[] memory storageOverrides = stateOverride.overrides;
            for (uint256 j; j < storageOverrides.length; j++) {
                SimulationStorageOverride memory storageOverride = storageOverrides[j];
                vm.store(stateOverride.contractAddress, storageOverride.key, storageOverride.value);
            }
        }

        // Execute the call in forge and return the state diff.
        vm.startStateDiffRecording();
        vm.prank(simPayload.from);
        (bool ok, bytes memory returnData) = address(simPayload.to).call(simPayload.data);
        Vm.AccountAccess[] memory accesses = vm.stopAndReturnStateDiff();
        require(ok, string.concat("Simulator::simulateFromSimPayload failed: ", vm.toString(returnData)));
        require(accesses.length > 0, "Simulator::simulateFromSimPayload: No state changes");
        return accesses;
    }

    function overrideSafeThresholdOwnerAndNonce(address _safe, address _owner, uint256 _nonce) public view returns (SimulationStateOverride memory) {
        SimulationStateOverride memory state = SimulationStateOverride({
            contractAddress: _safe,
            overrides: new SimulationStorageOverride[](0)
        });
        state = addThresholdOverride(_safe, state);
        state = addOwnerOverride(_safe, state, _owner);
        state = addNonceOverride(_safe, state, _nonce);
        return state;
    }

    function addThresholdOverride(address _safe, SimulationStateOverride memory _state) internal view returns (SimulationStateOverride memory) {
        // get the threshold and check if we need to override it
        (, bytes memory thresholdBytes) = _safe.staticcall(abi.encodeWithSignature("getThreshold()"));
        uint256 threshold = abi.decode(thresholdBytes, (uint256));
        if (threshold == 1) return _state;

        // set the threshold (slot 4) to 1
        return addOverride(_state, SimulationStorageOverride({
            key: bytes32(uint256(0x4)),
            value: bytes32(uint256(0x1))
        }));
    }

    function addOwnerOverride(address _safe, SimulationStateOverride memory _state, address _owner) internal view returns (SimulationStateOverride memory) {
        // get the owners and check if _owner is an owner
        (, bytes memory ownersBytes) = _safe.staticcall(abi.encodeWithSignature("getOwners()"));
        address[] memory owners = abi.decode(ownersBytes, (address[]));
        for (uint256 i; i < owners.length; i++) {
            if (owners[i] == _owner) return _state;
        }

        // set the ownerCount (slot 3) to 1
        _state = addOverride(_state, SimulationStorageOverride({
            key: bytes32(uint256(0x3)),
            value: bytes32(uint256(0x1))
        }));
        // override the owner mapping (slot 2), which requires two key/value pairs: { 0x1: _owner, _owner: 0x1 }
        _state = addOverride(_state, SimulationStorageOverride({
            key: bytes32(0xe90b7bceb6e7df5418fb78d8ee546e97c83a08bbccc01a0644d599ccd2a7c2e0), // keccak256(1 || 2)
            value: bytes32(uint256(uint160(_owner)))
        }));
        return addOverride(_state, SimulationStorageOverride({
            key: keccak256(abi.encode(_owner, uint256(2))),
            value: bytes32(uint256(0x1))
        }));
    }

    function addNonceOverride(address _safe, SimulationStateOverride memory _state, uint256 _nonce) internal view returns (SimulationStateOverride memory) {
        // get the nonce and check if we need to override it
        (, bytes memory nonceBytes) = _safe.staticcall(abi.encodeWithSignature("nonce()"));
        uint256 nonce = abi.decode(nonceBytes, (uint256));
        if (nonce == _nonce) return _state;

        // set the nonce (slot 5) to the desired value
        return addOverride(_state, SimulationStorageOverride({
            key: bytes32(uint256(0x5)),
            value: bytes32(_nonce)
        }));
    }

    function addOverride(SimulationStateOverride memory _state, SimulationStorageOverride memory _override) internal pure returns (SimulationStateOverride memory) {
        SimulationStorageOverride[] memory overrides = new SimulationStorageOverride[](_state.overrides.length + 1);
        for (uint256 i; i < _state.overrides.length; i++) {
            overrides[i] = _state.overrides[i];
        }
        overrides[_state.overrides.length] = _override;
        return SimulationStateOverride({
            contractAddress: _state.contractAddress,
            overrides: overrides
        });
    }

    function logSimulationLink(address _to, bytes memory _data, address _from) public view {
        logSimulationLink(_to, _data, _from, new SimulationStateOverride[](0));
    }

    function logSimulationLink(address _to, bytes memory _data, address _from, SimulationStateOverride[] memory _overrides) public view {
        string memory proj = vm.envOr("TENDERLY_PROJECT", string("TENDERLY_PROJECT"));
        string memory username = vm.envOr("TENDERLY_USERNAME", string("TENDERLY_USERNAME"));

        // the following characters are url encoded: []{}
        string memory stateOverrides = "%5B";
        for (uint256 i; i < _overrides.length; i++) {
            SimulationStateOverride memory _override = _overrides[i];
            if (i > 0) stateOverrides = string.concat(stateOverrides, ",");
            stateOverrides = string.concat(
                stateOverrides,
                "%7B\"contractAddress\":\"",
                vm.toString(_override.contractAddress),
                "\",\"storage\":%5B"
            );
            for (uint256 j; j < _override.overrides.length; j++) {
                if (j > 0) stateOverrides = string.concat(stateOverrides, ",");
                stateOverrides = string.concat(
                    stateOverrides,
                    "%7B\"key\":\"",
                    vm.toString(_override.overrides[j].key),
                    "\",\"value\":\"",
                    vm.toString(_override.overrides[j].value),
                    "\"%7D"
                );
            }
            stateOverrides = string.concat(stateOverrides, "%5D%7D");
        }
        stateOverrides = string.concat(stateOverrides, "%5D");

        string memory str = string.concat(
            "https://dashboard.tenderly.co/",
            username,
            "/",
            proj,
            "/simulator/new?network=",
            vm.toString(block.chainid),
            "&contractAddress=",
            vm.toString(_to),
            "&from=",
            vm.toString(_from),
            "&stateOverrides=",
            stateOverrides
        );
        if (bytes(str).length + _data.length * 2 > 7980) {
            // tenderly's nginx has issues with long URLs, so print the raw input data separately
            str = string.concat(str, "\nInsert the following hex into the 'Raw input data' field:");
            console.log(str);
            console.log(vm.toString(_data));
        } else {
            str = string.concat(str, "&rawFunctionInput=", vm.toString(_data));
            console.log(str);
        }
    }
}
