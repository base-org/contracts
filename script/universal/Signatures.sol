// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Bytes} from "@eth-optimism-bedrock/src/libraries/Bytes.sol";
import {LibSort} from "@solady/utils/LibSort.sol";
import {IGnosisSafe} from "./IGnosisSafe.sol";
import {console} from "forge-std/console.sol";

/**
 * @title Signatures Library
 * @dev Library for handling and validating signatures for a Safe contract.
 */
library Signatures {
    /**
     * @notice Prepares and sorts unique signatures for a Safe transaction.
     * @param _safe Address of the Safe contract.
     * @param hash Hash of the transaction data.
     * @param _signatures Combined signatures data.
     * @return Sorted and unique signatures.
     */
    function prepareSignatures(address _safe, bytes32 hash, bytes memory _signatures)
        internal
        view
        returns (bytes memory)
    {
        address[] memory approvers = getApprovers(_safe, hash);
        bytes memory prevalidatedSignatures = genPrevalidatedSignatures(approvers);
        _signatures = bytes.concat(prevalidatedSignatures, _signatures);

        return sortUniqueSignatures(
            _safe, _signatures, hash, IGnosisSafe(_safe).getThreshold(), prevalidatedSignatures.length
        );
    }

    /**
     * @notice Generates prevalidated signatures for a list of addresses.
     * @param _addresses Array of addresses to generate signatures for.
     * @return Prevalidated signatures as a bytes array.
     */
    function genPrevalidatedSignatures(address[] memory _addresses) internal pure returns (bytes memory) {
        LibSort.sort(_addresses);
        bytes memory signatures;
        for (uint256 i; i < _addresses.length; i++) {
            signatures = bytes.concat(signatures, genPrevalidatedSignature(_addresses[i]));
        }
        return signatures;
    }

    /**
     * @notice Generates a prevalidated signature for a specific address.
     * @param _address Address to generate the signature for.
     * @return A prevalidated signature.
     */
    function genPrevalidatedSignature(address _address) internal pure returns (bytes memory) {
        uint8 v = 1;
        bytes32 s = bytes32(0);
        bytes32 r = bytes32(uint256(uint160(_address)));
        return abi.encodePacked(r, s, v);
    }

    /**
     * @notice Retrieves the list of owners who approved a specific transaction.
     * @param _safe Address of the Safe contract.
     * @param hash Hash of the transaction data.
     * @return Array of addresses that approved the transaction.
     */
    function getApprovers(address _safe, bytes32 hash) internal view returns (address[] memory) {
        IGnosisSafe safe = IGnosisSafe(_safe);
        uint256 threshold = safe.getThreshold();
        address[] memory owners = safe.getOwners();
        address[] memory approvers = new address[](threshold);
        uint256 approverIndex;
        for (uint256 i; i < owners.length; i++) {
            address owner = owners[i];
            if (safe.approvedHashes(owner, hash) == 1) {
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
     * @notice Sorts and removes duplicate signatures.
     * @param _safe Address of the Safe contract.
     * @param _signatures Signature data.
     * @param dataHash Hash of the data being signed.
     * @param threshold Number of required signatures.
     * @param dynamicOffset Offset for dynamic signature data.
     * @return Sorted and unique signatures.
     */
    function sortUniqueSignatures(
        address _safe,
        bytes memory _signatures,
        bytes32 dataHash,
        uint256 threshold,
        uint256 dynamicOffset
    ) internal view returns (bytes memory) {
        bytes memory sorted;
        uint256 count = _signatures.length / 0x41;
        uint256[] memory addressesAndIndexes = new uint256[](threshold);
        address[] memory uniqueAddresses = new address[](threshold);
        uint256 j;

        for (uint256 i; i < count; i++) {
            (address owner, bool isOwner) = extractOwner(_safe, _signatures, dataHash, i);
            if (!isOwner) continue;

            uint256 k;
            for (; k < j; k++) {
                if (uniqueAddresses[k] == owner) break;
            }
            if (k < j) continue;

            uniqueAddresses[j] = owner;
            addressesAndIndexes[j] = uint256(uint256(uint160(owner)) << 0x60 | i);
            j++;

            if (j == threshold) break;
        }
        require(j == threshold, "not enough signatures");

        LibSort.sort(addressesAndIndexes);
        for (uint256 i; i < count; i++) {
            uint256 index = addressesAndIndexes[i] & 0xffffffff;
            (uint8 v, bytes32 r, bytes32 s) = signatureSplit(_signatures, index);
            if (v == 0) {
                s = bytes32(uint256(s) + dynamicOffset);
            }
            sorted = bytes.concat(sorted, abi.encodePacked(r, s, v));
        }
        sorted = appendRemainingBytes(sorted, _signatures);
        return sorted;
    }

    /**
     * @notice Extracts the owner's address from the signature.
     * @param _safe Address of the Safe contract.
     * @param _signatures Signature data.
     * @param dataHash Hash of the data being signed.
     * @param i Index of the signature.
     * @return Extracted owner's address and a boolean indicating ownership.
     */
    function extractOwner(address _safe, bytes memory _signatures, bytes32 dataHash, uint256 i)
        internal
        view
        returns (address, bool)
    {
        (uint8 v, bytes32 r, bytes32 s) = signatureSplit(_signatures, i);
        address owner = extractOwner(dataHash, r, s, v);
        bool isOwner = IGnosisSafe(_safe).isOwner(owner);
        if (!isOwner) {
            console.log("---\nSkipping invalid signature from non-owner: %s", owner);
        }
        return (owner, isOwner);
    }

    /**
     * @notice Extracts the owner's address based on signature components.
     * @param dataHash Hash of the data being signed.
     * @param r R value of the signature.
     * @param s S value of the signature.
     * @param v V value of the signature.
     * @return Address of the signer.
     */
    function extractOwner(bytes32 dataHash, bytes32 r, bytes32 s, uint8 v) internal pure returns (address) {
        if (v <= 1) {
            return address(uint160(uint256(r)));
        }
        if (v > 30) {
            return ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash)), v - 4, r, s);
        }
        return ecrecover(dataHash, v, r, s);
    }

    /**
     * @notice Splits a signature into its components.
     * @param signatures Combined signatures data.
     * @param pos Position of the signature in the array.
     * @return V, R, and S components of the signature.
     */
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

    /**
     * @notice Appends remaining bytes to a bytes array.
     * @param a1 Original bytes array.
     * @param a2 Bytes array to append from.
     * @return Combined bytes array.
     */
    function appendRemainingBytes(bytes memory a1, bytes memory a2) internal pure returns (bytes memory) {
        if (a2.length > a1.length) {
            a1 = bytes.concat(a1, Bytes.slice(a2, a1.length, a2.length - a1.length));
        }
        return a1;
    }
}
