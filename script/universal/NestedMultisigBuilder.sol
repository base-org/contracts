// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./MultisigBase.sol";

import { console } from "forge-std/console.sol";
import { IMulticall3 } from "forge-std/interfaces/IMulticall3.sol";

import { IGnosisSafe, Enum } from "@eth-optimism-bedrock/scripts/interfaces/IGnosisSafe.sol";

/**
 * @title NestedMultisigBuilder
 * @notice Modeled from Optimism's SafeBuilder, but built for nested safes (Safes where the signers are other Safes).
 */
abstract contract NestedMultisigBuilder is MultisigBase {
    /**
     * -----------------------------------------------------------
     * Virtual Functions
     * -----------------------------------------------------------
     */

    /**
     * @notice Follow up assertions to ensure that the script ran to completion
     */
    function _postCheck() internal virtual view;

    /**
     * @notice Creates the calldata
     */
    function _buildCalls() internal virtual view returns (IMulticall3.Call3[] memory);

    /**
     * @notice Returns the nested safe address to execute the final transaction from
     */
    function _ownerSafe() internal virtual view returns (address);

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
     * respective multisig.
     *
     * Alternatively, this method can be called by a threshold of signers, and those signatures
     * used by a separate tx executor address in step 2, which doesn't have to be a signer.
     *
     * Example:
     * --------
     * Given a nested 3-of-3 multisig with the following <m1>, <m2>, <m3> multisigs as signers:
     *  - 3-of-3 multisig <m1>, signers <s1>, <s2>, <s3>
     *  - 2-of-3 multisig <m2>, signers <s4>, <s5>, <s6>
     *  - 3-of-3 multisig <m3>, signers <s7>, <s8>, <s9>
     * The following signers should run this function:
        - <s1> => send signature to <s3>
        - <s2> => send signature to <s3>
        - <s4> => send signature to <s5>
     */
    function signApproval(address _signerSafe) public view returns (bool) {
        IMulticall3.Call3 memory call = _generateApproveCall();
        _printDataToSign(_signerSafe, toArray(call));
        return true;
    }

    /**
     * Step 2
     * ======
     * Execute a transaction approval. This method should be called by the final member of each of
     * the multisigs involved in the nested multisig, except the final multisig that will execute.
     * Signatures from step 1 are required.
     *
     * Alternatively, this method can be called after a threshold of signatures is collected from
     * step 1. In this scenario, the caller doesn't need to be a signer of the multisig.
     *
     * Example:
     * --------
     * Given a nested 3-of-3 multisig with the following <m1>, <m2>, <m3> multisigs as signers:
     *  - 3-of-3 multisig <m1>, signers <s1>, <s2>, <s3>
     *  - 2-of-3 multisig <m2>, signers <s4>, <s5>, <s6>
     *  - 3-of-3 multisig <m3>, signers <s7>, <s8>, <s9>
     * The following signers should run this function:
        - <s3> => using signatures from <s1>, <s2>
        - <s5> => using signature from <s4>
     */
    function runApproval(address _signerSafe, bytes memory _signatures) public returns (bool) {
        vm.startBroadcast();
        IMulticall3.Call3 memory call = _generateApproveCall();
        return _executeTransaction(_signerSafe, toArray(call), _signatures);
    }

    /**
     * Step 3
     * ======
     * Generate a transaction execution data to sign. This method should be called by a threshold-1
     * of members of the final multisig that will execute the transaction. Signers will pass their
     * signature to the final signer of this multisig.
     *
     * Alternatively this method can be called by a threshold of signers, and those signatures
     * used by a separate tx executor address in step 4, which doesn't have to be a signer.
     *
     * Example:
     * --------
     * Given a nested 3-of-3 multisig with the following <m1>, <m2>, <m3> multisigs as signers:
     *  - 3-of-3 multisig <m1>, signers <s1>, <s2>, <s3>
     *  - 2-of-3 multisig <m2>, signers <s4>, <s5>, <s6>
     *  - 3-of-3 multisig <m3>, signers <s7>, <s8>, <s9>
     * The following signers should run this function:
        - <s7> => send signature to <s9>
        - <s8> => send signature to <s9>
     */
    function signTransaction(address _signerSafe) public view returns (bool) {
        IMulticall3.Call3 memory call = _generateExecuteCall(_signerSafe);
        _printDataToSign(_signerSafe, toArray(call));
        return true;
    }

    /**
     * Step 4
     * ======
     * Execute the transaction. This method should be called by the final member of the final
     * multisig that will execute the transaction. Signatures from step 3 are required.
     *
     * Alternatively, this method can be called after a threshold of signatures is collected from
     * step 3. In this scenario, the caller doesn't need to be a signer of the multisig.
     *
     * Example:
     * --------
     * Given a nested 3-of-3 multisig with the following <m1>, <m2>, <m3> multisigs as signers:
     *  - 3-of-3 multisig <m1>, signers <s1>, <s2>, <s3>
     *  - 2-of-3 multisig <m2>, signers <s4>, <s5>, <s6>
     *  - 3-of-3 multisig <m3>, signers <s7>, <s8>, <s9>
     * The following signer should run this function:
        - <s9> => using signatures from <s7>, <s8>
     */
    function runTransaction(address _signerSafe, bytes memory _signatures) public returns (bool) {
        vm.startBroadcast();
        IMulticall3.Call3 memory call = _generateExecuteCall(_signerSafe);
        bool success = _executeTransaction(_signerSafe, toArray(call), _signatures);
        if (success) _postCheck();
        return success;
    }

    function _buildCalldata() internal view returns (bytes memory) {
        IMulticall3.Call3[] memory calls = _buildCalls();
        return abi.encodeCall(IMulticall3.aggregate3, (calls));
    }

    function _generateApproveCall() internal view returns (IMulticall3.Call3 memory) {
        address ownerSafeAddress = _ownerSafe();
        IGnosisSafe ownerSafe = IGnosisSafe(payable(ownerSafeAddress));
        bytes memory nestedData = _buildCalldata();
        bytes32 nestedHash = _getTransactionHash(ownerSafeAddress, nestedData);
        console.log("Nested hash:");
        console.logBytes32(nestedHash);

        return IMulticall3.Call3({
            target: ownerSafeAddress,
            allowFailure: false,
            callData: abi.encodeCall(
                ownerSafe.approveHash,
                (nestedHash)
            )
        });
    }

    function _generateExecuteCall(address _signerSafe) internal view returns (IMulticall3.Call3 memory) {
        address ownerSafe = _ownerSafe();
        IGnosisSafe nestedSafe = IGnosisSafe(payable(ownerSafe));
        bytes memory nestedData = _buildCalldata();
        bytes32 nestedHash = _getTransactionHash(ownerSafe, nestedData);

        // get a list of owners that have approved this transaction
        uint256 threshold = nestedSafe.getThreshold();
        address[] memory owners = nestedSafe.getOwners();
        address[] memory approvals = new address[](threshold);
        uint256 approvalIndex;
        for (uint256 i; i < owners.length; i++) {
            address owner = owners[i];
            uint256 approved = nestedSafe.approvedHashes(owner, nestedHash);
            if (approved == 1) {
                approvals[approvalIndex] = owner;
                approvalIndex++;
                if (approvalIndex == threshold - 1) {
                    break;
                }
            }
        }
        require(approvalIndex == threshold - 1, "not enough approvals");
        approvals[approvalIndex] = _signerSafe; // last approver is the current user

        return IMulticall3.Call3({
            target: ownerSafe,
            allowFailure: false,
            callData: abi.encodeCall(
                nestedSafe.execTransaction, (
                    address(multicall),          // to
                    0,                           // value
                    nestedData,                  // data
                    Enum.Operation.DelegateCall, // operation
                    0,                           // safeTxGas
                    0,                           // baseGas
                    0,                           // gasPrice
                    address(0),                  // gasToken
                    payable(address(0)),         // refundReceiver
                    addressSignatures(approvals) // signatures
                )
            )
        });
    }
}
