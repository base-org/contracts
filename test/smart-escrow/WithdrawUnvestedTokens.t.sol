// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./BaseSmartEscrow.t.sol";

contract WithdrawUnvestedTokensSmartEscrow is BaseSmartEscrowTest {
    function test_withdrawUnvestedTokens_succeeds() public {
        // Contract terminated
        vm.prank(benefactorOwner);
        smartEscrow.terminate();

        // We expect a Transfer and TokensWithdrawn events to be emitted
        vm.expectEmit(true, true, true, true, address(OP_TOKEN));
        emit Transfer(address(smartEscrow), benefactor, totalTokensToRelease);
        vm.expectEmit(true, true, true, true, address(smartEscrow));
        emit TokensWithdrawn(benefactor, totalTokensToRelease);

        // Tokens withdrawn to benefactor
        vm.prank(escrowOwner);
        smartEscrow.withdrawUnvestedTokens();

        // Benefactor updated
        vm.prank(benefactorOwner);
        smartEscrow.updateBenefactor(alice);

        // Additional tokens sent to contract which can be withdrawn
        vm.prank(address(smartEscrow));
        OP_TOKEN.mint(totalTokensToRelease);

        // We expect a Transfer event to be emitted
        vm.expectEmit(true, true, true, true, address(OP_TOKEN));
        emit Transfer(address(smartEscrow), alice, totalTokensToRelease);

        vm.prank(escrowOwner);
        smartEscrow.withdrawUnvestedTokens();
        
        // Tokens were released to benefactor on termination and to Alice on the additional withdraw
        assertEq(OP_TOKEN.balanceOf(benefactor), totalTokensToRelease);
        assertEq(OP_TOKEN.balanceOf(alice), totalTokensToRelease);
        assertEq(OP_TOKEN.balanceOf(address(smartEscrow)), 0);
    }

    function test_withdrawUnvestedTokens_unauthorizedCall_fails() public {
        vm.expectRevert(accessControlErrorMessage(benefactorOwner, DEFAULT_ADMIN_ROLE));
        vm.prank(benefactorOwner);
        smartEscrow.withdrawUnvestedTokens();

        vm.expectRevert(accessControlErrorMessage(beneficiaryOwner, DEFAULT_ADMIN_ROLE));
        vm.prank(beneficiaryOwner);
        smartEscrow.withdrawUnvestedTokens();
        
        // No tokens were released
        assertEq(OP_TOKEN.balanceOf(benefactor), 0);
        assertEq(OP_TOKEN.balanceOf(address(smartEscrow)), totalTokensToRelease);
    }

    function test_withdrawUnvestedTokens_contractStillActive_fails() public {
        bytes4 notTerminatedSelector = bytes4(keccak256("ContractIsNotTerminated()"));
        vm.expectRevert(abi.encodeWithSelector(notTerminatedSelector));
        vm.prank(escrowOwner);
        smartEscrow.withdrawUnvestedTokens();
        
        // No tokens were released
        assertEq(OP_TOKEN.balanceOf(address(smartEscrow)), totalTokensToRelease);
    }
}
