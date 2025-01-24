// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {CommonBase} from "forge-std/Base.sol";
// solhint-disable no-console
import {console} from "forge-std/console.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";
import {Vm} from "forge-std/Vm.sol";

import {IGnosisSafe, Enum} from "./IGnosisSafe.sol";
import {Signatures} from "./Signatures.sol";
import {Simulation} from "./Simulation.sol";

abstract contract MultisigBase is CommonBase {
    bytes32 internal constant SAFE_NONCE_SLOT = bytes32(uint256(5));

    event DataToSign(bytes);

    // Subclasses that use nested safes should return `false` to force use of the
    // explicit SAFE_NONCE_{UPPERCASE_SAFE_ADDRESS} env var.
    function _readFrom_SAFE_NONCE() internal pure virtual returns (bool);

    // Get the nonce to use for the given safe, for signing and simulations.
    //
    // If you override it, ensure that the behavior is correct for all contexts.
    // As an example, if you are pre-signing a message that needs safe.nonce+1 (before
    // safe.nonce is executed), you should explicitly set the nonce value with an env var.
    // Overriding this method with safe.nonce+1 will cause issues upon execution because
    // the transaction hash will differ from the one signed.
    //
    // The process for determining a nonce override is as follows:
    //   1. We look for an env var of the name SAFE_NONCE_{UPPERCASE_SAFE_ADDRESS}. For example,
    //      SAFE_NONCE_0X6DF4742A3C28790E63FE933F7D108FE9FCE51EA4.
    //   2. If it exists, we use it as the nonce override for the safe.
    //   3. If it does not exist and _readFrom_SAFE_NONCE() returns true, we do the same for the
    //      SAFE_NONCE env var.
    //   4. Otherwise we fallback to the safe's current nonce (no override).
    function _getNonce(address _safe) internal view virtual returns (uint256 nonce) {
        uint256 safeNonce = IGnosisSafe(_safe).nonce();
        nonce = safeNonce;

        // first try SAFE_NONCE
        if (_readFrom_SAFE_NONCE()) {
            try vm.envUint("SAFE_NONCE") {
                nonce = vm.envUint("SAFE_NONCE");
            } catch {}
        }

        // then try SAFE_NONCE_{UPPERCASE_SAFE_ADDRESS}
        string memory envVarName = string.concat("SAFE_NONCE_", vm.toUppercase(vm.toString(_safe)));
        try vm.envUint(envVarName) {
            nonce = vm.envUint(envVarName);
        } catch {}

        // print if any override
        if (nonce != safeNonce) {
            console.log("Overriding nonce for safe %s: %d -> %d", _safe, safeNonce, nonce);
        }
    }

    function _printDataToSign(address _safe, IMulticall3.Call3[] memory _calls) internal {
        bytes memory data = abi.encodeCall(IMulticall3.aggregate3, (_calls));
        bytes memory txData = _encodeTransactionData(_safe, data);
        bytes32 hash = _getTransactionHash(_safe, data);

        emit DataToSign(txData);

        console.log("---\nIf submitting onchain, call Safe.approveHash on %s with the following hash:", _safe);
        console.logBytes32(hash);

        console.log("---\nData to sign:");
        console.log("vvvvvvvv");
        console.logBytes(txData);
        console.log("^^^^^^^^\n");

        console.log("########## IMPORTANT ##########");
        console.log(
            // solhint-disable-next-line max-line-length
            "Please make sure that the 'Data to sign' displayed above matches what you see in the simulation and on your hardware wallet."
        );
        console.log("This is a critical step that must not be skipped.");
        console.log("###############################");
    }

    function _checkSignatures(address _safe, IMulticall3.Call3[] memory _calls, bytes memory _signatures)
        internal
        view
    {
        bytes memory data = abi.encodeCall(IMulticall3.aggregate3, (_calls));
        bytes32 hash = _getTransactionHash(_safe, data);
        _signatures = Signatures.prepareSignatures(_safe, hash, _signatures);

        IGnosisSafe(_safe).checkSignatures({dataHash: hash, data: data, signatures: _signatures});
    }

    function _executeTransaction(
        address _safe,
        IMulticall3.Call3[] memory _calls,
        bytes memory _signatures,
        bool _broadcast
    ) internal returns (Vm.AccountAccess[] memory, Simulation.Payload memory) {
        bytes memory data = abi.encodeCall(IMulticall3.aggregate3, (_calls));
        bytes32 hash = _getTransactionHash(_safe, data);
        _signatures = Signatures.prepareSignatures(_safe, hash, _signatures);

        bytes memory simData = _execTransactionCalldata(_safe, data, _signatures);
        Simulation.logSimulationLink({_to: _safe, _from: msg.sender, _data: simData});

        vm.startStateDiffRecording();
        bool success = _execTransaction(_safe, data, _signatures, _broadcast);
        Vm.AccountAccess[] memory accesses = vm.stopAndReturnStateDiff();
        require(success, "MultisigBase::_executeTransaction: Transaction failed");
        require(accesses.length > 0, "MultisigBase::_executeTransaction: No state changes");

        // This can be used to e.g. call out to the Tenderly API and get additional
        // data about the state diff before broadcasting the transaction.
        Simulation.Payload memory simPayload = Simulation.Payload({
            from: msg.sender,
            to: _safe,
            data: simData,
            stateOverrides: new Simulation.StateOverride[](0)
        });
        return (accesses, simPayload);
    }

    function _getTransactionHash(address _safe, IMulticall3.Call3[] memory calls) internal view returns (bytes32) {
        bytes memory data = abi.encodeCall(IMulticall3.aggregate3, (calls));
        return _getTransactionHash(_safe, data);
    }

    function _getTransactionHash(address _safe, bytes memory _data) internal view returns (bytes32) {
        return keccak256(_encodeTransactionData(_safe, _data));
    }

    function _encodeTransactionData(address _safe, bytes memory _data) internal view returns (bytes memory) {
        return IGnosisSafe(_safe).encodeTransactionData({
            to: MULTICALL3_ADDRESS,
            value: 0,
            data: _data,
            operation: Enum.Operation.DelegateCall,
            safeTxGas: 0,
            baseGas: 0,
            gasPrice: 0,
            gasToken: address(0),
            refundReceiver: address(0),
            _nonce: _getNonce(_safe)
        });
    }

    function _execTransactionCalldata(address _safe, bytes memory _data, bytes memory _signatures)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeCall(
            IGnosisSafe(_safe).execTransaction,
            (
                MULTICALL3_ADDRESS,
                0,
                _data,
                Enum.Operation.DelegateCall,
                0,
                0,
                0,
                address(0),
                payable(address(0)),
                _signatures
            )
        );
    }

    function _execTransaction(address _safe, bytes memory _data, bytes memory _signatures, bool _broadcast)
        internal
        returns (bool)
    {
        if (_broadcast) {
            vm.broadcast();
        }
        return IGnosisSafe(_safe).execTransaction({
            to: MULTICALL3_ADDRESS,
            value: 0,
            data: _data,
            operation: Enum.Operation.DelegateCall,
            safeTxGas: 0,
            baseGas: 0,
            gasPrice: 0,
            gasToken: address(0),
            refundReceiver: payable(address(0)),
            signatures: _signatures
        });
    }

    // The state change simulation can set the threshold, owner address and/or nonce.
    // This allows simulation of the final transaction by overriding the threshold to 1.
    // State changes reflected in the simulation as a result of these overrides will
    // not be reflected in the prod execution.
    function _safeOverrides(address _safe, address _owner)
        internal
        view
        virtual
        returns (Simulation.StateOverride memory)
    {
        uint256 _nonce = _getNonce(_safe);
        if (_owner == address(0)) {
            return Simulation.overrideSafeThresholdAndNonce(_safe, _nonce);
        }
        return Simulation.overrideSafeThresholdOwnerAndNonce(_safe, _owner, _nonce);
    }

    // Tenderly simulations can accept generic state overrides. This hook enables this functionality.
    // By default, an empty (no-op) override is returned.
    function _simulationOverrides() internal view virtual returns (Simulation.StateOverride[] memory overrides_) {}
}
