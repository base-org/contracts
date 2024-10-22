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
            cliffStart,
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
            cliffStart,
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
            cliffStart,
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
            cliffStart,
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
            cliffStart,
            end,
            vestingPeriod,
            initialTokens,
            vestingEventTokens
        );
    }

    function test_constructor_cliffStartTimeZero_fails() public {
        vm.warp(100);
        bytes4 pastStartTimeSelector = bytes4(keccak256("CliffStartTimeInvalid(uint256,uint256)"));
        vm.expectRevert(abi.encodeWithSelector(pastStartTimeSelector, 0, start));
        new SmartEscrow(
            benefactor,
            beneficiary,
            benefactorOwner,
            beneficiaryOwner,
            escrowOwner,
            start,
            0,
            end,
            vestingPeriod,
            initialTokens,
            vestingEventTokens
        );
    }

    function test_constructor_startAfterEnd_fails() public {
        bytes4 startAfterEndSelector = bytes4(keccak256("StartTimeAfterEndTime(uint256,uint256)"));
        vm.expectRevert(abi.encodeWithSelector(startAfterEndSelector, end, end));
        new SmartEscrow(
            benefactor,
            beneficiary,
            benefactorOwner,
            beneficiaryOwner,
            escrowOwner,
            end,
            cliffStart,
            end,
            vestingPeriod,
            initialTokens,
            vestingEventTokens
        );
    }

    function test_constructor_cliffStartAfterEnd_fails() public {
        bytes4 startAfterEndSelector = bytes4(keccak256("CliffStartTimeAfterEndTime(uint256,uint256)"));
        vm.expectRevert(abi.encodeWithSelector(startAfterEndSelector, end, end));
        new SmartEscrow(
            benefactor,
            beneficiary,
            benefactorOwner,
            beneficiaryOwner,
            escrowOwner,
            start,
            end,
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
            cliffStart,
            end,
            0,
            initialTokens,
            vestingEventTokens
        );
    }

    function test_constructor_vestingEventTokensZero_fails() public {
        bytes4 vestingEventTokensZeroSelector = bytes4(keccak256("VestingEventTokensIsZero()"));
        vm.expectRevert(abi.encodeWithSelector(vestingEventTokensZeroSelector));
        new SmartEscrow(
            benefactor,
            beneficiary,
            benefactorOwner,
            beneficiaryOwner,
            escrowOwner,
            start,
            cliffStart,
            end,
            vestingPeriod,
            initialTokens,
            0
        );
    }

    function test_constructor_vestingPeriodExceedsContractDuration_fails() public {
        bytes4 vestingPeriodExceedsContractDurationSelector =
            bytes4(keccak256("VestingPeriodExceedsContractDuration(uint256)"));
        vm.expectRevert(abi.encodeWithSelector(vestingPeriodExceedsContractDurationSelector, end));
        new SmartEscrow(
            benefactor,
            beneficiary,
            benefactorOwner,
            beneficiaryOwner,
            escrowOwner,
            start,
            cliffStart,
            end,
            end,
            initialTokens,
            vestingEventTokens
        );
    }

    function test_constructor_unevenVestingPeriod_fails() public {
        bytes4 unevenVestingPeriodSelector = bytes4(keccak256("UnevenVestingPeriod(uint256,uint256,uint256)"));
        uint256 unevenVestingPeriod = 7;
        vm.expectRevert(abi.encodeWithSelector(unevenVestingPeriodSelector, unevenVestingPeriod, start, end));
        new SmartEscrow(
            benefactor,
            beneficiary,
            benefactorOwner,
            beneficiaryOwner,
            escrowOwner,
            start,
            cliffStart,
            end,
            unevenVestingPeriod,
            initialTokens,
            vestingEventTokens
        );
    }
}
