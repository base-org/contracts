// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./BaseSmartEscrow.t.sol";

contract ConstructorSmartEscrow is BaseSmartEscrowTest {
    function test_constructor_zeroAddressBenefactor_fails() public {
        bytes4 zeroAddressSelector = bytes4(keccak256("AddressIsZeroAddress()"));
        vm.expectRevert(abi.encodeWithSelector(zeroAddressSelector));
        new SmartEscrow(
            address(0),
            beneficiary,
            benefactorOwner,
            beneficiaryOwner,
            escrowOwner,
            start,
            end,
            vestingPeriod,
            initialTokens,
            vestingEventTokens
        );
    }

    function test_constructor_zeroAddressBeneficiary_fails() public {
        bytes4 zeroAddressSelector = bytes4(keccak256("AddressIsZeroAddress()"));
        vm.expectRevert(abi.encodeWithSelector(zeroAddressSelector));
        new SmartEscrow(
            benefactor,
            address(0),
            benefactorOwner,
            beneficiaryOwner,
            escrowOwner,
            start,
            end,
            vestingPeriod,
            initialTokens,
            vestingEventTokens
        );
    }

    function test_constructor_zeroAddressBenefactorOwner_fails() public {
        bytes4 zeroAddressSelector = bytes4(keccak256("AddressIsZeroAddress()"));
        vm.expectRevert(abi.encodeWithSelector(zeroAddressSelector));
        new SmartEscrow(
            benefactor,
            beneficiary,
            address(0),
            beneficiaryOwner,
            escrowOwner,
            start,
            end,
            vestingPeriod,
            initialTokens,
            vestingEventTokens
        );
    }

    function test_constructor_zeroAddressBeneficiaryOwner_fails() public {
        bytes4 zeroAddressSelector = bytes4(keccak256("AddressIsZeroAddress()"));
        vm.expectRevert(abi.encodeWithSelector(zeroAddressSelector));
        new SmartEscrow(
            benefactor,
            beneficiary,
            benefactorOwner,
            address(0),
            escrowOwner,
            start,
            end,
            vestingPeriod,
            initialTokens,
            vestingEventTokens
        );
    }

    function test_constructor_zeroAddressEscrowOwner_fails() public {
        vm.expectRevert("AccessControl: 0 default admin");
        new SmartEscrow(
            benefactor,
            beneficiary,
            benefactorOwner,
            beneficiaryOwner,
            address(0),
            start,
            end,
            vestingPeriod,
            initialTokens,
            vestingEventTokens
        );
    }

    function test_constructor_startTimeZero_fails() public {
        bytes4 zeroStartSelector = bytes4(keccak256("StartTimeIsZero()"));
        vm.expectRevert(abi.encodeWithSelector(zeroStartSelector));
        new SmartEscrow(
            benefactor,
            beneficiary,
            benefactorOwner,
            beneficiaryOwner,
            escrowOwner,
            0,
            end,
            vestingPeriod,
            initialTokens,
            vestingEventTokens
        );
    }

    function test_constructor_startAfterEnd_fails() public {
        bytes4 startAfterEndSelector = bytes4(keccak256("StartTimeAfterEndTime(uint256,uint256)"));
        uint256 lateStart = 2002;
        vm.expectRevert(abi.encodeWithSelector(startAfterEndSelector, lateStart, end));
        new SmartEscrow(
            benefactor,
            beneficiary,
            benefactorOwner,
            beneficiaryOwner,
            escrowOwner,
            lateStart,
            end,
            vestingPeriod,
            initialTokens,
            vestingEventTokens
        );
    }

    function test_constructor_vestingPeriodZero_fails() public {
        bytes4 vestingPeriodZeroSelector = bytes4(keccak256("VestingPeriodIsZeroSeconds()"));
        vm.expectRevert(abi.encodeWithSelector(vestingPeriodZeroSelector));
        new SmartEscrow(
            benefactor,
            beneficiary,
            benefactorOwner,
            beneficiaryOwner,
            escrowOwner,
            start,
            end,
            0,
            initialTokens,
            vestingEventTokens
        );
    }
}