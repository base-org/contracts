// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {CommonTest} from "test/CommonTest.t.sol";
import {FeeVaultRevert} from "test/revenue-share/mocks/FeeVaultRevert.sol";
import {OptimismWalletRevert} from "test/revenue-share/mocks/OptimismWalletRevert.sol";

import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {L2StandardBridge} from "@eth-optimism-bedrock/src/L2/L2StandardBridge.sol";
import {SequencerFeeVault, FeeVault} from "@eth-optimism-bedrock/src/L2/SequencerFeeVault.sol";
import {BaseFeeVault} from "@eth-optimism-bedrock/src/L2/BaseFeeVault.sol";
import {L1FeeVault} from "@eth-optimism-bedrock/src/L2/L1FeeVault.sol";
import {Predeploys} from "@eth-optimism-bedrock/src/libraries/Predeploys.sol";

import {FeeDisburser} from "src/revenue-share/FeeDisburser.sol";

contract FeeDisburserTest is CommonTest {
    event FeesDisbursed(uint256 _disbursementTime, uint256 _paidToOptimism, uint256 _totalFeesDisbursed);
    event FeesReceived(address indexed _sender, uint256 _amount);
    event NoFeesCollected();

    uint256 constant BASIS_POINTS_SCALE = 10_000;
    uint256 constant WITHDRAWAL_MIN_GAS = 35_000;

    TransparentUpgradeableProxy feeDisburserProxy;
    FeeDisburser feeDisburserImplementation;
    FeeDisburser feeDisburser;
    SequencerFeeVault sequencerFeeVault;
    BaseFeeVault baseFeeVault;
    L1FeeVault l1FeeVault;
    address payable optimismWallet = payable(address(1000));
    address payable l1Wallet = payable(address(1001));
    // 15% denominated in base points
    uint256 optimismNetRevenueShareBasisPoints = 1_500;
    // 2.5% denominated in base points
    uint256 optimismGrossRevenueShareBasisPoints = 250;
    // 101% denominated in basis points
    uint256 tooLargeBasisPoints = 10_001;
    // Denominated in seconds
    uint256 feeDisbursementInterval = 24 hours;
    uint256 minimumWithdrawalAmount = 10 ether;
    address proxyAdminOwner = address(2048);

    bytes MINIMUM_WITHDRAWAL_AMOUNT_SIGNATURE = abi.encodeWithSignature("MIN_WITHDRAWAL_AMOUNT()");
    bytes WITHDRAW_SIGNATURE = abi.encodeWithSignature("withdraw()");

    function setUp() public override {
        super.setUp();
        vm.warp(feeDisbursementInterval);

        feeDisburserImplementation = new FeeDisburser(optimismWallet, l1Wallet, feeDisbursementInterval);
        feeDisburserProxy =
            new TransparentUpgradeableProxy(address(feeDisburserImplementation), proxyAdminOwner, NULL_BYTES);
        feeDisburser = FeeDisburser(payable(address(feeDisburserProxy)));

        sequencerFeeVault = new SequencerFeeVault(
            payable(address(feeDisburser)), minimumWithdrawalAmount, FeeVault.WithdrawalNetwork.L2
        );
        baseFeeVault =
            new BaseFeeVault(payable(address(feeDisburser)), minimumWithdrawalAmount, FeeVault.WithdrawalNetwork.L2);
        l1FeeVault =
            new L1FeeVault(payable(address(feeDisburser)), minimumWithdrawalAmount, FeeVault.WithdrawalNetwork.L2);

        vm.etch(Predeploys.SEQUENCER_FEE_WALLET, address(sequencerFeeVault).code);
        vm.etch(Predeploys.BASE_FEE_VAULT, address(baseFeeVault).code);
        vm.etch(Predeploys.L1_FEE_VAULT, address(l1FeeVault).code);
    }

    function test_constructor_fail_optimismWallet_ZeroAddress() external {
        vm.expectRevert("FeeDisburser: OptimismWallet cannot be address(0)");
        new FeeDisburser(payable(address(0)), l1Wallet, feeDisbursementInterval);
    }

    function test_constructor_fail_l1Wallet_ZeroAddress() external {
        vm.expectRevert("FeeDisburser: L1Wallet cannot be address(0)");
        new FeeDisburser(optimismWallet, payable(address(0)), feeDisbursementInterval);
    }

    function test_constructor_fail_feeDisbursementInterval_lessThan24Hours() external {
        vm.expectRevert("FeeDisburser: FeeDisbursementInterval cannot be less than 24 hours");
        new FeeDisburser(optimismWallet, l1Wallet, 24 hours - 1);
    }

    function test_constructor_success() external {
        feeDisburserImplementation = new FeeDisburser(optimismWallet, l1Wallet, feeDisbursementInterval);
        assertEq(feeDisburserImplementation.OPTIMISM_WALLET(), optimismWallet);
        assertEq(feeDisburserImplementation.L1_WALLET(), l1Wallet);
    }

    function test_disburseFees_fail_feeDisbursementInterval_Zero() external {
        // Setup so that the first disburse fees actually does a disbursal and doesn't return early
        vm.deal(Predeploys.SEQUENCER_FEE_WALLET, minimumWithdrawalAmount * 2);
        vm.mockCall(
            Predeploys.L2_STANDARD_BRIDGE,
            abi.encodeWithSignature("bridgeETHTo(address,uint256,bytes)", l1Wallet, WITHDRAWAL_MIN_GAS, NULL_BYTES),
            NULL_BYTES
        );

        feeDisburser.disburseFees();
        vm.expectRevert("FeeDisburser: Disbursement interval not reached");
        feeDisburser.disburseFees();
    }

    function test_disburseFees_fail_feeVaultWithdrawalToL1() external {
        sequencerFeeVault = new SequencerFeeVault(
            payable(address(feeDisburser)), minimumWithdrawalAmount, FeeVault.WithdrawalNetwork.L1
        );
        vm.etch(Predeploys.SEQUENCER_FEE_WALLET, address(sequencerFeeVault).code);

        vm.expectRevert("FeeDisburser: FeeVault must withdraw to L2");
        feeDisburser.disburseFees();
    }

    function test_disburseFees_fail_feeVaultWithdrawalToAnotherAddress() external {
        sequencerFeeVault = new SequencerFeeVault(admin, minimumWithdrawalAmount, FeeVault.WithdrawalNetwork.L2);
        vm.etch(Predeploys.SEQUENCER_FEE_WALLET, address(sequencerFeeVault).code);

        vm.expectRevert("FeeDisburser: FeeVault must withdraw to FeeDisburser contract");
        feeDisburser.disburseFees();
    }

    function test_disburseFees_fail_sendToOptimismFails() external {
        // Define a new feeDisburser for which the OP Wallet always reverts when receiving funds
        OptimismWalletRevert optimismWalletRevert = new OptimismWalletRevert();
        FeeDisburser feeDisburser2 =
            new FeeDisburser(payable(address(optimismWalletRevert)), l1Wallet, feeDisbursementInterval);

        // Have the fee vaults point to the new fee disburser contract
        sequencerFeeVault = new SequencerFeeVault(
            payable(address(feeDisburser2)), minimumWithdrawalAmount, FeeVault.WithdrawalNetwork.L2
        );
        vm.etch(Predeploys.SEQUENCER_FEE_WALLET, address(sequencerFeeVault).code);
        baseFeeVault =
            new BaseFeeVault(payable(address(feeDisburser2)), minimumWithdrawalAmount, FeeVault.WithdrawalNetwork.L2);
        vm.etch(Predeploys.BASE_FEE_VAULT, address(baseFeeVault).code);
        l1FeeVault =
            new L1FeeVault(payable(address(feeDisburser2)), minimumWithdrawalAmount, FeeVault.WithdrawalNetwork.L2);
        vm.etch(Predeploys.L1_FEE_VAULT, address(l1FeeVault).code);

        vm.deal(Predeploys.SEQUENCER_FEE_WALLET, minimumWithdrawalAmount);

        vm.expectRevert("FeeDisburser: Failed to send funds to Optimism");
        feeDisburser2.disburseFees();
    }

    function test_disburseFees_fail_minimumWithdrawalReversion() external {
        FeeVaultRevert feeVaultRevert = new FeeVaultRevert(address(feeDisburser));
        vm.etch(Predeploys.SEQUENCER_FEE_WALLET, address(feeVaultRevert).code);

        vm.expectRevert("revert message");
        feeDisburser.disburseFees();
    }

    function test_disburseFees_fail_withdrawalReversion() external {
        vm.mockCall(Predeploys.SEQUENCER_FEE_WALLET, MINIMUM_WITHDRAWAL_AMOUNT_SIGNATURE, abi.encode(ZERO_VALUE));

        vm.expectRevert("FeeVault: withdrawal amount must be greater than minimum withdrawal amount");
        feeDisburser.disburseFees();
    }

    function test_disburseFees_success_noFees() external {
        vm.expectEmit(true, true, true, true, address(feeDisburser));
        emit NoFeesCollected();
        feeDisburser.disburseFees();

        assertEq(feeDisburser.OPTIMISM_WALLET().balance, ZERO_VALUE);
        assertEq(Predeploys.L2_STANDARD_BRIDGE.balance, ZERO_VALUE);
    }

    function test_disburseFees_success_netRevenueMax() external {
        // 15% of minimumWithdrawalAmount * 2 > 2.5 % of minimumWithdrawalAmount * 11
        uint256 sequencerFeeVaultBalance = minimumWithdrawalAmount;
        uint256 baseFeeVaultBalance = minimumWithdrawalAmount;
        uint256 l1FeeVaultBalance = minimumWithdrawalAmount * 9;
        vm.deal(Predeploys.SEQUENCER_FEE_WALLET, sequencerFeeVaultBalance);
        vm.deal(Predeploys.BASE_FEE_VAULT, baseFeeVaultBalance);
        vm.deal(Predeploys.L1_FEE_VAULT, l1FeeVaultBalance);

        uint256 netFeeVaultBalance = sequencerFeeVaultBalance + baseFeeVaultBalance;
        uint256 totalFeeVaultBalance = netFeeVaultBalance + l1FeeVaultBalance;
        uint256 expectedOptimismWalletBalance =
            netFeeVaultBalance * optimismNetRevenueShareBasisPoints / BASIS_POINTS_SCALE;
        uint256 expectedBridgeWithdrawalBalance = totalFeeVaultBalance - expectedOptimismWalletBalance;

        vm.mockCall(
            Predeploys.L2_STANDARD_BRIDGE,
            abi.encodeWithSignature("bridgeETHTo(address,uint256,bytes)", l1Wallet, WITHDRAWAL_MIN_GAS, NULL_BYTES),
            NULL_BYTES
        );

        vm.expectEmit(true, true, true, true, address(feeDisburser));
        emit FeesDisbursed(block.timestamp, expectedOptimismWalletBalance, totalFeeVaultBalance);
        feeDisburser.disburseFees();

        assertEq(feeDisburser.lastDisbursementTime(), block.timestamp);
        assertEq(feeDisburser.netFeeRevenue(), ZERO_VALUE);
        assertEq(feeDisburser.OPTIMISM_WALLET().balance, expectedOptimismWalletBalance);
        assertEq(Predeploys.L2_STANDARD_BRIDGE.balance, expectedBridgeWithdrawalBalance);
    }

    function test_disburseFees_success_grossRevenueMax() external {
        // 15% of minimumWithdrawalAmount * 2 > 2.5 % of minimumWithdrawalAmount * 13
        uint256 sequencerFeeVaultBalance = minimumWithdrawalAmount;
        uint256 baseFeeVaultBalance = minimumWithdrawalAmount;
        uint256 l1FeeVaultBalance = minimumWithdrawalAmount * 11;
        vm.deal(Predeploys.SEQUENCER_FEE_WALLET, sequencerFeeVaultBalance);
        vm.deal(Predeploys.BASE_FEE_VAULT, baseFeeVaultBalance);
        vm.deal(Predeploys.L1_FEE_VAULT, l1FeeVaultBalance);

        uint256 totalFeeVaultBalance = sequencerFeeVaultBalance + baseFeeVaultBalance + l1FeeVaultBalance;
        uint256 expectedOptimismWalletBalance =
            totalFeeVaultBalance * optimismGrossRevenueShareBasisPoints / BASIS_POINTS_SCALE;
        uint256 expectedBridgeWithdrawalBalance = totalFeeVaultBalance - expectedOptimismWalletBalance;

        vm.mockCall(
            Predeploys.L2_STANDARD_BRIDGE,
            abi.encodeWithSignature("bridgeETHTo(address,uint256,bytes)", l1Wallet, WITHDRAWAL_MIN_GAS, NULL_BYTES),
            NULL_BYTES
        );

        vm.expectEmit(true, true, true, true, address(feeDisburser));
        emit FeesDisbursed(block.timestamp, expectedOptimismWalletBalance, totalFeeVaultBalance);
        feeDisburser.disburseFees();

        assertEq(feeDisburser.lastDisbursementTime(), block.timestamp);
        assertEq(feeDisburser.netFeeRevenue(), ZERO_VALUE);
        assertEq(feeDisburser.OPTIMISM_WALLET().balance, expectedOptimismWalletBalance);
        assertEq(Predeploys.L2_STANDARD_BRIDGE.balance, expectedBridgeWithdrawalBalance);
    }

    function test_fuzz_success_disburseFees(
        uint256 sequencerFeeVaultBalance,
        uint256 baseFeeVaultBalance,
        uint256 l1FeeVaultBalance
    ) external {
        vm.assume(sequencerFeeVaultBalance < 10 ** 36);
        vm.assume(baseFeeVaultBalance < 10 ** 36);
        vm.assume(l1FeeVaultBalance < 10 ** 36);

        vm.deal(Predeploys.SEQUENCER_FEE_WALLET, sequencerFeeVaultBalance);
        vm.deal(Predeploys.BASE_FEE_VAULT, baseFeeVaultBalance);
        vm.deal(Predeploys.L1_FEE_VAULT, l1FeeVaultBalance);

        uint256 netFeeVaultBalance = sequencerFeeVaultBalance >= minimumWithdrawalAmount ? sequencerFeeVaultBalance : 0;
        netFeeVaultBalance += baseFeeVaultBalance >= minimumWithdrawalAmount ? baseFeeVaultBalance : 0;
        uint256 totalFeeVaultBalance =
            netFeeVaultBalance + (l1FeeVaultBalance >= minimumWithdrawalAmount ? l1FeeVaultBalance : 0);

        uint256 optimismNetRevenue = netFeeVaultBalance * optimismNetRevenueShareBasisPoints / BASIS_POINTS_SCALE;
        uint256 optimismGrossRevenue = totalFeeVaultBalance * optimismGrossRevenueShareBasisPoints / BASIS_POINTS_SCALE;
        uint256 expectedOptimismWalletBalance = Math.max(optimismNetRevenue, optimismGrossRevenue);

        uint256 expectedBridgeWithdrawalBalance = totalFeeVaultBalance - expectedOptimismWalletBalance;

        vm.mockCall(
            Predeploys.L2_STANDARD_BRIDGE,
            abi.encodeWithSignature("bridgeETHTo(address,uint256,bytes)", l1Wallet, WITHDRAWAL_MIN_GAS, NULL_BYTES),
            NULL_BYTES
        );

        vm.expectEmit(true, true, true, true, address(feeDisburser));
        if (totalFeeVaultBalance == 0) {
            emit NoFeesCollected();
        } else {
            emit FeesDisbursed(block.timestamp, expectedOptimismWalletBalance, totalFeeVaultBalance);
        }

        feeDisburser.disburseFees();

        assertEq(feeDisburser.netFeeRevenue(), ZERO_VALUE);
        assertEq(feeDisburser.OPTIMISM_WALLET().balance, expectedOptimismWalletBalance);
        assertEq(Predeploys.L2_STANDARD_BRIDGE.balance, expectedBridgeWithdrawalBalance);
    }

    function test_receive_fail_unauthorizedCaller() external {
        vm.expectRevert("FeeDisburser: Only FeeVaults can send ETH to FeeDisburser");
        vm.prank(alice);
        (bool success,) = payable(address(feeDisburser)).call{value: NON_ZERO_VALUE}("");
        assertTrue(success);
    }

    function test_receive_success() external {
        vm.deal(Predeploys.SEQUENCER_FEE_WALLET, NON_ZERO_VALUE);

        vm.prank(Predeploys.SEQUENCER_FEE_WALLET);
        Address.sendValue(payable(address(feeDisburser)), NON_ZERO_VALUE);

        assertEq(feeDisburser.netFeeRevenue(), NON_ZERO_VALUE);
        assertEq(address(feeDisburser).balance, NON_ZERO_VALUE);
    }

    function test_receive_success_fromMultipleFeeVaults() external {
        vm.deal(Predeploys.SEQUENCER_FEE_WALLET, NON_ZERO_VALUE);
        vm.deal(Predeploys.BASE_FEE_VAULT, NON_ZERO_VALUE);
        vm.deal(Predeploys.L1_FEE_VAULT, NON_ZERO_VALUE);
        uint256 expectedNetFeeRevenue = NON_ZERO_VALUE * 2;
        uint256 expectedTotalValue = NON_ZERO_VALUE * 3;

        vm.prank(Predeploys.SEQUENCER_FEE_WALLET);
        Address.sendValue(payable(address(feeDisburser)), NON_ZERO_VALUE);

        vm.prank(Predeploys.BASE_FEE_VAULT);
        Address.sendValue(payable(address(feeDisburser)), NON_ZERO_VALUE);

        assertEq(feeDisburser.netFeeRevenue(), expectedNetFeeRevenue);
        assertEq(address(feeDisburser).balance, expectedNetFeeRevenue);

        vm.prank(Predeploys.L1_FEE_VAULT);
        Address.sendValue(payable(address(feeDisburser)), NON_ZERO_VALUE);

        assertEq(feeDisburser.netFeeRevenue(), expectedNetFeeRevenue);
        assertEq(address(feeDisburser).balance, expectedTotalValue);
    }
}
