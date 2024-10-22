// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./BaseSmartEscrow.t.sol";

contract UpdateBenefactorSmartEscrow is BaseSmartEscrowTest {
    function test_updateBenefactor_succeeds() public {
        vm.expectEmit(true, true, true, true, address(smartEscrow));
        emit BenefactorUpdated(benefactor, alice);
        vm.prank(benefactorOwner);
        smartEscrow.updateBenefactor(alice);
        assertEq(smartEscrow.benefactor(), alice);
    }

    function test_updateBenefactor_newBenefactorOwner_succeeds() public {
        address newBenefactorOwner = address(100);
        vm.prank(escrowOwner);
        smartEscrow.grantRole(BENEFACTOR_OWNER_ROLE, newBenefactorOwner);
        assertEq(smartEscrow.hasRole(BENEFACTOR_OWNER_ROLE, newBenefactorOwner), true);

        vm.expectEmit(true, true, true, true, address(smartEscrow));
        emit BenefactorUpdated(benefactor, alice);
        vm.prank(newBenefactorOwner);
        smartEscrow.updateBenefactor(alice);
        assertEq(smartEscrow.benefactor(), alice);
    }

    function test_updateBenefactor_zeroAddress_fails() public {
        bytes4 zeroAddressSelector = bytes4(keccak256("AddressIsZeroAddress()"));
        vm.expectRevert(abi.encodeWithSelector(zeroAddressSelector));

        vm.prank(benefactorOwner);
        smartEscrow.updateBenefactor(address(0));

        // Benefactor remains the same
        assertEq(smartEscrow.benefactor(), benefactor);
    }

    function test_updateBenefactor_unauthorizedCall_fails() public {
        vm.expectRevert(accessControlErrorMessage(escrowOwner, BENEFACTOR_OWNER_ROLE));
        vm.prank(escrowOwner);
        smartEscrow.updateBenefactor(alice);

        // Benefactor owner remains the same
        assertEq(smartEscrow.benefactor(), benefactor);
    }

    function test_updateBenefactor_oldOwner_fails() public {
        // Remove role from benefactor owner
        vm.prank(escrowOwner);
        smartEscrow.revokeRole(BENEFACTOR_OWNER_ROLE, benefactorOwner);

        vm.expectRevert(accessControlErrorMessage(benefactorOwner, BENEFACTOR_OWNER_ROLE));
        vm.prank(benefactorOwner);
        smartEscrow.updateBenefactor(alice);

        // Benefactor owner remains the same
        assertEq(smartEscrow.benefactor(), benefactor);
    }
}
