// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "forge-std/console.sol";
import "forge-std/Script.sol";

import {Predeploys} from "@eth-optimism-bedrock/src/libraries/Predeploys.sol";
import {L2StandardBridge} from "@eth-optimism-bedrock/src/L2/L2StandardBridge.sol";
import {L2ERC721Bridge} from "@eth-optimism-bedrock/src/L2/L2ERC721Bridge.sol";

// Withdraws tokens from L2 to L1 to test Base Mainnet's bridging functionality
contract TestWithdraw is Script {
    function run(
        address _tester,
        address _l2erc20,
        address _l1erc721,
        address _l2erc721
    ) public {
        vm.startBroadcast(_tester);
        L2StandardBridge(payable(Predeploys.L2_STANDARD_BRIDGE)).withdraw(
            _l2erc20,
            10_000 ether,
            200_000,
            bytes("")
        );
        console.log("erc20 withdrawal initiated");

        L2ERC721Bridge(payable(Predeploys.L2_ERC721_BRIDGE)).bridgeERC721(
            _l2erc721,
            _l1erc721,
            0,
            200_000,
            bytes("")
        );
        console.log("erc721 withdrawal initiated");

        vm.stopBroadcast();
    }
}
