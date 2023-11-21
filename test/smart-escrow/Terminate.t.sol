// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./BaseSmartEscrow.t.sol";

contract TerminateSmartEscrow is BaseSmartEscrowTest {
    function test_terminate_byBenefactorOwner_succeeds() public {
        vm.warp(start - 1); // before start
        vm.expectEmit(true, true, true, true, address(smartEscrow));
        emit ContractTerminated();

        vm.prank(benefactorOwner);
        smartEscrow.terminate();

        // Additional calls to release should fail
        bytes4 selector = bytes4(keccak256("ContractIsTerminated()"));
        vm.expectRevert(abi.encodeWithSelector(selector));
        smartEscrow.release();

        // All tokens should remain in the contract
        assertEq(OP_TOKEN.balanceOf(address(smartEscrow)), totalTokensToRelease);
    }

    function test_terminate_byBeneficiaryOwner_succeeds() public {
        vm.warp(start + 2 * vestingPeriod); // after 2 vesting periods
        uint256 expectedReleased = initialTokens + 2 * vestingEventTokens;

        vm.expectEmit(true, true, true, true, address(OP_TOKEN));
        emit Transfer(address(smartEscrow), beneficiary, expectedReleased);
        vm.expectEmit(true, true, true, true, address(smartEscrow));
        emit ContractTerminated();

        // Calling terminate should release vested tokens to beneficiary before pausing
        vm.prank(beneficiaryOwner);
        smartEscrow.terminate();

        // Beneficiary should have received vested tokens, rest remain in the contract
        assertEq(OP_TOKEN.balanceOf(beneficiary), expectedReleased);
        assertEq(OP_TOKEN.balanceOf(address(smartEscrow)), totalTokensToRelease - expectedReleased);

        // Additional calls to release should fail
        bytes4 selector = bytes4(keccak256("ContractIsTerminated()"));
        vm.expectRevert(abi.encodeWithSelector(selector));
        smartEscrow.release();

        // Balances should not have changed
        assertEq(OP_TOKEN.balanceOf(beneficiary), expectedReleased);
        assertEq(OP_TOKEN.balanceOf(address(smartEscrow)), totalTokensToRelease - expectedReleased);
    }

    function test_terminate_withdrawAfterTermination_succeeds() public {
        vm.warp(start + 2 * vestingPeriod); // after 2 vesting periods
        uint256 expectedReleased = initialTokens + 2 * vestingEventTokens;

        vm.expectEmit(true, true, true, true, address(OP_TOKEN));
        emit Transfer(address(smartEscrow), beneficiary, expectedReleased);
        vm.expectEmit(true, true, true, true, address(smartEscrow));
        emit ContractTerminated();

        // Calling terminate should release vested tokens to beneficiary before pausing
        vm.prank(benefactorOwner);
        smartEscrow.terminate();

        // Both parties agreed to fully terminate the contract and withdraw unvested tokens
        vm.prank(escrowOwner);
        smartEscrow.withdrawUnvestedTokens();

        // Expected that some tokens released to beneficiary, rest to benefactor and none remain in the contract
        assertEq(OP_TOKEN.balanceOf(beneficiary), expectedReleased);
        assertEq(OP_TOKEN.balanceOf(benefactor), totalTokensToRelease - expectedReleased);
        assertEq(OP_TOKEN.balanceOf(address(smartEscrow)), 0);
    }

    function test_terminate_unauthorizedCall_fails() public {
        vm.expectRevert(accessControlErrorMessage(alice, TERMINATOR_ROLE));
        vm.prank(alice);
        smartEscrow.terminate();
        
        // All tokens should remain in the contract
        assertEq(OP_TOKEN.balanceOf(address(smartEscrow)), totalTokensToRelease);
    }

    function test_terminate_calledTwice_fails() public {
        vm.prank(benefactorOwner);
        smartEscrow.terminate();

        // Second call to terminate should fail
        bytes4 selector = bytes4(keccak256("ContractIsTerminated()"));
        vm.expectRevert(abi.encodeWithSelector(selector));
        vm.prank(benefactorOwner);
        smartEscrow.terminate();
    }
}