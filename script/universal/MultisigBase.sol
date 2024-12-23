// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Vm} from "forge-std/Vm.sol";
import {console} from "forge-std/console.sol";
import {CommonBase} from "forge-std/Base.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";
import {IGnosisSafe, Enum} from "./IGnosisSafe.sol";
import {Simulation} from "./Simulation.sol";
import {Signatures} from "./Signatures.sol";

/// @title MultisigBase - Base contract for working with multisignature wallets.
/// @notice Provides utility functions for nonce handling, transaction encoding, and simulation.
abstract contract MultisigBase is CommonBase {
    /// @notice Slot in storage for the Safe's nonce.
    bytes32 internal constant SAFE_NONCE_SLOT = bytes32(uint256(5));

    /// @notice Event emitted when data to sign is generated.
    event DataToSign(bytes);

    /// @dev Subclasses can override this to determine nonce behavior for nested safes.
    function _readFrom_SAFE_NONCE() internal pure virtual returns (bool);

    /// @notice Retrieves the nonce to use for the given Safe.
    /// @param _safe Address of the Safe.
    /// @return nonce The nonce to be used.
    function _getNonce(address _safe) internal view virtual returns (uint256 nonce) {
        uint256 safeNonce = IGnosisSafe(_safe).nonce();
        nonce = safeNonce;

        // Try reading from SAFE_NONCE environment variable if allowed.
        if (_readFrom_SAFE_NONCE()) {
            try vm.envUint("SAFE_NONCE") {
                nonce = vm.envUint("SAFE_NONCE");
            } catch {}
        }

        // Try reading from SAFE_NONCE_{UPPERCASE_SAFE_ADDRESS} environment variable.
        string memory envVarName = string.concat("SAFE_NONCE_", vm.toUppercase(vm.toString(_safe)));
        try vm.envUint(envVarName) {
            nonce = vm.envUint(envVarName);
        } catch {}

        // Log any override of the nonce.
        if (nonce != safeNonce) {
            console.log("Overriding nonce for safe %s: %d -> %d", _safe, safeNonce, nonce);
        }
    }

    /// @notice Prints the data that should be signed for a transaction.
    /// @param _safe Address of the Safe.
    /// @param _calls Array of calls to be aggregated.
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
        console.log("Please ensure the 'Data to sign' matches the simulation and hardware wallet output.");
        console.log("###############################");
    }

    /// @notice Checks the validity of provided signatures for the transaction.
    /// @param _safe Address of the Safe.
    /// @param _calls Array of calls to be aggregated.
    /// @param _signatures Combined signatures to validate.
    function _checkSignatures(address _safe, IMulticall3.Call3[] memory _calls, bytes memory _signatures)
        internal
        view
    {
        bytes memory data = abi.encodeCall(IMulticall3.aggregate3, (_calls));
        bytes32 hash = _getTransactionHash(_safe, data);
        _signatures = Signatures.prepareSignatures(_safe, hash, _signatures);

        IGnosisSafe(_safe).checkSignatures({
            dataHash: hash,
            data: data,
            signatures: _signatures
        });
    }

    /// @notice Executes a transaction with the given data and signatures.
    /// @param _safe Address of the Safe.
    /// @param _calls Array of calls to be executed.
    /// @param _signatures Combined signatures for the transaction.
    /// @param _broadcast Whether to broadcast the transaction.
    /// @return State changes and simulation payload.
    function _executeTransaction(
        address _safe,
        IMulticall3.Call3[] memory _calls,
        bytes memory _signatures,
        bool _broadcast
    ) internal returns (Vm.AccountAccess[] memory, Simulation.Payload memory) {
        bytes memory data = abi.encodeCall(IMulticall3.aggregate3, (_calls));
        bytes32 hash = _getTransactionHash(_safe, data);
        _signatures = Signatures.prepareSignatures(_safe, hash, _signatures);

        bytes memory simData = _execTransationCalldata(_safe, data, _signatures);
        Simulation.logSimulationLink({_to: _safe, _from: msg.sender, _data: simData});

        vm.startStateDiffRecording();
        bool success = _execTransaction(_safe, data, _signatures, _broadcast);
        Vm.AccountAccess[] memory accesses = vm.stopAndReturnStateDiff();
        require(success, "MultisigBase::_executeTransaction: Transaction failed");
        require(accesses.length > 0, "MultisigBase::_executeTransaction: No state changes");

        Simulation.Payload memory simPayload = Simulation.Payload({
            from: msg.sender,
            to: _safe,
            data: simData,
            stateOverrides: new Simulation.StateOverride     });
        return (accesses, simPayload);
    }

    /// @notice Encodes transaction data for the Safe.
    /// @param _safe Address of the Safe.
    /// @param _data Transaction data.
    /// @return Encoded transaction data.
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

    /// @notice Executes the transaction using the Gnosis Safe interface.
    /// @param _safe Address of the Safe.
    /// @param _data Transaction data.
    /// @param _signatures Combined signatures for the transaction.
    /// @param _broadcast Whether to broadcast the transaction.
    /// @return True if the transaction succeeds.
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
}
