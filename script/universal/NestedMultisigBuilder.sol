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
     * Generate a transaction approval data to sign. This method should be called by a threshold
     * of members of each of the multisigs involved in the nested multisig. Signers will pass
     * their signature to a facilitator, who will execute the approval transaction for each
     * multisig (see step 2).
     */
    function sign(address _signerSafe) public view returns (bool) {
        IMulticall3.Call3 memory call = _generateApproveCall();
        _printDataToSign(_signerSafe, toArray(call));
        return true;
    }

    /**
     * Step 2
     * ======
     * Execute an approval transaction. This method should be called by a facilitator
     * (non-signer), once for each of the multisigs involved in the nested multisig,
     * after collecting a threshold of signatures for each multisig (see step 1).
     */
    function approve(address _signerSafe, bytes memory _signatures) public returns (bool) {
        vm.startBroadcast();

        IMulticall3.Call3 memory call = _generateApproveCall();
        return _executeTransaction(_signerSafe, toArray(call), _signatures);
    }

    /**
     * Step 3
     * ======
     * Execute the transaction. This method should be called by a facilitator (non-signer), after
     * all of the approval transactions have been submitted onchain (see step 2).
     */
    function run() public returns (bool) {
        vm.startBroadcast();

        address nestedSafeAddress = _ownerSafe();
        IMulticall3.Call3[] memory nestedCalls = _buildCalls();
        address[] memory approvers = _getApprovers(nestedSafeAddress, nestedCalls);
        bytes memory signatures = addressSignatures(approvers);

        bool success = _executeTransaction(nestedSafeAddress, nestedCalls, signatures);
        if (success) _postCheck();
        return success;
    }

    function _generateApproveCall() internal view returns (IMulticall3.Call3 memory) {
        address nestedSafeAddress = _ownerSafe();
        IGnosisSafe nestedSafe = IGnosisSafe(payable(nestedSafeAddress));
        IMulticall3.Call3[] memory nestedCalls = _buildCalls();
        bytes32 nestedHash = _getTransactionHash(nestedSafeAddress, nestedCalls);
        console.log("Nested hash:");
        console.logBytes32(nestedHash);

        return IMulticall3.Call3({
            target: nestedSafeAddress,
            allowFailure: false,
            callData: abi.encodeCall(
                nestedSafe.approveHash,
                (nestedHash)
            )
        });
    }

    function _getApprovers(address safeAddr, IMulticall3.Call3[] memory calls) internal view returns (address[] memory) {
        IGnosisSafe safe = IGnosisSafe(payable(safeAddr));
        bytes32 hash = _getTransactionHash(safeAddr, calls);

        // get a list of owners that have approved this transaction
        uint256 threshold = safe.getThreshold();
        address[] memory owners = safe.getOwners();
        address[] memory approvers = new address[](threshold);
        uint256 approverIndex;
        for (uint256 i; i < owners.length; i++) {
            address owner = owners[i];
            uint256 approved = safe.approvedHashes(owner, hash);
            if (approved == 1) {
                approvers[approverIndex] = owner;
                approverIndex++;
                if (approverIndex == threshold) {
                    break;
                }
            }
        }
        require(approverIndex == threshold, "not enough approvals");
        return approvers;
    }
}
