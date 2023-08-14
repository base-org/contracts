// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { CommonTest } from "test/CommonTest.t.sol";
import { Predeploys } from "@eth-optimism-bedrock/contracts/libraries/Predeploys.sol";
import { Proxy } from "@eth-optimism-bedrock/contracts/universal/Proxy.sol";
import { FeeVault as FeeVault_Final } from "@eth-optimism-bedrock/contracts/universal/FeeVault.sol";
import { L1FeeVault as L1FeeVault_Final } from "@eth-optimism-bedrock/contracts/L2/L1FeeVault.sol";
import { FeeVault as FeeVault_Fix } from "src/fee-vault-fixes/FeeVault.sol";

contract L1FeeVaultTest is CommonTest {
   uint256 constant BASE_MAINNET_BLOCK = 2116000;

   string BASE_MAINNET_URL = vm.envString("BASE_MAINNET_URL");
   address recipient;
   FeeVault_Final.WithdrawalNetwork withdrawalNetwork;
   uint256 minimumWithdrawalAmount;
   FeeVault_Fix l1FeeVaultFix;
   L1FeeVault_Final l1FeeVaultFinal;
   
    function setUp() public virtual override {
        super.setUp();
        vm.createSelectFork(BASE_MAINNET_URL, BASE_MAINNET_BLOCK);
    
        recipient = L1FeeVault_Final(payable(Predeploys.SEQUENCER_FEE_WALLET)).RECIPIENT();
        minimumWithdrawalAmount = L1FeeVault_Final(payable(Predeploys.SEQUENCER_FEE_WALLET)).MIN_WITHDRAWAL_AMOUNT();
        withdrawalNetwork = L1FeeVault_Final(payable(Predeploys.SEQUENCER_FEE_WALLET)).WITHDRAWAL_NETWORK();

        l1FeeVaultFix = new FeeVault_Fix();
        l1FeeVaultFinal = new L1FeeVault_Final(recipient, minimumWithdrawalAmount, withdrawalNetwork);
    }

    function test_upgradeToFixImplementationThenFinalImplementation_succeeds() public {
        bytes memory setTotalProcessedCall = abi.encodeCall(
            FeeVault_Fix.setTotalProcessed,
            ZERO_VALUE
        );

        assertNotEq(L1FeeVault_Final(payable(Predeploys.L1_FEE_VAULT)).totalProcessed(), ZERO_VALUE);
        vm.prank(Predeploys.PROXY_ADMIN);
        Proxy(payable(Predeploys.L1_FEE_VAULT)).upgradeToAndCall(address(l1FeeVaultFix), setTotalProcessedCall);
        assertEq(FeeVault_Fix(payable(Predeploys.L1_FEE_VAULT)).totalProcessed(), ZERO_VALUE);

        vm.prank(Predeploys.PROXY_ADMIN);
        Proxy(payable(Predeploys.L1_FEE_VAULT)).upgradeTo(address(l1FeeVaultFinal));        
        assertEq(L1FeeVault_Final(payable(Predeploys.L1_FEE_VAULT)).totalProcessed(), ZERO_VALUE);
    }
}