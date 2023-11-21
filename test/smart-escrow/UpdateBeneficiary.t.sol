// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./BaseSmartEscrow.t.sol";

contract UpdateBeneficiarySmartEscrow is BaseSmartEscrowTest {
    function test_updateBeneficiary_succeeds() public {
        vm.expectEmit(true, true, true, true, address(smartEscrow));
        emit BeneficiaryUpdated(beneficiary, alice);
        vm.prank(beneficiaryOwner);
        smartEscrow.updateBeneficiary(alice);
        assertEq(smartEscrow.beneficiary(), alice);
    }

    function test_updateBeneficiary_newBeneficiaryOwner_succeeds() public {
        address newBeneficiaryOwner = address(1000);
        vm.prank(escrowOwner);
        smartEscrow.grantRole(BENEFICIARY_OWNER_ROLE, newBeneficiaryOwner);
        assertEq(smartEscrow.hasRole(BENEFICIARY_OWNER_ROLE, newBeneficiaryOwner), true);

        vm.expectEmit(true, true, true, true, address(smartEscrow));
        emit BeneficiaryUpdated(beneficiary, alice);
        vm.prank(newBeneficiaryOwner);
        smartEscrow.updateBeneficiary(alice);
        assertEq(smartEscrow.beneficiary(), alice);
    }

    function test_updateBeneficiary_zeroAddress_fails() public {
        bytes4 zeroAddressSelector = bytes4(keccak256("AddressIsZeroAddress()"));
        vm.expectRevert(abi.encodeWithSelector(zeroAddressSelector));

        vm.prank(beneficiaryOwner);
        smartEscrow.updateBeneficiary(address(0));
        
        // Beneficiary remains the same
        assertEq(smartEscrow.beneficiary(), beneficiary);
    }

    function test_updateBeneficiary_unauthorizedCall_fails() public {
        vm.expectRevert(accessControlErrorMessage(escrowOwner, BENEFICIARY_OWNER_ROLE));
        vm.prank(escrowOwner);
        smartEscrow.updateBeneficiary(alice);
        
        // Beneficiary owner remains the same
        assertEq(smartEscrow.beneficiary(), beneficiary);
    }

    function test_updateBeneficiary_oldOwner_fails() public {
        // Remove role from beneficiary owner
        vm.prank(escrowOwner);
        smartEscrow.revokeRole(BENEFICIARY_OWNER_ROLE, beneficiaryOwner);

        vm.expectRevert(accessControlErrorMessage(beneficiaryOwner, BENEFICIARY_OWNER_ROLE));
        vm.prank(beneficiaryOwner);
        smartEscrow.updateBeneficiary(alice);

        // Beneficiary owner remains the same
        assertEq(smartEscrow.beneficiary(), beneficiary);
    }
}