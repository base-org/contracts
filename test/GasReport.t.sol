// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "../src/Challenger1of2.sol";
import "../src/revenue-share/BalanceTracker.sol";
import {FeeVault as CustomFeeVault} from "../src/fee-vault-fixes/FeeVault.sol";
import {Proxy} from "@eth-optimism-bedrock/src/universal/Proxy.sol";

contract GasReportTest is Test {
    Challenger1of2 challenger;
    BalanceTracker balanceTracker;
    CustomFeeVault feeVault;
    address opSigner;
    address otherSigner;
    address proxyAdmin;

    // Proxy-related variables
    Proxy balanceTrackerProxy;
    BalanceTracker balanceTrackerImplementation;

    function setUp() public {
        opSigner = makeAddr("opSigner");
        otherSigner = makeAddr("otherSigner");
        proxyAdmin = makeAddr("proxyAdmin");

        // Setup Challenger
        challenger = new Challenger1of2(
            opSigner,
            otherSigner,
            address(new MockL2OutputOracle())
        );

        // Setup BalanceTracker
        address payable profitWallet = payable(makeAddr("profitWallet"));
        balanceTrackerImplementation = new BalanceTracker(profitWallet);
        balanceTrackerProxy = new Proxy(proxyAdmin);
        vm.prank(proxyAdmin);
        balanceTrackerProxy.upgradeTo(address(balanceTrackerImplementation));
        balanceTracker = BalanceTracker(payable(address(balanceTrackerProxy)));

        // Initialize BalanceTracker
        address payable[] memory systemAddresses = new address payable[](2);
        systemAddresses[0] = payable(makeAddr("system1"));
        systemAddresses[1] = payable(makeAddr("system2"));
        uint256[] memory targetBalances = new uint256[](2);
        targetBalances[0] = 1 ether;
        targetBalances[1] = 2 ether;
        balanceTracker.initialize(systemAddresses, targetBalances);

        feeVault = new CustomFeeVault();
    }

    /// @notice Gas report for challenge execution
    function test_challenger_execute() public {
        bytes memory message = abi.encodeWithSelector(
            MockL2OutputOracle.deleteL2Outputs.selector,
            0
        );
        vm.prank(opSigner);
        challenger.execute(message);
    }

    /// @notice Gas report for processing fees in BalanceTracker
    function test_balanceTracker_processFees() public {
        vm.deal(address(balanceTracker), 10 ether);
        balanceTracker.processFees();
    }

    /// @notice Gas report for setting total processed in FeeVault
    function test_feeVault_setTotalProcessed() public {
        feeVault.setTotalProcessed(1 ether);
    }

    receive() external payable {}
}

contract MockL2OutputOracle {
    function deleteL2Outputs(uint256) external pure returns (bool) {
        return true;
    }
}
