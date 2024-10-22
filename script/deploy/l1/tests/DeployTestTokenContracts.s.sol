// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "forge-std/console.sol";
import "forge-std/Script.sol";

import {ERC20PresetMinterPauser} from "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import {ERC721PresetMinterPauserAutoId} from
    "@openzeppelin/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";

// Deploys test token contracts on L1 to test Base Mainnet's bridging functionality
contract DeployTestTokenContracts is Script {
    function run(address _tester) public {
        vm.startBroadcast(_tester);
        ERC20PresetMinterPauser erc20 = new ERC20PresetMinterPauser("L1 TEST ERC20", "L1T20");
        console.log("TEST ERC20 deployed to: %s", address(erc20));

        ERC721PresetMinterPauserAutoId erc721 =
            new ERC721PresetMinterPauserAutoId("L1 TEST ERC721", "L1T721", "not applicable");
        console.log("TEST ERC721 deployed to: %s", address(erc721));

        erc20.mint(_tester, 1_000_000 ether);
        erc721.mint(_tester);
        console.log("Minting to tester complete");

        vm.stopBroadcast();
    }
}
