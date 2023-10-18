// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./BaseSmartEscrow.t.sol";

contract TerminateSmartEscrow is BaseSmartEscrowTest {
    function test_terminate_byBenefactorOwner_succeeds() public {
        vm.expectEmit(true, true, true, true, address(smartEscrow));
        emit ContractTerminated();

        vm.prank(benefactorOwner);
        smartEscrow.terminate();

        bytes4 selector = bytes4(keccak256("ContractIsTerminated()"));
        vm.expectRevert(abi.encodeWithSelector(selector));
        smartEscrow.release();

        // All tokens should remain in the contract
        assertEq(OP_TOKEN.balanceOf(address(smartEscrow)), totalTokensToRelease);
    }

    function test_terminate_byBeneficiaryOwner_succeeds() public {
        vm.expectEmit(true, true, true, true, address(smartEscrow));
        emit ContractTerminated();

        vm.prank(beneficiaryOwner);
        smartEscrow.terminate();

        bytes4 selector = bytes4(keccak256("ContractIsTerminated()"));
        vm.expectRevert(abi.encodeWithSelector(selector));
        smartEscrow.release();

        // All tokens should remain in the contract
        assertEq(OP_TOKEN.balanceOf(address(smartEscrow)), totalTokensToRelease);
    }

    function test_terminate_afterRelease_succeeds() public {
        vm.warp(1001); // after 2 vesting periods
        uint256 expectedReleased = initialTokens + 2 * vestingEventTokens;
        vm.expectEmit(true, true, true, true, address(OP_TOKEN));
        emit Transfer(address(smartEscrow), beneficiary, expectedReleased);
        smartEscrow.release();

        vm.expectEmit(true, true, true, true, address(smartEscrow));
        emit ContractTerminated();

        vm.prank(benefactorOwner);
        smartEscrow.terminate();

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
}