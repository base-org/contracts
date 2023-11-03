// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./BaseSmartEscrow.t.sol";

contract ResumeSmartEscrow is BaseSmartEscrowTest {
    function test_resume_succeeds() public {
        // Contract was terminated
        vm.prank(benefactorOwner);
        smartEscrow.terminate();

        vm.expectEmit(true, true, true, true, address(smartEscrow));
        emit ContractResumed();

        // Contract is resumed
        vm.prank(escrowOwner);
        smartEscrow.resume();

        vm.warp(end + 1); // All tokens are releasable at this time
        smartEscrow.release();

        // All tokens should have been released
        assertEq(OP_TOKEN.balanceOf(beneficiary), totalTokensToRelease);
        assertEq(OP_TOKEN.balanceOf(address(smartEscrow)), 0);
    }

    function test_resume_unauthorizedCall_fails() public {
        // Contract was terminated
        vm.prank(benefactorOwner);
        smartEscrow.terminate();

        // Unauthorized call to resume
        vm.expectRevert(accessControlErrorMessage(benefactorOwner, DEFAULT_ADMIN_ROLE));
        vm.prank(benefactorOwner);
        smartEscrow.resume();

        // Attempt to release tokens
        bytes4 selector = bytes4(keccak256("ContractIsTerminated()"));
        vm.expectRevert(abi.encodeWithSelector(selector));
        smartEscrow.release();
        
        // All tokens should remain in the contract
        assertEq(OP_TOKEN.balanceOf(address(smartEscrow)), totalTokensToRelease);
    }

    function test_resume_calledWhenContractNotTerminated_fails() public {
        bytes4 selector = bytes4(keccak256("ContractIsNotTerminated()"));
        vm.expectRevert(abi.encodeWithSelector(selector));
        vm.prank(escrowOwner);
        smartEscrow.resume();
    }
}