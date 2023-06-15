// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "forge-std/console.sol";
import "forge-std/Script.sol";

import {ERC20PresetMinterPauser} from "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import {ERC721PresetMinterPauserAutoId} from "@openzeppelin/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";

import {L1StandardBridge} from "@eth-optimism-bedrock/contracts/L1/L1StandardBridge.sol";
import {L1ERC721Bridge} from "@eth-optimism-bedrock/contracts/L1/L1ERC721Bridge.sol";

// Deposits funds to Base Mainnet to test its functionality
contract DeployTestContracts is Script {
    function run(
        address _tester,
        address _l1erc721Bridge,
        address _l1erc721,
        address _l2erc721
    ) public {
        vm.startBroadcast(_tester);
        ERC721PresetMinterPauserAutoId(_l1erc721).approve(_l1erc721Bridge, 0);

        console.log("L1StandardBridge erc20 deposit complete");

        L1ERC721Bridge(_l1erc721Bridge).bridgeERC721(
            _l1erc721,
            _l2erc721,
            0,
            200_000,
            bytes("")
        );

        console.log("L1ERC721Bridge erc721 deposit complete");
    }
}
