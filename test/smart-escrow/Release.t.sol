// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./BaseSmartEscrow.t.sol";

contract ReleaseSmartEscrow is BaseSmartEscrowTest {
    function test_release_beforeScheduleStart_succeeds() public {
        vm.warp(start - 1); // before start
        smartEscrow.release();
        assertEq(OP_TOKEN.balanceOf(beneficiary), 0);
        assertEq(OP_TOKEN.balanceOf(address(smartEscrow)), totalTokensToRelease);
    }

    function test_release_afterCliffStart_succeeds() public {
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(smartEscrow), beneficiary, initialTokens);
        vm.expectEmit(true, true, true, true, address(smartEscrow));
        emit TokensReleased(beneficiary, initialTokens);
        vm.warp(cliffStart + 1); // after start, before first vesting period
        smartEscrow.release();
        assertEq(OP_TOKEN.balanceOf(beneficiary), initialTokens);
        assertEq(OP_TOKEN.balanceOf(address(smartEscrow)), totalTokensToRelease - initialTokens);
    }

    function test_release_afterVestingPeriods_succeeds() public {
        vm.warp(start + 2 * vestingPeriod); // after 2 vesting periods, includes cliff
        uint256 expectedTokens = initialTokens + 2 * vestingEventTokens;
        vm.expectEmit(true, true, true, true, address(OP_TOKEN));
        emit Transfer(address(smartEscrow), beneficiary, expectedTokens);

        smartEscrow.release();
        assertEq(OP_TOKEN.balanceOf(beneficiary), expectedTokens);
        assertEq(OP_TOKEN.balanceOf(address(smartEscrow)), totalTokensToRelease - expectedTokens);
    }

    function test_release_afterScheduleEnd_succeeds() public {
        vm.warp(end + 1); // after end time

        vm.expectEmit(true, true, true, true, address(OP_TOKEN));
        emit Transfer(address(smartEscrow), beneficiary, totalTokensToRelease);

        smartEscrow.release();
        assertEq(OP_TOKEN.balanceOf(beneficiary), totalTokensToRelease);
        assertEq(OP_TOKEN.balanceOf(address(smartEscrow)), 0);
    }

    function test_release_notEnoughTokens_reverts() public {
        vm.prank(address(smartEscrow));
        OP_TOKEN.burn(totalTokensToRelease);

        vm.expectRevert("ERC20: transfer amount exceeds balance");

        vm.warp(cliffStart + 1);
        smartEscrow.release();
        assertEq(OP_TOKEN.balanceOf(beneficiary), 0);
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

        if (timestamp > start && timestamp < end) {
            // assert that the token vesting is happening in increments
            assertEq((releasable - initialTokens) % uint256(vestingEventTokens), 0);
        }

        // assert all tokens are released after the end period
        if (timestamp > end) {
            assertEq(smartEscrow.released(), totalTokensToRelease);
        }
    }
}