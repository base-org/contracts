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
}