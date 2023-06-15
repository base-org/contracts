// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "forge-std/Script.sol";

import "@eth-optimism-bedrock/contracts/universal/ProxyAdmin.sol";
import "@eth-optimism-bedrock/contracts/legacy/AddressManager.sol";
import "@eth-optimism-bedrock/contracts/L1/L1CrossDomainMessenger.sol";
import "@eth-optimism-bedrock/contracts/L1/L1StandardBridge.sol";
import "@eth-optimism-bedrock/contracts/L1/L2OutputOracle.sol";
import "@eth-optimism-bedrock/contracts/L1/OptimismPortal.sol";
import "@eth-optimism-bedrock/contracts/universal/OptimismMintableERC20Factory.sol";
import "@eth-optimism-bedrock/contracts/L1/L1ERC721Bridge.sol";
import "@eth-optimism-bedrock/contracts/L1/SystemConfig.sol";

import "script/deploy/Utils.sol";

contract CheckBedrockDeploy is Script {
    Utils.AddressesConfig addresses;

    function setup() public {
        Utils utils = new Utils();
        addresses = utils.readAddressesFile();
    }

    function run() public {
        AddressManager addressManager = AddressManager(payable(addresses.AddressManager));
        L1CrossDomainMessenger l1CrossDomainMessenger = L1CrossDomainMessenger(payable(addresses.L1CrossDomainMessengerProxy));
        L1ERC721Bridge l1ERC721Bridge = L1ERC721Bridge(payable(addresses.L1ERC721BridgeProxy));
        L1StandardBridge l1StandardBridge = L1StandardBridge(payable(addresses.L1StandardBridgeProxy));
        L2OutputOracle l2OutputOracle = L2OutputOracle(payable(addresses.L2OutputOracleProxy));
        OptimismMintableERC20Factory optimismMintableERC20Factory = OptimismMintableERC20Factory(payable(addresses.OptimismMintableERC20FactoryProxy));
        OptimismPortal optimismPortal = OptimismPortal(payable(addresses.OptimismPortalProxy));
        ProxyAdmin proxyAdmin = ProxyAdmin(payable(addresses.ProxyAdmin));
        SystemConfig systemConfig = SystemConfig(payable(addresses.SystemConfigProxy));

        // Check contract versions
        versionMatch(l1CrossDomainMessenger.version(), "1.4.0");
        versionMatch(l1CrossDomainMessenger.version(), "1.4.0");
        versionMatch(l1ERC721Bridge.version(), "1.1.1");
        versionMatch(l1StandardBridge.version(), "1.1.0");
        versionMatch(l2OutputOracle.version(), "1.3.0");
        versionMatch(optimismMintableERC20Factory.version(), "1.1.0");
        versionMatch(optimismPortal.version(), "1.7.0");
        versionMatch(systemConfig.version(), "1.3.0");

        // Check critical variables
        require(l1CrossDomainMessenger.PORTAL() == optimismPortal);
        require(proxyAdmin.owner() == 0x9855054731540A48b28990B63DcF4f33d8AE46A1);
        require(optimismPortal.GUARDIAN() == 0x14536667Cd30e52C0b458BaACcB9faDA7046E056);
        require(l2OutputOracle.CHALLENGER() == 0x14536667Cd30e52C0b458BaACcB9faDA7046E056);
        require(systemConfig.owner() == 0x9855054731540A48b28990B63DcF4f33d8AE46A1);

    }

    function versionMatch(string memory _actualVersion, string memory _expectedVersion) internal {
        require(keccak256(abi.encode(_actualVersion)) == keccak256(abi.encode(_expectedVersion)));
    }
}

