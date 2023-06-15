// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { console } from "forge-std/console.sol";
import { IMulticall3 } from "forge-std/interfaces/IMulticall3.sol";

import { LibSort } from "@eth-optimism-bedrock/scripts/libraries/LibSort.sol";
import { IGnosisSafe, Enum } from "@eth-optimism-bedrock/scripts/interfaces/IGnosisSafe.sol";
import { EnhancedScript } from "@eth-optimism-bedrock/scripts/universal/EnhancedScript.sol";
import { GlobalConstants } from "@eth-optimism-bedrock/scripts/universal/GlobalConstants.sol";

/**
 * @title NestedMultisigBuilder
 * @notice Modeled from Optimism's SafeBuilder, but built for nested safes.
 */
abstract contract NestedMultisigBuilder is EnhancedScript, GlobalConstants {
    /**
     * @notice Interface for multicall3.
     */
    IMulticall3 internal constant multicall = IMulticall3(MULTICALL3_ADDRESS);

    /**
     * -----------------------------------------------------------
     * Virtual Functions
     * -----------------------------------------------------------
     */

    /**
     * @notice Follow up assertions to ensure that the script ran to completion.
     */
    function _postCheck(address _target) internal virtual view;

    /**
     * @notice Creates the calldata
     */
    function buildCalldata(address _target) internal virtual view returns (bytes memory);

    /**
     * -----------------------------------------------------------
     * Implemented Functions
     * -----------------------------------------------------------
     */

    /**
     * Step 1
     * ======
     * Generate a transaction approval data to sign. This method should be called by a threshold-1
     * of members of each of the multisigs involved in the nested multisig, except the final
     * multisig that will execute. Signers will pass their signature to the final signer of their
     * repsective multisig.
     *
     * Example:
     * --------
     * Given:
     *  - 3-of-3 multisig <m1>, signers <s1>, <s2>, <s3>
     *  - 2-of-3 multisig <m2>, signers <s4>, <s5>, <s6>
     *  - 3-of-3 multisig <m3>, signers <s7>, <s8>, <s9>
     *  - 3-of-3 nested multisig <n>, signers <m1>, <m2>, <m3>
     * The following signers should run this function:
        - <s1> => send signature to <s3>
        - <s2> => send signature to <s3>
        - <s4> => send signature to <s5>
     */
    function signApproval(address _safe, address _nestedSafe, address _target) public returns (bool) {
        IMulticall3.Call3 memory call = _generateApproveCall(_safe, _nestedSafe, _target);
        _printDataToSign(_safe, call);
        return true;
    }

    /**
     * Step 2
     * ======
     * Execute a transaction approval. This method should be called by the final member of each of
     * the multisigs involved in the nested multisig, except the final multisig that will execute.
     * Signatures from step 1 are required.
     *
     * Example:
     * --------
     * Given:
     *  - 3-of-3 multisig <m1>, signers <s1>, <s2>, <s3>
     *  - 2-of-3 multisig <m2>, signers <s4>, <s5>, <s6>
     *  - 3-of-3 multisig <m3>, signers <s7>, <s8>, <s9>
     *  - 3-of-3 nested multisig <n>, signers <m1>, <m2>, <m3>
     * The following signers should run this function:
        - <s3> => using signatures from <s1>, <s2>
        - <s5> => using signature from <s4>
     */
    function runApproval(address _safe, address _nestedSafe, address _target, bytes memory _signatures) public returns (bool) {
        vm.startBroadcast();
        IMulticall3.Call3 memory call = _generateApproveCall(_safe, _nestedSafe, _target);
        return _executeTransaction(_safe, call, _signatures);
    }

    /**
     * Step 3
     * ======
     * Generate a transaction execution data to sign. This method should be called by a threshold-1
     * of members of the final multisig that will execute the transaction. Signers will pass their
     * signature to the final signer of this multisig.
     *
     * Example:
     * --------
     * Given:
     *  - 3-of-3 multisig <m1>, signers <s1>, <s2>, <s3>
     *  - 2-of-3 multisig <m2>, signers <s4>, <s5>, <s6>
     *  - 3-of-3 multisig <m3>, signers <s7>, <s8>, <s9>
     *  - 3-of-3 nested multisig <n>, signers <m1>, <m2>, <m3>
     * The following signers should run this function:
        - <s7> => send signature to <s9>
        - <s8> => send signature to <s9>
     */
    function signTransaction(address _safe, address _nestedSafe, address _target, address[] memory _otherSigners) public returns (bool) {
        IMulticall3.Call3 memory call = _generateExecuteCall(_safe, _nestedSafe, _target, _otherSigners);
        _printDataToSign(_safe, call);
        return true;
    }

    /**
     * Step 4
     * ======
     * Execute the transaction. This method should be called by the final member of the final
     * multisig that will execute the transaction. Signatures from step 3 are required.
     *
     * Example:
     * --------
     * Given:
     *  - 3-of-3 multisig <m1>, signers <s1>, <s2>, <s3>
     *  - 2-of-3 multisig <m2>, signers <s4>, <s5>, <s6>
     *  - 3-of-3 multisig <m3>, signers <s7>, <s8>, <s9>
     *  - 3-of-3 nested multisig <n>, signers <m1>, <m2>, <m3>
     * The following signer should run this function:
        - <s9> => using signatures from <s7>, <s8>
     */
    function runTransaction(address _safe, address _nestedSafe, address _target, address[] memory _otherSigners, bytes memory _signatures) public returns (bool) {
        vm.startBroadcast();
        IMulticall3.Call3 memory call = _generateExecuteCall(_safe, _nestedSafe, _target, _otherSigners);
        bool success = _executeTransaction(_safe, call, _signatures);
        if (success) _postCheck(_target);
        return success;
    }

    function _getTransactionHash(address _safe, bytes memory _data) internal view returns (bytes32) {
        return keccak256(_encodeTransactionData(_safe, _data));
    }

    function _encodeTransactionData(address _safe, bytes memory _data) internal view returns (bytes memory) {
        // Ensure that the required contracts exist
        require(address(multicall).code.length > 0, "multicall3 not deployed");
        require(_safe.code.length > 0, "no code at safe address");

        IGnosisSafe safe = IGnosisSafe(payable(_safe));
        uint256 nonce = safe.nonce();

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

    function _generateApproveCall(address _safe, address _nestedSafe, address _target) internal returns (IMulticall3.Call3 memory) {
        IGnosisSafe safe = IGnosisSafe(payable(_safe));
        IGnosisSafe nestedSafe = IGnosisSafe(payable(_nestedSafe));
        bytes memory nestedData = buildCalldata(_target);
        bytes32 nestedHash = _getTransactionHash(_nestedSafe, nestedData);
        console.log("Nested hash:");
        console.logBytes32(nestedHash);

        return IMulticall3.Call3({
            target: _nestedSafe,
            allowFailure: false,
            callData: abi.encodeCall(
                nestedSafe.approveHash,
                (nestedHash)
            )
        });
    }

    function _generateExecuteCall(address _safe, address _nestedSafe, address _target, address[] memory _signers) internal returns (IMulticall3.Call3 memory) {
        IGnosisSafe safe = IGnosisSafe(payable(_safe));
        IGnosisSafe nestedSafe = IGnosisSafe(payable(_nestedSafe));
        bytes memory nestedData = buildCalldata(_target);

        address[] memory allSigners = new address[](_signers.length + 1);
        for (uint256 i; i < _signers.length; i++) {
            allSigners[i] = _signers[i];
        }
        allSigners[_signers.length] = _safe;

        return IMulticall3.Call3({
            target: _nestedSafe,
            allowFailure: false,
            callData: abi.encodeCall(
                nestedSafe.execTransaction, (
                    address(multicall),           // to
                    0,                            // value
                    nestedData,                   // data
                    Enum.Operation.DelegateCall,  // operation
                    0,                            // safeTxGas
                    0,                            // baseGas
                    0,                            // gasPrice
                    address(0),                   // gasToken
                    payable(address(0)),          // refundReceiver
                    addressSignatures(allSigners) // signatures
                )
            )
        });
    }

    function _printDataToSign(address _safe, IMulticall3.Call3 memory _call) internal {
        IMulticall3.Call3[] memory calls = new IMulticall3.Call3[](1);
        calls[0] = _call;
        bytes memory data = abi.encodeCall(IMulticall3.aggregate3, (calls));

        bytes memory txData = _encodeTransactionData(_safe, data);
        console.log("Data to sign:");
        console.log("vvvvvvvv");
        console.logBytes(txData);
        console.log("^^^^^^^^");
    }

    function _executeTransaction(address _safe, IMulticall3.Call3 memory _call, bytes memory _signatures) internal returns (bool) {
        IGnosisSafe safe = IGnosisSafe(payable(_safe));
        IMulticall3.Call3[] memory calls = new IMulticall3.Call3[](1);
        calls[0] = _call;
        bytes memory data = abi.encodeCall(IMulticall3.aggregate3, (calls));
        bytes32 hash = _getTransactionHash(_safe, data);

        uint8 v = 1;
        bytes32 s = bytes32(0);
        bytes32 r = bytes32(uint256(uint160(msg.sender)));
        _signatures = bytes.concat(_signatures, abi.encodePacked(r, s, v));

        return safe.execTransaction({
            to: address(multicall),
            value: 0,
            data: data,
            operation: Enum.Operation.DelegateCall,
            safeTxGas: 0,
            baseGas: 0,
            gasPrice: 0,
            gasToken: address(0),
            refundReceiver: payable(address(0)),
            signatures: sortSignatures(_signatures, hash)
        });
    }

    function sortSignatures(bytes memory _signatures, bytes32 dataHash) internal returns (bytes memory) {
        bytes memory sorted;
        uint256 count = uint256(_signatures.length / 0x41);
        uint256[] memory addressesAndIndexes = new uint256[](count);
        uint8 v;
        bytes32 r;
        bytes32 s;
        for (uint256 i; i < count; i++) {
            (v, r, s) = signatureSplit(_signatures, i);
            address owner;
            if (v <= 1) {
                owner = address(uint160(uint256(r)));
            } else if (v > 30) {
                owner = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash)), v - 4, r, s);
            } else {
                owner = ecrecover(dataHash, v, r, s);
            }
            addressesAndIndexes[i] = uint256(uint256(uint160(owner)) << 0x60 | i); // address in first 160 bits, index in second 96 bits
        }
        LibSort.sort(addressesAndIndexes);
        for (uint256 i; i < count; i++) {
            uint256 index = addressesAndIndexes[i] & 0xffffffff;
            (v, r, s) = signatureSplit(_signatures, index);
            sorted = bytes.concat(sorted, abi.encodePacked(r, s, v));
        }
        return sorted;
    }

    function addressSignatures(address[] memory _addresses) internal view returns (bytes memory) {
        LibSort.sort(_addresses);
        bytes memory signatures;
        uint8 v = 1;
        bytes32 s = bytes32(0);
        for (uint256 i; i < _addresses.length; i++) {
            bytes32 r = bytes32(uint256(uint160(_addresses[i])));
            signatures = bytes.concat(signatures, abi.encodePacked(r, s, v));
        }
        return signatures;
    }

    // see https://github.com/safe-global/safe-contracts/blob/1ed486bb148fe40c26be58d1b517cec163980027/contracts/common/SignatureDecoder.sol
    function signatureSplit(bytes memory signatures, uint256 pos) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
        assembly {
            let signaturePos := mul(0x41, pos)
            r := mload(add(signatures, add(signaturePos, 0x20)))
            s := mload(add(signatures, add(signaturePos, 0x40)))
            v := and(mload(add(signatures, add(signaturePos, 0x41))), 0xff)
        }
    }
}
