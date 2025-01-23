// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

// solhint-disable no-console
import {console} from "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";

import {ERC20PresetMinterPauser} from "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import {ERC721PresetMinterPauserAutoId} from
    "@openzeppelin/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";

import {L1StandardBridge} from "@eth-optimism-bedrock/src/L1/L1StandardBridge.sol";
import {L1ERC721Bridge} from "@eth-optimism-bedrock/src/L1/L1ERC721Bridge.sol";

// Deposits funds to Base Mainnet to test its functionality
contract DeployTestContracts is Script {
    function run(
        address _tester,
        address payable _l1StandardBridge,
        address _l1erc721Bridge,
        address payable _l1erc20,
        address _l1erc721,
        address _l2erc20,
        address _l2erc721
    ) public {
        vm.startBroadcast(_tester);
        ERC20PresetMinterPauser(_l1erc20).approve(_l1StandardBridge, 1_000_000 ether);
        ERC721PresetMinterPauserAutoId(_l1erc721).approve(_l1erc721Bridge, 0);

        console.log("Approvals to bridge contracts complete");

        L1StandardBridge(_l1StandardBridge).depositERC20(_l1erc20, _l2erc20, 1_000_000 ether, 200_000, bytes(""));

        console.log("L1StandardBridge erc20 deposit complete");

        L1ERC721Bridge(_l1erc721Bridge).bridgeERC721(_l1erc721, _l2erc721, 0, 200_000, bytes(""));

        console.log("L1ERC721Bridge erc721 deposit complete");
    }
}
