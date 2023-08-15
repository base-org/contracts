// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { CommonTest } from "test/CommonTest.t.sol";
import { ReenterProcessFees } from "test/revenue-share/mocks/ReenterProcessFees.sol";

import { Proxy } from "@eth-optimism-bedrock/contracts/universal/Proxy.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import { BalanceTracker } from "src/revenue-share/BalanceTracker.sol";

contract BalanceTrackerTest is CommonTest {
    event ProcessedFunds(address indexed _systemAddress, bool indexed _success, uint256 _balanceNeeded, uint256 _balanceSent);
    event SentProfit(address indexed _profitWallet, bool indexed _success, uint256 _balanceSent);
    event ReceivedFunds(address indexed _sender, uint256 _amount);

    uint256 constant MAX_SYSTEM_ADDRESS_COUNT = 20;
    uint256 constant INITIAL_BALANCE_TRACKER_BALANCE = 2_000 ether;

    Proxy balanceTrackerProxy;
    BalanceTracker balanceTrackerImplementation;
    BalanceTracker balanceTracker;
    
    address payable l1StandardBridge = payable(address(1000));
    address payable profitWallet = payable(address(1001));
    address payable batchSender = payable(address(1002));
    address payable l2OutputProposer = payable(address(1003));
    uint256 batchSenderTargetBalance = 1_000 ether;
    uint256 l2OutputProposerTargetBalance = 100 ether;
    address payable[] systemAddresses = [batchSender, l2OutputProposer];
    uint256[] targetBalances = [batchSenderTargetBalance, l2OutputProposerTargetBalance];
    address proxyAdminOwner = address(2048);
    
    function setUp() public override {
        super.setUp();

        balanceTrackerImplementation = new BalanceTracker(
            profitWallet
        );
        balanceTrackerProxy = new Proxy(proxyAdminOwner);
        vm.prank(proxyAdminOwner);
        balanceTrackerProxy.upgradeTo(address(balanceTrackerImplementation));
        balanceTracker = BalanceTracker(payable(address(balanceTrackerProxy)));
    }

    function test_constructor_fail_profitWallet_zeroAddress() external {
        vm.expectRevert(
            "BalanceTracker: PROFIT_WALLET cannot be address(0)"
        );
        new BalanceTracker(
            payable(ZERO_ADDRESS)
        );
    }


    function test_constructor_success() external {
        balanceTracker = new BalanceTracker(
            profitWallet
        );

        assertEq(balanceTracker.MAX_SYSTEM_ADDRESS_COUNT(), MAX_SYSTEM_ADDRESS_COUNT);
        assertEq(balanceTracker.PROFIT_WALLET(), profitWallet);
    }

    function test_initializer_fail_systemAddresses_zeroLength() external {
        delete systemAddresses;
        vm.expectRevert(
            "BalanceTracker: systemAddresses cannot have a length of zero"
        );
        balanceTracker.initialize(
            systemAddresses,
            targetBalances
        );
    }

    function test_initializer_fail_systemAddresses_greaterThanMaxLength() external {
        for (;systemAddresses.length <= balanceTracker.MAX_SYSTEM_ADDRESS_COUNT();) systemAddresses.push(payable(address(0)));
        
        vm.expectRevert(
            "BalanceTracker: systemAddresses cannot have a length greater than 20"
        );
        balanceTracker.initialize(
            systemAddresses,
            targetBalances
        );
    }
    
    function test_initializer_fail_systemAddresses_lengthNotEqualToTargetBalancesLength() external {
        systemAddresses.push(payable(address(0)));
        
        vm.expectRevert(
            "BalanceTracker: systemAddresses and targetBalances length must be equal"
        );
        balanceTracker.initialize(
            systemAddresses,
            targetBalances
        );
    }

    function test_initializer_fail_systemAddresses_containsZeroAddress() external {
        systemAddresses[1] = payable(address(0));
        
        vm.expectRevert(
            "BalanceTracker: systemAddresses cannot contain address(0)"
        );
        balanceTracker.initialize(
            systemAddresses,
            targetBalances
        );
    }

    function test_initializer_fail_targetBalances_containsZero() external {
        targetBalances[1] = ZERO_VALUE;
        
        vm.expectRevert(
            "BalanceTracker: targetBalances cannot contain 0 target"
        );
        balanceTracker.initialize(
            systemAddresses,
            targetBalances
        );
    }

    function test_initializer_success() external {
        balanceTracker.initialize(
            systemAddresses,
            targetBalances
        );

        assertEq(balanceTracker.systemAddresses(0), systemAddresses[0]);
        assertEq(balanceTracker.systemAddresses(1), systemAddresses[1]);
        assertEq(balanceTracker.targetBalances(0), targetBalances[0]);
        assertEq(balanceTracker.targetBalances(1), targetBalances[1]);
    }

    function test_processFees_success_cannotBeReentered() external {
        vm.deal(address(balanceTracker), INITIAL_BALANCE_TRACKER_BALANCE);
        uint256 expectedProfitWalletBalance = INITIAL_BALANCE_TRACKER_BALANCE - l2OutputProposerTargetBalance;
        address payable reentrancySystemAddress = payable(address(new ReenterProcessFees()));
        systemAddresses[0] = reentrancySystemAddress;
        balanceTracker.initialize(
            systemAddresses,
            targetBalances
        );

        vm.expectEmit(true, true, true, true, address(balanceTracker));
        emit ProcessedFunds(reentrancySystemAddress, false, batchSenderTargetBalance, batchSenderTargetBalance);
        vm.expectEmit(true, true, true, true, address(balanceTracker));
        emit ProcessedFunds(l2OutputProposer, true, l2OutputProposerTargetBalance, l2OutputProposerTargetBalance);
        vm.expectEmit(true, true, true, true, address(balanceTracker));
        emit SentProfit(profitWallet, true, expectedProfitWalletBalance);
        
        balanceTracker.processFees();

        assertEq(address(balanceTracker).balance, ZERO_VALUE);
        assertEq(profitWallet.balance, expectedProfitWalletBalance);
        assertEq(batchSender.balance, ZERO_VALUE);
        assertEq(l2OutputProposer.balance, l2OutputProposerTargetBalance);
    }

    function test_processFees_fail_whenNotInitialized() external {
        vm.expectRevert(
            "BalanceTracker: systemAddresses cannot have a length of zero"
        );
        
        balanceTracker.processFees();
    }

    function test_processFees_success_continuesWhenSystemAddressReverts() external {
        vm.deal(address(balanceTracker), INITIAL_BALANCE_TRACKER_BALANCE);
        uint256 expectedProfitWalletBalance = INITIAL_BALANCE_TRACKER_BALANCE - l2OutputProposerTargetBalance;
        balanceTracker.initialize(
            systemAddresses,
            targetBalances
        );
        vm.mockCallRevert(
            batchSender,
            bytes(""),
            abi.encode("revert message")
        );
        vm.expectEmit(true, true, true, true, address(balanceTracker));
        emit ProcessedFunds(batchSender, false, batchSenderTargetBalance, batchSenderTargetBalance);
        vm.expectEmit(true, true, true, true, address(balanceTracker));
        emit ProcessedFunds(l2OutputProposer, true, l2OutputProposerTargetBalance, l2OutputProposerTargetBalance);
        vm.expectEmit(true, true, true, true, address(balanceTracker));
        emit SentProfit(profitWallet, true, expectedProfitWalletBalance);

        balanceTracker.processFees();

        assertEq(address(balanceTracker).balance, ZERO_VALUE);
        assertEq(profitWallet.balance, expectedProfitWalletBalance);
        assertEq(batchSender.balance, ZERO_VALUE);
        assertEq(l2OutputProposer.balance, l2OutputProposerTargetBalance);
    }

    function test_processFees_success_fundsSystemAddresses() external {
        vm.deal(address(balanceTracker), INITIAL_BALANCE_TRACKER_BALANCE);
        uint256 expectedProfitWalletBalance = INITIAL_BALANCE_TRACKER_BALANCE - batchSenderTargetBalance - l2OutputProposerTargetBalance;
        balanceTracker.initialize(
            systemAddresses,
            targetBalances
        );
        vm.expectEmit(true, true, true, true, address(balanceTracker));
        emit ProcessedFunds(batchSender, true, batchSenderTargetBalance, batchSenderTargetBalance);
        vm.expectEmit(true, true, true, true, address(balanceTracker));
        emit ProcessedFunds(l2OutputProposer, true, l2OutputProposerTargetBalance, l2OutputProposerTargetBalance);
        vm.expectEmit(true, true, true, true, address(balanceTracker));
        emit SentProfit(profitWallet, true, expectedProfitWalletBalance);

        balanceTracker.processFees();

        assertEq(address(balanceTracker).balance, ZERO_VALUE);
        assertEq(profitWallet.balance, expectedProfitWalletBalance);
        assertEq(batchSender.balance, batchSenderTargetBalance);
        assertEq(l2OutputProposer.balance, l2OutputProposerTargetBalance);
    }

    function test_processFees_success_noFunds() external {
        balanceTracker.initialize(
            systemAddresses,
            targetBalances
        );
        vm.expectEmit(true, true, true, true, address(balanceTracker));
        emit ProcessedFunds(batchSender, true, batchSenderTargetBalance, ZERO_VALUE);
        vm.expectEmit(true, true, true, true, address(balanceTracker));
        emit ProcessedFunds(l2OutputProposer, true, l2OutputProposerTargetBalance, ZERO_VALUE);
        vm.expectEmit(true, true, true, true, address(balanceTracker));
        emit SentProfit(profitWallet, true, ZERO_VALUE);

        balanceTracker.processFees();

        assertEq(address(balanceTracker).balance, ZERO_VALUE);
        assertEq(profitWallet.balance, ZERO_VALUE);
        assertEq(batchSender.balance, ZERO_VALUE);
        assertEq(l2OutputProposer.balance, ZERO_VALUE);
    }

    function test_processFees_success_partialFunds() external {
        uint256 partialBalanceTrackerBalance = INITIAL_BALANCE_TRACKER_BALANCE/3;
        vm.deal(address(balanceTracker), partialBalanceTrackerBalance);
        balanceTracker.initialize(
            systemAddresses,
            targetBalances
        );
        vm.expectEmit(true, true, true, true, address(balanceTracker));
        emit ProcessedFunds(batchSender, true, batchSenderTargetBalance, partialBalanceTrackerBalance);
        vm.expectEmit(true, true, true, true, address(balanceTracker));
        emit ProcessedFunds(l2OutputProposer, true, l2OutputProposerTargetBalance, ZERO_VALUE);
        vm.expectEmit(true, true, true, true, address(balanceTracker));
        emit SentProfit(profitWallet, true, ZERO_VALUE);

        balanceTracker.processFees();

        assertEq(address(balanceTracker).balance, ZERO_VALUE);
        assertEq(profitWallet.balance, ZERO_VALUE);
        assertEq(batchSender.balance, partialBalanceTrackerBalance);
        assertEq(l2OutputProposer.balance, ZERO_VALUE);
    }

    function test_processFees_success_skipsAddressesAtTargetBalance() external {
        vm.deal(address(balanceTracker), INITIAL_BALANCE_TRACKER_BALANCE);
        vm.deal(batchSender, batchSenderTargetBalance);
        vm.deal(l2OutputProposer, l2OutputProposerTargetBalance);
        balanceTracker.initialize(
            systemAddresses,
            targetBalances
        );
        vm.expectEmit(true, true, true, true, address(balanceTracker));
        emit ProcessedFunds(batchSender, false, ZERO_VALUE, ZERO_VALUE);
        vm.expectEmit(true, true, true, true, address(balanceTracker));
        emit ProcessedFunds(l2OutputProposer, false, ZERO_VALUE, ZERO_VALUE);
        vm.expectEmit(true, true, true, true, address(balanceTracker));
        emit SentProfit(profitWallet, true, INITIAL_BALANCE_TRACKER_BALANCE);

        balanceTracker.processFees();
        
        assertEq(address(balanceTracker).balance, ZERO_VALUE);
        assertEq(profitWallet.balance, INITIAL_BALANCE_TRACKER_BALANCE);
        assertEq(batchSender.balance, batchSenderTargetBalance);
        assertEq(l2OutputProposer.balance, l2OutputProposerTargetBalance);
    }

    function test_processFees_success_maximumSystemAddresses() external {
        vm.deal(address(balanceTracker), INITIAL_BALANCE_TRACKER_BALANCE);
        delete systemAddresses;
        delete targetBalances;
        for (uint256 i = 0; i < balanceTracker.MAX_SYSTEM_ADDRESS_COUNT(); i++) {
            systemAddresses.push(payable(address(uint160(i+100))));
            targetBalances.push(l2OutputProposerTargetBalance);
        }
        balanceTracker.initialize(
            systemAddresses,
            targetBalances
        );
    
        balanceTracker.processFees();

        assertEq(address(balanceTracker).balance, ZERO_VALUE);
        for (uint256 i = 0; i < balanceTracker.MAX_SYSTEM_ADDRESS_COUNT(); i++) {
            assertEq(systemAddresses[i].balance, l2OutputProposerTargetBalance);
        }
        assertEq(profitWallet.balance, ZERO_VALUE);   
    }

    function test_receive_success() external {
        vm.deal(l1StandardBridge, NON_ZERO_VALUE);
        
        vm.prank(l1StandardBridge);
        vm.expectEmit(true, true, true, true, address(balanceTracker));
        emit ReceivedFunds(l1StandardBridge, NON_ZERO_VALUE);

        payable(address(balanceTracker)).call{ value: NON_ZERO_VALUE }("");

        assertEq(address(balanceTracker).balance, NON_ZERO_VALUE);
    }
}
