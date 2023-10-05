// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { CommonTest } from "test/CommonTest.t.sol";
import { MockERC20 } from "test/MockERC20.t.sol";
import "src/smart-escrow/SmartEscrow.sol";

contract SmartEscrowTest is CommonTest {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event BeneficiaryOwnerUpdated(address indexed oldOwner, address indexed newOwner);
    event BeneficiaryUpdated(address indexed oldBeneficiary, address indexed newBeneficiary);
    event ContractTerminated();


    MockERC20 public constant OP_TOKEN = MockERC20(0x4200000000000000000000000000000000000042);

    SmartEscrow public smartEscrow;
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
        smartEscrow = new SmartEscrow(
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

        vm.prank(address(smartEscrow));
        OP_TOKEN.mint(totalTokensToRelease);
    }

    function test_constructor_zeroAddressBeneficiaryOwner_fails() public {
        bytes4 zeroAddressSelector = bytes4(keccak256("AddressIsZeroAddress()"));
        vm.expectRevert(abi.encodeWithSelector(zeroAddressSelector));
        new SmartEscrow(
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
        new SmartEscrow(
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
        new SmartEscrow(
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
        new SmartEscrow(
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
        new SmartEscrow(
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
        new SmartEscrow(
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
        vm.expectEmit(true, true, true, true, address(smartEscrow));
        emit ContractTerminated();

        vm.prank(escrowOwner);
        smartEscrow.terminate(alice);

        bytes4 selector = bytes4(keccak256("ContractIsTerminated()"));
        vm.expectRevert(abi.encodeWithSelector(selector));
        smartEscrow.release();

        // No tokens should have be sent to beneficiary
        assertEq(OP_TOKEN.balanceOf(beneficiary), 0);
        
        // Tokens were released to Alice on termination
        assertEq(OP_TOKEN.balanceOf(alice), totalTokensToRelease);
        assertEq(OP_TOKEN.balanceOf(address(smartEscrow)), 0);
    }

    function test_terminate_afterRelease_succeeds() public {
        vm.warp(1001); // after 2 vesting periods
        uint256 expectedReleased = initialTokens + 2 * vestingEventTokens;
        vm.expectEmit(true, true, true, true, address(OP_TOKEN));
        emit Transfer(address(smartEscrow), beneficiary, expectedReleased);
        smartEscrow.release();

        vm.expectEmit(true, true, true, true, address(smartEscrow));
        emit ContractTerminated();

        vm.prank(escrowOwner);
        smartEscrow.terminate(alice);

        // Expected that some tokens released to beneficiary, rest to Alice and none remain in the contract
        assertEq(OP_TOKEN.balanceOf(beneficiary), expectedReleased);
        assertEq(OP_TOKEN.balanceOf(alice), totalTokensToRelease - expectedReleased);
        assertEq(OP_TOKEN.balanceOf(address(smartEscrow)), 0);
    }

    function test_terminate_unauthorizedCall_fails() public {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(alice);
        smartEscrow.terminate(alice);
        
        // Alice should not have received any tokens
        assertEq(OP_TOKEN.balanceOf(alice), 0);
        assertEq(OP_TOKEN.balanceOf(address(smartEscrow)), totalTokensToRelease);
    }

    function test_updateBeneficiaryOwner_succeeds() public {
        vm.expectEmit(true, true, true, true, address(smartEscrow));
        emit BeneficiaryOwnerUpdated(beneficiaryOwner, alice);
        vm.prank(escrowOwner);
        smartEscrow.updateBeneficiaryOwner(alice);
        assertEq(smartEscrow.beneficiaryOwner(), alice);
    }

    function test_updateBeneficiaryOwner_zeroAddress_fails() public {
        bytes4 zeroAddressSelector = bytes4(keccak256("AddressIsZeroAddress()"));
        vm.expectRevert(abi.encodeWithSelector(zeroAddressSelector));

        vm.prank(escrowOwner);
        smartEscrow.updateBeneficiaryOwner(address(0));
        
        // Beneficiary owner remains the same
        assertEq(smartEscrow.beneficiaryOwner(), beneficiaryOwner);
    }

    function test_updateBeneficiaryOwner_unauthorizedCall_fails() public {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(beneficiaryOwner);
        smartEscrow.updateBeneficiaryOwner(alice);
        
        // Beneficiary owner remains the same
        assertEq(smartEscrow.beneficiaryOwner(), beneficiaryOwner);
    }

    function test_updateBeneficiary_succeeds() public {
        vm.expectEmit(true, true, true, true, address(smartEscrow));
        emit BeneficiaryUpdated(beneficiary, alice);
        vm.prank(beneficiaryOwner);
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
        bytes4 notOwnerSelector = bytes4(keccak256("CallerIsNotOwner(address,address)"));
        vm.expectRevert(abi.encodeWithSelector(notOwnerSelector, escrowOwner, beneficiaryOwner));
        vm.prank(escrowOwner);
        smartEscrow.updateBeneficiary(alice);
        
        // Beneficiary owner remains the same
        assertEq(smartEscrow.beneficiary(), beneficiary);
    }

    function test_withdrawUnvestedTokens_succeeds() public {
        vm.prank(escrowOwner);
        smartEscrow.terminate(alice);

        // Additional tokens which can be withdrawn
        vm.prank(address(smartEscrow));
        OP_TOKEN.mint(totalTokensToRelease);

        // We expect a Transfer event to be emitted
        vm.expectEmit(true, true, true, true, address(OP_TOKEN));
        emit Transfer(address(smartEscrow), bob, totalTokensToRelease);

        vm.prank(escrowOwner);
        smartEscrow.withdrawUnvestedTokens(bob);
        
        // Tokens were released to Alice on termination and to Bob on the additional withdraw
        assertEq(OP_TOKEN.balanceOf(alice), totalTokensToRelease);
        assertEq(OP_TOKEN.balanceOf(bob), totalTokensToRelease);
        assertEq(OP_TOKEN.balanceOf(address(smartEscrow)), 0);
    }

    function test_withdrawUnvestedTokens_unauthorizedCall_fails() public {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(beneficiaryOwner);
        smartEscrow.withdrawUnvestedTokens(alice);
        
        // No tokens were released
        assertEq(OP_TOKEN.balanceOf(alice), 0);
        assertEq(OP_TOKEN.balanceOf(address(smartEscrow)), totalTokensToRelease);
    }

    function test_withdrawUnvestedTokens_contractStillActive_fails() public {
        bytes4 notTerminatedSelector = bytes4(keccak256("ContractIsNotTerminated()"));
        vm.expectRevert(abi.encodeWithSelector(notTerminatedSelector));
        vm.prank(escrowOwner);
        smartEscrow.withdrawUnvestedTokens(alice);
        
        // No tokens were released
        assertEq(OP_TOKEN.balanceOf(address(smartEscrow)), totalTokensToRelease);

    }

    function test_withdrawUnvestedTokens_zeroReturnAddress_fails() public {
        vm.prank(escrowOwner);
        smartEscrow.terminate(alice);

        bytes4 zeroAddressSelector = bytes4(keccak256("AddressIsZeroAddress()"));
        vm.expectRevert(abi.encodeWithSelector(zeroAddressSelector));
        vm.prank(escrowOwner);
        smartEscrow.withdrawUnvestedTokens(address(0));
    }

    function test_release_beforeScheduleStart_succeeds() public {
        vm.warp(0); // before start
        smartEscrow.release();
        assertEq(OP_TOKEN.balanceOf(beneficiary), 0);
        assertEq(OP_TOKEN.balanceOf(address(smartEscrow)), totalTokensToRelease);
    }

    function test_release_afterScheduleStart_succeeds() public {
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(smartEscrow), beneficiary, initialTokens);
        vm.warp(500); // after start, before first vesting period
        smartEscrow.release();
        assertEq(OP_TOKEN.balanceOf(beneficiary), initialTokens);
        assertEq(OP_TOKEN.balanceOf(address(smartEscrow)), totalTokensToRelease - initialTokens);
    }

    function test_release_afterVestingPeriods_succeeds() public {
        vm.warp(1001); // after 2 vesting periods
        uint256 expectedTokens = initialTokens + 2 * vestingEventTokens;
        vm.expectEmit(true, true, true, true, address(OP_TOKEN));
        emit Transfer(address(smartEscrow), beneficiary, expectedTokens);

        smartEscrow.release();
        assertEq(OP_TOKEN.balanceOf(beneficiary), expectedTokens);
        assertEq(OP_TOKEN.balanceOf(address(smartEscrow)), totalTokensToRelease - expectedTokens);
    }

    function test_release_afterScheduleEnd_succeeds() public {
        vm.warp(2002); // after end time

        vm.expectEmit(true, true, true, true, address(OP_TOKEN));
        emit Transfer(address(smartEscrow), beneficiary, totalTokensToRelease);

        smartEscrow.release();
        assertEq(OP_TOKEN.balanceOf(beneficiary), totalTokensToRelease);
        assertEq(OP_TOKEN.balanceOf(address(smartEscrow)), 0);
    }

    function testFuzz_release(uint256 timestamp) public {
        vm.warp(timestamp);
        uint256 releasable = smartEscrow.releasable();
        smartEscrow.release();

        // assert releasable tokens were sent to beneficiary
        assertEq(OP_TOKEN.balanceOf(beneficiary), releasable);

        // assert amount released is amount we expected to released
        assertEq(smartEscrow.released(), releasable);

        // assert total tokens released is correct
        assertEq(smartEscrow.released() + OP_TOKEN.balanceOf(address(smartEscrow)), totalTokensToRelease);

        // assert that the token vesting is happening in increments
        assertEq(releasable % uint256(50), 0);

        // assert all tokens are released after the end period
        if (timestamp > end) {
            assertEq(smartEscrow.released(), totalTokensToRelease);
        }
    }
}