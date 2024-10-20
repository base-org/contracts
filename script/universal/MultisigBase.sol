// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {console} from "forge-std/console.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";
import {IGnosisSafe, Enum} from "./IGnosisSafe.sol";
import {Bytes} from "@eth-optimism-bedrock/src/libraries/Bytes.sol";
import {LibSort} from "@solady/utils/LibSort.sol";
import "./Simulator.sol";

abstract contract MultisigBase is Simulator {
    bytes32 internal constant SAFE_NONCE_SLOT = bytes32(uint256(5));

    function _getTransactionHash(IGnosisSafe _safe, IMulticall3.Call3[] memory calls) internal view returns (bytes32) {
        bytes memory data = abi.encodeCall(IMulticall3.aggregate3, (calls));
        return _getTransactionHash(_safe, data);
    }

    function _getTransactionHash(IGnosisSafe _safe, bytes memory _data) internal view returns (bytes32) {
        return keccak256(_encodeTransactionData(_safe, _data));
    }

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
    function _getNonce(IGnosisSafe safe) internal view virtual returns (uint256 nonce) {
        uint256 safeNonce = safe.nonce();
        nonce = safeNonce;

        // first try SAFE_NONCE
        if (_readFrom_SAFE_NONCE()) {
            try vm.envUint("SAFE_NONCE") {
                nonce = vm.envUint("SAFE_NONCE");
            }
            catch {}
        }

        // then try SAFE_NONCE_{UPPERCASE_SAFE_ADDRESS}
        string memory envVarName = string.concat("SAFE_NONCE_", vm.toUppercase(vm.toString(address(safe))));
        try vm.envUint(envVarName) {
            nonce = vm.envUint(envVarName);
        }
        catch {}

        // print if any override
        if (nonce != safeNonce) {
            console.log("Overriding nonce for safe %s: %d -> %d", address(safe), safeNonce, nonce);
        }
    }

    function _encodeTransactionData(IGnosisSafe _safe, bytes memory _data) internal view returns (bytes memory) {
        // Ensure that the required contracts exist
        require(MULTICALL3_ADDRESS.code.length > 0, "multicall3 not deployed");
        require(address(_safe).code.length > 0, "no code at safe address");

        uint256 nonce = _getNonce(_safe);

        return _safe.encodeTransactionData({
            to: MULTICALL3_ADDRESS,
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

    function _printDataToSign(IGnosisSafe _safe, IMulticall3.Call3[] memory _calls) internal view {
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

    function _checkSignatures(IGnosisSafe _safe, IMulticall3.Call3[] memory _calls, bytes memory _signatures)
        internal
        view
    {
        bytes memory data = abi.encodeCall(IMulticall3.aggregate3, (_calls));
        bytes32 hash = _getTransactionHash(_safe, data);
        _signatures = prepareSignatures(_safe, hash, _signatures);

        _safe.checkSignatures({
            dataHash: hash,
            data: data,
            signatures: _signatures
        });
    }

    function _execTransationCalldata(IGnosisSafe _safe, bytes memory _data, bytes memory _signatures) internal pure returns (bytes memory) {
        return abi.encodeCall(
            _safe.execTransaction,
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

    function _execTransaction(IGnosisSafe _safe, bytes memory _data, bytes memory _signatures) internal returns (bool) {
        return _safe.execTransaction({
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

    function _executeTransaction(IGnosisSafe _safe, IMulticall3.Call3[] memory _calls, bytes memory _signatures)
        internal
        returns (Vm.AccountAccess[] memory, SimulationPayload memory)
    {
        bytes memory data = abi.encodeCall(IMulticall3.aggregate3, (_calls));
        bytes32 hash = _getTransactionHash(_safe, data);
        _signatures = prepareSignatures(_safe, hash, _signatures);

        bytes memory simData = _execTransationCalldata(_safe, data, _signatures);
        logSimulationLink({
            _to: address(_safe),
            _from: msg.sender,
            _data: simData
        });

        vm.startStateDiffRecording();
        bool success = _execTransaction(_safe, data, _signatures);
        Vm.AccountAccess[] memory accesses = vm.stopAndReturnStateDiff();
        require(success, "MultisigBase::_executeTransaction: Transaction failed");
        require(accesses.length > 0, "MultisigBase::_executeTransaction: No state changes");

        // This can be used to e.g. call out to the Tenderly API and get additional
        // data about the state diff before broadcasting the transaction.
        SimulationPayload memory simPayload = SimulationPayload({
            from: msg.sender,
            to: address(_safe),
            data: simData,
            stateOverrides: new SimulationStateOverride[](0)
        });
        return (accesses, simPayload);
    }

    function toArray(IMulticall3.Call3 memory call) internal pure returns (IMulticall3.Call3[] memory) {
        IMulticall3.Call3[] memory calls = new IMulticall3.Call3[](1);
        calls[0] = call;
        return calls;
    }

    function prepareSignatures(IGnosisSafe _safe, bytes32 hash, bytes memory _signatures) internal view returns (bytes memory) {
        // prepend the prevalidated signatures to the signatures
        address[] memory approvers = _getApprovers(_safe, hash);
        bytes memory prevalidatedSignatures = genPrevalidatedSignatures(approvers);
        _signatures = bytes.concat(prevalidatedSignatures, _signatures);

        // safe requires all signatures to be unique, and sorted ascending by public key
        return sortUniqueSignatures(_signatures, hash, _safe.getThreshold(), prevalidatedSignatures.length);
    }

    function genPrevalidatedSignatures(address[] memory _addresses) internal pure returns (bytes memory) {
        LibSort.sort(_addresses);
        bytes memory signatures;
        for (uint256 i; i < _addresses.length; i++) {
            signatures = bytes.concat(signatures, genPrevalidatedSignature(_addresses[i]));
        }
        return signatures;
    }

    function genPrevalidatedSignature(address _address) internal pure returns (bytes memory) {
        uint8 v = 1;
        bytes32 s = bytes32(0);
        bytes32 r = bytes32(uint256(uint160(_address)));
        return abi.encodePacked(r, s, v);
    }

    function _getApprovers(IGnosisSafe _safe, bytes32 hash) internal view returns (address[] memory) {
        // get a list of owners that have approved this transaction
        uint256 threshold = _safe.getThreshold();
        address[] memory owners = _safe.getOwners();
        address[] memory approvers = new address[](threshold);
        uint256 approverIndex;
        for (uint256 i; i < owners.length; i++) {
            address owner = owners[i];
            uint256 approved = _safe.approvedHashes(owner, hash);
            if (approved == 1) {
                approvers[approverIndex] = owner;
                approverIndex++;
                if (approverIndex == threshold) {
                    return approvers;
                }
            }
        }
        address[] memory subset = new address[](approverIndex);
        for (uint256 i; i < approverIndex; i++) {
            subset[i] = approvers[i];
        }
        return subset;
    }

    /**
     * @notice Sorts the signatures in ascending order of the signer's address, and removes any duplicates.
     * @dev see https://github.com/safe-global/safe-smart-account/blob/1ed486bb148fe40c26be58d1b517cec163980027/contracts/Safe.sol#L265-L334
     * @param _signatures Signature data that should be verified.
     *                    Can be packed ECDSA signature ({bytes32 r}{bytes32 s}{uint8 v}), contract signature (EIP-1271) or approved hash.
     *                    Can be suffixed with EIP-1271 signatures after threshold*65 bytes.
     * @param dataHash Hash that is signed.
     * @param threshold Number of signatures required to approve the transaction.
     * @param dynamicOffset Offset to add to the `s` value of any EIP-1271 signature.
     *                      Can be used to accomodate any additional signatures prepended to the array.
     *                      If prevalidated signatures were prepended, this should be the length of those signatures.
     */
    function sortUniqueSignatures(bytes memory _signatures, bytes32 dataHash, uint256 threshold, uint256 dynamicOffset) internal pure returns (bytes memory) {
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
            address owner = extractOwner(dataHash, r, s, v);

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
            if (v == 0) {
                // The `s` value is used by safe as a lookup into the signature bytes.
                // Increment by the offset so that the lookup location remains correct.
                s = bytes32(uint256(s) + dynamicOffset);
            }
            sorted = bytes.concat(sorted, abi.encodePacked(r, s, v));
        }

        // append the non-static part of the signatures (can contain EIP-1271 signatures if contracts are signers)
        // if there were any duplicates detected above, they will be safely ignored by Safe's checkNSignatures method
        sorted = appendRemainingBytes(sorted, _signatures);

        return sorted;
    }

    function appendRemainingBytes(bytes memory a1, bytes memory a2) internal pure returns (bytes memory) {
        if (a2.length > a1.length) {
            a1 = bytes.concat(a1, Bytes.slice(a2, a1.length, a2.length - a1.length));
        }
        return a1;
    }

    function extractOwner(bytes32 dataHash, bytes32 r, bytes32 s, uint8 v) internal pure returns (address) {
        if (v <= 1) {
            return address(uint160(uint256(r)));
        }
        if (v > 30) {
            return ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash)), v - 4, r, s);
        }
        return ecrecover(dataHash, v, r, s);
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
