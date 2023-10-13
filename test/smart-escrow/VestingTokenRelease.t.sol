// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { CommonTest } from "test/CommonTest.t.sol";
import { MockERC20 } from "test/MockERC20.t.sol";
import "src/smart-escrow/VestingTokenRelease.sol";

contract VestingTokenReleaseTest is CommonTest {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event BeneficiaryOwnerUpdated(address indexed oldOwner, address indexed newOwner);
    event BeneficiaryUpdated(address indexed oldBeneficiary, address indexed newBeneficiary);
    event ContractTerminated();


    MockERC20 public constant OP_TOKEN = MockERC20(0x4200000000000000000000000000000000000042);

    VestingTokenRelease public vestingTokenRelease;
    address public beneficiary = address(1);
    address public beneficiaryOwner = address(2);
    address public escrowOwner = address(3);
    uint256 public start = 1;
    uint256 public end = 2001;
    uint256 public vestingPeriod = 500;
    uint256 public initialTokens = 100;
    uint256 public vestingEventTokens = 50;
    uint256 public totalTokensToRelease = 300;

    function setUp() public override {
        vestingTokenRelease = new VestingTokenRelease(
            beneficiaryOwner,
            beneficiary,
            escrowOwner,
            start,
            end,
            vestingPeriod,
            initialTokens,
            vestingEventTokens
        );

        MockERC20 opToken = new MockERC20("Optimism", "OP");
        vm.etch(0x4200000000000000000000000000000000000042, address(opToken).code);

        vm.prank(address(vestingTokenRelease));
        OP_TOKEN.mint(totalTokensToRelease);
    }

    function test_constructor_zeroAddressBeneficiaryOwner_fails() public {
        bytes4 zeroAddressSelector = bytes4(keccak256("AddressIsZeroAddress()"));
        vm.expectRevert(abi.encodeWithSelector(zeroAddressSelector));
        new VestingTokenRelease(
            address(0),
            beneficiary,
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
        new VestingTokenRelease(
            beneficiaryOwner,
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
        bytes4 zeroAddressSelector = bytes4(keccak256("AddressIsZeroAddress()"));
        vm.expectRevert(abi.encodeWithSelector(zeroAddressSelector));
        new VestingTokenRelease(
            beneficiaryOwner,
            beneficiary,
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
        new VestingTokenRelease(
            beneficiaryOwner,
            beneficiary,
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
        new VestingTokenRelease(
            beneficiaryOwner,
            beneficiary,
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
        new VestingTokenRelease(
            beneficiaryOwner,
            beneficiary,
            escrowOwner,
            start,
            end,
            0,
            initialTokens,
            vestingEventTokens
        );
    }

    function test_terminate_succeeds() public {
        vm.expectEmit(true, true, true, true, address(vestingTokenRelease));
        emit ContractTerminated();

        vm.prank(escrowOwner);
        vestingTokenRelease.terminate(alice);

        bytes4 selector = bytes4(keccak256("ContractIsTerminated()"));
        vm.expectRevert(abi.encodeWithSelector(selector));
        vestingTokenRelease.release();

        // No tokens should have be sent to beneficiary
        assertEq(OP_TOKEN.balanceOf(beneficiary), 0);
        
        // Tokens were released to Alice on termination
        assertEq(OP_TOKEN.balanceOf(alice), totalTokensToRelease);
        assertEq(OP_TOKEN.balanceOf(address(vestingTokenRelease)), 0);
    }

    function test_terminate_afterRelease_succeeds() public {
        vm.warp(1001); // after 2 vesting periods
        uint256 expectedReleased = initialTokens + 2 * vestingEventTokens;
        vm.expectEmit(true, true, true, true, address(OP_TOKEN));
        emit Transfer(address(vestingTokenRelease), beneficiary, expectedReleased);
        vestingTokenRelease.release();

        vm.expectEmit(true, true, true, true, address(vestingTokenRelease));
        emit ContractTerminated();

        vm.prank(escrowOwner);
        vestingTokenRelease.terminate(alice);

        // Expected that some tokens released to beneficiary, rest to Alice and none remain in the contract
        assertEq(OP_TOKEN.balanceOf(beneficiary), expectedReleased);
        assertEq(OP_TOKEN.balanceOf(alice), totalTokensToRelease - expectedReleased);
        assertEq(OP_TOKEN.balanceOf(address(vestingTokenRelease)), 0);
    }

    function test_terminate_unauthorizedCall_fails() public {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(alice);
        vestingTokenRelease.terminate(alice);
        
        // Alice should not have received any tokens
        assertEq(OP_TOKEN.balanceOf(alice), 0);
        assertEq(OP_TOKEN.balanceOf(address(vestingTokenRelease)), totalTokensToRelease);
    }

    function test_updateBeneficiaryOwner_succeeds() public {
        vm.expectEmit(true, true, true, true, address(vestingTokenRelease));
        emit BeneficiaryOwnerUpdated(beneficiaryOwner, alice);
        vm.prank(escrowOwner);
        vestingTokenRelease.updateBeneficiaryOwner(alice);
        assertEq(vestingTokenRelease.beneficiaryOwner(), alice);
    }

    function test_updateBeneficiaryOwner_zeroAddress_fails() public {
        bytes4 zeroAddressSelector = bytes4(keccak256("AddressIsZeroAddress()"));
        vm.expectRevert(abi.encodeWithSelector(zeroAddressSelector));

        vm.prank(escrowOwner);
        vestingTokenRelease.updateBeneficiaryOwner(address(0));
        
        // Beneficiary owner remains the same
        assertEq(vestingTokenRelease.beneficiaryOwner(), beneficiaryOwner);
    }

    function test_updateBeneficiaryOwner_unauthorizedCall_fails() public {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(beneficiaryOwner);
        vestingTokenRelease.updateBeneficiaryOwner(alice);
        
        // Beneficiary owner remains the same
        assertEq(vestingTokenRelease.beneficiaryOwner(), beneficiaryOwner);
    }

    function test_updateBeneficiary_succeeds() public {
        vm.expectEmit(true, true, true, true, address(vestingTokenRelease));
        emit BeneficiaryUpdated(beneficiary, alice);
        vm.prank(beneficiaryOwner);
        vestingTokenRelease.updateBeneficiary(alice);
        assertEq(vestingTokenRelease.beneficiary(), alice);
    }

    function test_updateBeneficiary_zeroAddress_fails() public {
        bytes4 zeroAddressSelector = bytes4(keccak256("AddressIsZeroAddress()"));
        vm.expectRevert(abi.encodeWithSelector(zeroAddressSelector));

        vm.prank(beneficiaryOwner);
        vestingTokenRelease.updateBeneficiary(address(0));
        
        // Beneficiary remains the same
        assertEq(vestingTokenRelease.beneficiary(), beneficiary);
    }

    function test_updateBeneficiary_unauthorizedCall_fails() public {
        bytes4 notOwnerSelector = bytes4(keccak256("CallerIsNotOwner(address,address)"));
        vm.expectRevert(abi.encodeWithSelector(notOwnerSelector, escrowOwner, beneficiaryOwner));
        vm.prank(escrowOwner);
        vestingTokenRelease.updateBeneficiary(alice);
        
        // Beneficiary owner remains the same
        assertEq(vestingTokenRelease.beneficiary(), beneficiary);
    }

    function test_withdrawUnvestedTokens_succeeds() public {
        vm.prank(escrowOwner);
        vestingTokenRelease.terminate(alice);

        // Additional tokens which can be withdrawn
        vm.prank(address(vestingTokenRelease));
        OP_TOKEN.mint(totalTokensToRelease);

        // We expect a Transfer event to be emitted
        vm.expectEmit(true, true, true, true, address(OP_TOKEN));
        emit Transfer(address(vestingTokenRelease), bob, totalTokensToRelease);

        vm.prank(escrowOwner);
        vestingTokenRelease.withdrawUnvestedTokens(bob);
        
        // Tokens were released to Alice on termination and to Bob on the additional withdraw
        assertEq(OP_TOKEN.balanceOf(alice), totalTokensToRelease);
        assertEq(OP_TOKEN.balanceOf(bob), totalTokensToRelease);
        assertEq(OP_TOKEN.balanceOf(address(vestingTokenRelease)), 0);
    }

    function test_withdrawUnvestedTokens_unauthorizedCall_fails() public {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(beneficiaryOwner);
        vestingTokenRelease.withdrawUnvestedTokens(alice);
        
        // No tokens were released
        assertEq(OP_TOKEN.balanceOf(alice), 0);
        assertEq(OP_TOKEN.balanceOf(address(vestingTokenRelease)), totalTokensToRelease);
    }

    function test_withdrawUnvestedTokens_contractStillActive_fails() public {
        bytes4 notTerminatedSelector = bytes4(keccak256("ContractIsNotTerminated()"));
        vm.expectRevert(abi.encodeWithSelector(notTerminatedSelector));
        vm.prank(escrowOwner);
        vestingTokenRelease.withdrawUnvestedTokens(alice);
        
        // No tokens were released
        assertEq(OP_TOKEN.balanceOf(address(vestingTokenRelease)), totalTokensToRelease);

    }

    function test_withdrawUnvestedTokens_zeroReturnAddress_fails() public {
        vm.prank(escrowOwner);
        vestingTokenRelease.terminate(alice);

        bytes4 zeroAddressSelector = bytes4(keccak256("AddressIsZeroAddress()"));
        vm.expectRevert(abi.encodeWithSelector(zeroAddressSelector));
        vm.prank(escrowOwner);
        vestingTokenRelease.withdrawUnvestedTokens(address(0));
    }

    function test_release_beforeScheduleStart_succeeds() public {
        vm.warp(0); // before start
        vestingTokenRelease.release();
        assertEq(OP_TOKEN.balanceOf(beneficiary), 0);
        assertEq(OP_TOKEN.balanceOf(address(vestingTokenRelease)), totalTokensToRelease);
    }

    function test_release_afterScheduleStart_succeeds() public {
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(vestingTokenRelease), beneficiary, initialTokens);
        vm.warp(500); // after start, before first vesting period
        vestingTokenRelease.release();
        assertEq(OP_TOKEN.balanceOf(beneficiary), initialTokens);
        assertEq(OP_TOKEN.balanceOf(address(vestingTokenRelease)), totalTokensToRelease - initialTokens);
    }

    function test_release_afterVestingPeriods_succeeds() public {
        vm.warp(1001); // after 2 vesting periods
        uint256 expectedTokens = initialTokens + 2 * vestingEventTokens;
        vm.expectEmit(true, true, true, true, address(OP_TOKEN));
        emit Transfer(address(vestingTokenRelease), beneficiary, expectedTokens);

        vestingTokenRelease.release();
        assertEq(OP_TOKEN.balanceOf(beneficiary), expectedTokens);
        assertEq(OP_TOKEN.balanceOf(address(vestingTokenRelease)), totalTokensToRelease - expectedTokens);
    }

    function test_release_afterScheduleEnd_succeeds() public {
        vm.warp(2002); // after end time

        vm.expectEmit(true, true, true, true, address(OP_TOKEN));
        emit Transfer(address(vestingTokenRelease), beneficiary, totalTokensToRelease);

        vestingTokenRelease.release();
        assertEq(OP_TOKEN.balanceOf(beneficiary), totalTokensToRelease);
        assertEq(OP_TOKEN.balanceOf(address(vestingTokenRelease)), 0);
    }

    function testFuzz_release(uint256 timestamp) public {
        vm.warp(timestamp);
        uint256 releasable = vestingTokenRelease.releasable();
        vestingTokenRelease.release();

        // assert releasable tokens were sent to beneficiary
        assertEq(OP_TOKEN.balanceOf(beneficiary), releasable);

        // assert amount released is amount we expected to released
        assertEq(vestingTokenRelease.released(), releasable);

        // assert total tokens released is correct
        assertEq(vestingTokenRelease.released() + OP_TOKEN.balanceOf(address(vestingTokenRelease)), totalTokensToRelease);

        // assert that the token vesting is happening in increments
        assertEq(releasable % uint256(50), 0);

        // assert all tokens are released after the end period
        if (timestamp > end) {
            assertEq(vestingTokenRelease.released(), totalTokensToRelease);
        }
    }
}