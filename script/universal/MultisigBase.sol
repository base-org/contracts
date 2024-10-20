// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {console} from "forge-std/console.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";
import {IGnosisSafe, Enum} from "./IGnosisSafe.sol";
import {Bytes} from "@eth-optimism-bedrock/src/libraries/Bytes.sol";
import {LibSort} from "@solady/utils/LibSort.sol";
import "./Simulator.sol";

abstract contract MultisigBase is Simulator {
    IMulticall3 internal constant multicall = IMulticall3(MULTICALL3_ADDRESS);
    bytes32 internal constant SAFE_NONCE_SLOT = bytes32(uint256(5));

    function _getTransactionHash(address _safe, IMulticall3.Call3[] memory calls) internal view returns (bytes32) {
        bytes memory data = abi.encodeCall(IMulticall3.aggregate3, (calls));
        return _getTransactionHash(_safe, data);
    }

    function _getTransactionHash(address _safe, bytes memory _data) internal view returns (bytes32) {
        return keccak256(_encodeTransactionData(_safe, _data));
    }

    // Virtual method which can be overwritten
    // Default logic here is vestigial for backwards compatibility
    // IMPORTANT: this method is used in the sign, simulate, AND execution contexts
    // If you override it, ensure that the behavior is correct for all contexts
    // As an example, if you are pre-signing a message that needs safe.nonce+1 (before safe.nonce is executed),
    // you should explicitly set the nonce value with an env var.
    // Overwriting this method with safe.nonce + 1 will cause issues upon execution because the transaction
    // hash will differ from the one signed.
    function _getNonce(IGnosisSafe safe) internal view virtual returns (uint256 nonce) {
        nonce = safe.nonce();
        console.log("Safe current nonce:", nonce);
        try vm.envUint("SAFE_NONCE") {
            nonce = vm.envUint("SAFE_NONCE");
            console.log("Creating transaction with nonce:", nonce);
        }
        catch {}
    }

    function _encodeTransactionData(address _safe, bytes memory _data) internal view returns (bytes memory) {
        // Ensure that the required contracts exist
        require(address(multicall).code.length > 0, "multicall3 not deployed");
        require(_safe.code.length > 0, "no code at safe address");

        IGnosisSafe safe = IGnosisSafe(payable(_safe));
        uint256 nonce = _getNonce(safe);

        return safe.encodeTransactionData({
            to: address(multicall),
            value: 0,
            data: _data,
            operation: Enum.Operation.DelegateCall,
            safeTxGas: 0,
            baseGas: 0,
            gasPrice: 0,
            gasToken: address(0),
            refundReceiver: address(0),
            _nonce: nonce
        });
    }

    function _printDataToSign(address _safe, IMulticall3.Call3[] memory _calls) internal view {
        bytes memory data = abi.encodeCall(IMulticall3.aggregate3, (_calls));
        bytes memory txData = _encodeTransactionData(_safe, data);

        console.log("---\nData to sign:");
        console.log("vvvvvvvv");
        console.logBytes(txData);
        console.log("^^^^^^^^\n");

        console.log("########## IMPORTANT ##########");
        console.log("Please make sure that the 'Data to sign' displayed above matches what you see in the simulation and on your hardware wallet.");
        console.log("This is a critical step that must not be skipped.");
        console.log("###############################");
    }

    function _checkSignatures(address _safe, IMulticall3.Call3[] memory _calls, bytes memory _signatures)
        internal
        view
    {
        IGnosisSafe safe = IGnosisSafe(payable(_safe));
        bytes memory data = abi.encodeCall(IMulticall3.aggregate3, (_calls));
        bytes32 hash = _getTransactionHash(_safe, data);

        // safe requires all signatures to be unique, and sorted ascending by public key
        _signatures = sortUniqueSignatures(_signatures, hash, safe.getThreshold());

        safe.checkSignatures({
            dataHash: hash,
            data: data,
            signatures: _signatures
        });
    }

    function _executeTransaction(address _safe, IMulticall3.Call3[] memory _calls, bytes memory _signatures)
        internal
        returns (Vm.AccountAccess[] memory, SimulationPayload memory)
    {
        IGnosisSafe safe = IGnosisSafe(payable(_safe));
        bytes memory data = abi.encodeCall(IMulticall3.aggregate3, (_calls));
        bytes32 hash = _getTransactionHash(_safe, data);

        // safe requires all signatures to be unique, and sorted ascending by public key
        _signatures = sortUniqueSignatures(_signatures, hash, safe.getThreshold());

        logSimulationLink({
            _to: _safe,
            _from: msg.sender,
            _data: abi.encodeCall(
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
                    _signatures
                )
            )
        });

        vm.startStateDiffRecording();
        bool success = safe.execTransaction({
            to: address(multicall),
            value: 0,
            data: data,
            operation: Enum.Operation.DelegateCall,
            safeTxGas: 0,
            baseGas: 0,
            gasPrice: 0,
            gasToken: address(0),
            refundReceiver: payable(address(0)),
            signatures: _signatures
        });
        Vm.AccountAccess[] memory accesses = vm.stopAndReturnStateDiff();
        require(success, "MultisigBase::_executeTransaction: Transaction failed");
        require(accesses.length > 0, "MultisigBase::_executeTransaction: No state changes");

        // This can be used to e.g. call out to the Tenderly API and get additional
        // data about the state diff before broadcasting the transaction.
        SimulationPayload memory simPayload = SimulationPayload({
            from: msg.sender,
            to: address(safe),
            data: abi.encodeCall(safe.execTransaction, (
                address(multicall),
                0,
                data,
                Enum.Operation.DelegateCall,
                0,
                0,
                0,
                address(0),
                payable(address(0)),
                _signatures
            )),
            stateOverrides: new SimulationStateOverride[](0)
        });
        return (accesses, simPayload);
    }

    function toArray(IMulticall3.Call3 memory call) internal pure returns (IMulticall3.Call3[] memory) {
        IMulticall3.Call3[] memory calls = new IMulticall3.Call3[](1);
        calls[0] = call;
        return calls;
    }

    function prevalidatedSignatures(address[] memory _addresses) internal pure returns (bytes memory) {
        LibSort.sort(_addresses);
        bytes memory signatures;
        for (uint256 i; i < _addresses.length; i++) {
            signatures = bytes.concat(signatures, prevalidatedSignature(_addresses[i]));
        }
        return signatures;
    }

    function prevalidatedSignature(address _address) internal pure returns (bytes memory) {
        uint8 v = 1;
        bytes32 s = bytes32(0);
        bytes32 r = bytes32(uint256(uint160(_address)));
        return abi.encodePacked(r, s, v);
    }

    // see https://github.com/safe-global/safe-smart-account/blob/1ed486bb148fe40c26be58d1b517cec163980027/contracts/Safe.sol#L265-L334
    function sortUniqueSignatures(bytes memory _signatures, bytes32 dataHash, uint256 threshold) internal pure returns (bytes memory) {
        bytes memory sorted;
        uint256 count = uint256(_signatures.length / 0x41);
        uint256[] memory addressesAndIndexes = new uint256[](threshold);
        address[] memory uniqueAddresses = new address[](threshold);
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 j;
        for (uint256 i; i < count; i++) {
            (v, r, s) = signatureSplit(_signatures, i);
            address owner;
            if (v <= 1) {
                owner = address(uint160(uint256(r)));
            } else if (v > 30) {
                owner =
                    ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash)), v - 4, r, s);
            } else {
                owner = ecrecover(dataHash, v, r, s);
            }

            // skip duplicate owners
            uint256 k;
            for (; k < j; k++) {
                if (uniqueAddresses[k] == owner) break;
            }
            if (k < j) continue;

            uniqueAddresses[j] = owner;
            addressesAndIndexes[j] = uint256(uint256(uint160(owner)) << 0x60 | i); // address in first 160 bits, index in second 96 bits
            j++;

            // we have enough signatures to reach the threshold
            if (j == threshold) break;
        }
        require(j == threshold, "not enough signatures");

        LibSort.sort(addressesAndIndexes);
        for (uint256 i; i < count; i++) {
            uint256 index = addressesAndIndexes[i] & 0xffffffff;
            (v, r, s) = signatureSplit(_signatures, index);
            sorted = bytes.concat(sorted, abi.encodePacked(r, s, v));
        }

        // append the non-static part of the signatures (can contain EIP-1271 signatures if contracts are signers)
        // if there were any duplicates detected above, they will be safely ignored by Safe's checkNSignatures method
        if (_signatures.length > sorted.length) {
            sorted = bytes.concat(sorted, Bytes.slice(_signatures, sorted.length, _signatures.length - sorted.length));
        }

        return sorted;
    }

    // see https://github.com/safe-global/safe-contracts/blob/1ed486bb148fe40c26be58d1b517cec163980027/contracts/common/SignatureDecoder.sol
    function signatureSplit(bytes memory signatures, uint256 pos)
        internal
        pure
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        assembly {
            let signaturePos := mul(0x41, pos)
            r := mload(add(signatures, add(signaturePos, 0x20)))
            s := mload(add(signatures, add(signaturePos, 0x40)))
            v := and(mload(add(signatures, add(signaturePos, 0x41))), 0xff)
        }
    }
}
