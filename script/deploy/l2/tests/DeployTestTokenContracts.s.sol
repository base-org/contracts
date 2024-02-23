// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "forge-std/console.sol";
import "forge-std/Script.sol";

import {Predeploys} from "@eth-optimism-bedrock/contracts/libraries/Predeploys.sol";
import {OptimismMintableERC20Factory} from "@eth-optimism-bedrock/contracts/universal/OptimismMintableERC20Factory.sol";
import {OptimismMintableERC721Factory} from "@eth-optimism-bedrock/contracts/universal/OptimismMintableERC721Factory.sol";

// Deploys test token contracts on L2 to test Base Mainnet functionality
contract DeployTestTokenContracts is Script {
    function run(
        address _tester,
        address _l1erc20,
        address _l1erc721
    ) public {
        vm.startBroadcast(_tester);
        address erc20 = OptimismMintableERC20Factory(Predeploys.OPTIMISM_MINTABLE_ERC20_FACTORY).createOptimismMintableERC20(
            _l1erc20,
            "L2 TEST ERC20",
            "L2T20"
        );
        console.log("Bridged erc20 deployed to: %s", address(erc20));

        address erc721 = OptimismMintableERC721Factory(payable(Predeploys.OPTIMISM_MINTABLE_ERC721_FACTORY)).createOptimismMintableERC721(
            _l1erc721,
            "L2 TEST ERC721",
            "L1T721"
        );
        console.log("Bridged erc721 deployed to: %s", address(erc721));

        vm.stopBroadcast();
    }
}
