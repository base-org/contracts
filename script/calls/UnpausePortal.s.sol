// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { console } from "forge-std/console.sol";
import { IMulticall3 } from "forge-std/interfaces/IMulticall3.sol";
import { OptimismPortal } from "@eth-optimism-bedrock/contracts/L1/OptimismPortal.sol";
import { SafeBuilder } from "script/SafeBuilder.sol";

/**
 * @title UnpausePortal
 * @notice Script for unpausing Optimism Portal
 */
contract UnpausePortal is SafeBuilder {
    address constant internal PORTAL_ADDR = 0x49048044D57e1C92A77f79988d21Fa8fAF74E97e;

    /**
     * @notice Follow up assertions to ensure that the script ran to completion.
     */
    function _postCheck() internal override view {
        OptimismPortal optimismPortal = OptimismPortal(payable(PORTAL_ADDR));
        require(optimismPortal.paused() == false, "Portal is still paused");
    }

    /**
     * @notice Builds the calldata that the multisig needs to make for the call to happen.
     */
    function buildCalldata() internal override pure returns (bytes memory) {
        IMulticall3.Call3[] memory calls = new IMulticall3.Call3[](1);

        calls[0] = IMulticall3.Call3({
            target: PORTAL_ADDR,
            allowFailure: false,
            callData: abi.encodeCall(OptimismPortal.unpause, ())
        });

        return abi.encodeCall(IMulticall3.aggregate3, (calls));
    }
}