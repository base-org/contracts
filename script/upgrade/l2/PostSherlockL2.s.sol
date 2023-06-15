// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { console } from "forge-std/console.sol";
import { IGnosisSafe, Enum } from "@eth-optimism-bedrock/scripts/interfaces/IGnosisSafe.sol";
import { IMulticall3 } from "forge-std/interfaces/IMulticall3.sol";
import { Predeploys } from "@eth-optimism-bedrock/contracts/libraries/Predeploys.sol";
import { ProxyAdmin } from "@eth-optimism-bedrock/contracts/universal/ProxyAdmin.sol";
import { OptimismPortal } from "@eth-optimism-bedrock/contracts/L1/OptimismPortal.sol";
import "script/deploy/Utils.sol";
import { SafeBuilder } from "script/SafeBuilder.sol";

/**
 * @title PostSherlockL2
 * @notice Upgrades the L2 contracts.
 */
contract PostSherlockL2 is SafeBuilder {
    uint256 immutable CHAIN_ID;

    /**
     * @notice Represents a set of L2 predepploy contracts. Used to represent a set of
     *         implementations and also a set of proxies.
     */
    struct ContractSet {
        address BaseFeeVault;
        address GasPriceOracle;
        address L1Block;
        address L1FeeVault;
        address L2CrossDomainMessenger;
        address L2ERC721Bridge;
        address L2StandardBridge;
        address L2ToL1MessagePasser;
        address OptimismMintableERC20Factory;
        address OptimismMintableERC721Factory;
        address SequencerFeeVault;
    }

    /**
     * @notice A mapping of chainid to a ContractSet of implementations.
     */
    mapping(uint256 => ContractSet) internal implementations;

    /**
     * @notice A mapping of chainid to ContractSet of proxy addresses.
     */
    mapping(uint256 => ContractSet) internal proxies;

    /**
     * @notice The expected versions for the contracts to be upgraded to.
     */
    string constant internal BaseFeeVault_Version = "1.2.0";
    string constant internal GasPriceOracle_Version = "1.0.0";
    string constant internal L1Block_Version = "1.0.0";
    string constant internal L1FeeVault_Version = "1.2.0";
    string constant internal L2CrossDomainMessenger_Version = "1.4.0";
    string constant internal L2ERC721Bridge_Version = "1.1.0";
    string constant internal L2StandardBridge_Version = "1.1.0";
    string constant internal L2ToL1MessagePasser_Version = "1.0.0";
    string constant internal SequencerFeeVault_Version = "1.2.0";
    string constant internal OptimismMintableERC20Factory_Version = "1.1.0";
    string constant internal OptimismMintableERC721Factory_Version = "1.2.0";

    constructor(uint256 _l2ChainId) {
        CHAIN_ID = _l2ChainId;
    }

    /**
     * @notice Place the contract addresses in storage so they can be used when building calldata.
     */
    function setUp() external {
        Utils addressUtils = new Utils();
        Utils.AddressesL2ImplementationsConfig memory addressL2Cfg = addressUtils.readImplAddressesL2File();

        implementations[CHAIN_ID] = ContractSet({
            BaseFeeVault: addressL2Cfg.BaseFeeVault,
            GasPriceOracle: addressL2Cfg.GasPriceOracle,
            L1Block: addressL2Cfg.L1Block,
            L1FeeVault: addressL2Cfg.L1FeeVault,
            L2CrossDomainMessenger: addressL2Cfg.L2CrossDomainMessenger,
            L2ERC721Bridge: addressL2Cfg.L2ERC721Bridge,
            L2StandardBridge: addressL2Cfg.L2StandardBridge,
            L2ToL1MessagePasser: addressL2Cfg.L2ToL1MessagePasser,
            OptimismMintableERC20Factory: addressL2Cfg.OptimismMintableERC20Factory,
            OptimismMintableERC721Factory: addressL2Cfg.OptimismMintableERC721Factory,
            SequencerFeeVault: addressL2Cfg.SequencerFeeVault
        });

        proxies[CHAIN_ID] = ContractSet({
            BaseFeeVault: Predeploys.BASE_FEE_VAULT,
            GasPriceOracle: Predeploys.GAS_PRICE_ORACLE,
            L1Block: Predeploys.L1_BLOCK_ATTRIBUTES,
            L1FeeVault: Predeploys.L1_FEE_VAULT,
            L2CrossDomainMessenger: Predeploys.L2_CROSS_DOMAIN_MESSENGER,
            L2ERC721Bridge: Predeploys.L2_ERC721_BRIDGE,
            L2StandardBridge: Predeploys.L2_STANDARD_BRIDGE,
            L2ToL1MessagePasser: Predeploys.L2_TO_L1_MESSAGE_PASSER,
            OptimismMintableERC20Factory: Predeploys.OPTIMISM_MINTABLE_ERC20_FACTORY,
            OptimismMintableERC721Factory: Predeploys.OPTIMISM_MINTABLE_ERC721_FACTORY,
            SequencerFeeVault: Predeploys.SEQUENCER_FEE_WALLET
        });
    }

    /**
     * @notice Follow up assertions to ensure that the script ran to completion.
     */
    function _postCheck() internal override view {
        ContractSet memory prox = getProxies();
        require(_versionHash(prox.BaseFeeVault) == keccak256(bytes(BaseFeeVault_Version)), "BaseFeeVault");
        require(_versionHash(prox.GasPriceOracle) == keccak256(bytes(GasPriceOracle_Version)), "GasPriceOracle");
        require(_versionHash(prox.L1Block) == keccak256(bytes(L1Block_Version)), "L1Block");
        require(_versionHash(prox.L1FeeVault) == keccak256(bytes(L1FeeVault_Version)), "L1FeeVault");
        require(_versionHash(prox.L2CrossDomainMessenger) == keccak256(bytes(L2CrossDomainMessenger_Version)), "L2CrossDomainMessenger");
        require(_versionHash(prox.L2ERC721Bridge) == keccak256(bytes(L2ERC721Bridge_Version)), "L2ERC721Bridge");
        require(_versionHash(prox.L2StandardBridge) == keccak256(bytes(L2StandardBridge_Version)), "L2StandardBridge");
        require(_versionHash(prox.L2ToL1MessagePasser) == keccak256(bytes(L2ToL1MessagePasser_Version)), "L2ToL1MessagePasser");
        require(_versionHash(prox.SequencerFeeVault) == keccak256(bytes(SequencerFeeVault_Version)), "SequencerFeeVault");
        require(_versionHash(prox.OptimismMintableERC20Factory) == keccak256(bytes(OptimismMintableERC20Factory_Version)), "OptimismMintableERC20Factory");
        require(_versionHash(prox.OptimismMintableERC721Factory) == keccak256(bytes(OptimismMintableERC721Factory_Version)), "OptimismMintableERC721Factory");

        // Check that the codehashes of all implementations match the proxies set implementations.
        ContractSet memory impl = getImplementations();
        ProxyAdmin proxyAdmin = ProxyAdmin(Predeploys.PROXY_ADMIN);
        require(proxyAdmin.getProxyImplementation(prox.BaseFeeVault).codehash == impl.BaseFeeVault.codehash);
        require(proxyAdmin.getProxyImplementation(prox.GasPriceOracle).codehash == impl.GasPriceOracle.codehash);
        require(proxyAdmin.getProxyImplementation(prox.L1Block).codehash == impl.L1Block.codehash);
        require(proxyAdmin.getProxyImplementation(prox.L1FeeVault).codehash == impl.L1FeeVault.codehash);
        require(proxyAdmin.getProxyImplementation(prox.L2CrossDomainMessenger).codehash == impl.L2CrossDomainMessenger.codehash);
        require(proxyAdmin.getProxyImplementation(prox.L2ERC721Bridge).codehash == impl.L2ERC721Bridge.codehash);
        require(proxyAdmin.getProxyImplementation(prox.L2StandardBridge).codehash == impl.L2StandardBridge.codehash);
        require(proxyAdmin.getProxyImplementation(prox.L2ToL1MessagePasser).codehash == impl.L2ToL1MessagePasser.codehash);
        require(proxyAdmin.getProxyImplementation(prox.SequencerFeeVault).codehash == impl.SequencerFeeVault.codehash);
        require(proxyAdmin.getProxyImplementation(prox.OptimismMintableERC20Factory).codehash == impl.OptimismMintableERC20Factory.codehash);
        require(proxyAdmin.getProxyImplementation(prox.OptimismMintableERC721Factory).codehash == impl.OptimismMintableERC721Factory.codehash);
    }

    /**
     * @notice Builds the calldata that the multisig needs to make for the upgrade to happen.
     *         A total of 9 calls are made to the proxy admin to upgrade the implementations
     *         of the predeploys.
     */
    function buildCalldata() internal override view returns (bytes memory) {
        IMulticall3.Call3[] memory calls = new IMulticall3.Call3[](11);

        ContractSet memory impl = getImplementations();
        ContractSet memory prox = getProxies();

        // Upgrade the BaseFeeVault
        calls[0] = IMulticall3.Call3({
            target: Predeploys.PROXY_ADMIN,
            allowFailure: false,
            callData: abi.encodeCall(
                ProxyAdmin.upgrade,
                (payable(prox.BaseFeeVault), impl.BaseFeeVault)
            )
        });

        // Upgrade the GasPriceOracle
        calls[1] = IMulticall3.Call3({
            target: Predeploys.PROXY_ADMIN,
            allowFailure: false,
            callData: abi.encodeCall(
                ProxyAdmin.upgrade,
                (payable(prox.GasPriceOracle), impl.GasPriceOracle)
            )
        });

        // Upgrade the L1Block predeploy
        calls[2] = IMulticall3.Call3({
            target: Predeploys.PROXY_ADMIN,
            allowFailure: false,
            callData: abi.encodeCall(
                ProxyAdmin.upgrade,
                (payable(prox.L1Block), impl.L1Block)
            )
        });

        // Upgrade the L1FeeVault
        calls[3] = IMulticall3.Call3({
            target: Predeploys.PROXY_ADMIN,
            allowFailure: false,
            callData: abi.encodeCall(
                ProxyAdmin.upgrade,
                (payable(prox.L1FeeVault), impl.L1FeeVault)
            )
        });

        // Upgrade the L2CrossDomainMessenger
        calls[4] = IMulticall3.Call3({
            target: Predeploys.PROXY_ADMIN,
            allowFailure: false,
            callData: abi.encodeCall(
                ProxyAdmin.upgrade,
                (payable(prox.L2CrossDomainMessenger), impl.L2CrossDomainMessenger)
            )
        });

        // Upgrade the L2ERC721Bridge
        calls[5] = IMulticall3.Call3({
            target: Predeploys.PROXY_ADMIN,
            allowFailure: false,
            callData: abi.encodeCall(
                ProxyAdmin.upgrade,
                (payable(prox.L2ERC721Bridge), impl.L2ERC721Bridge)
            )
        });

        // Upgrade the L2StandardBridge
        calls[6] = IMulticall3.Call3({
            target: Predeploys.PROXY_ADMIN,
            allowFailure: false,
            callData: abi.encodeCall(
                ProxyAdmin.upgrade,
                (payable(prox.L2StandardBridge), impl.L2StandardBridge)
            )
        });

        // Upgrade the L2ToL1MessagePasser
        calls[7] = IMulticall3.Call3({
            target: Predeploys.PROXY_ADMIN,
            allowFailure: false,
            callData: abi.encodeCall(
                ProxyAdmin.upgrade,
                (payable(prox.L2ToL1MessagePasser), impl.L2ToL1MessagePasser)
            )
        });

        // Upgrade the SequencerFeeVault
        calls[8] = IMulticall3.Call3({
            target: Predeploys.PROXY_ADMIN,
            allowFailure: false,
            callData: abi.encodeCall(
                ProxyAdmin.upgrade,
                (payable(prox.SequencerFeeVault), impl.SequencerFeeVault)
            )
        });

        // Upgrade the OptimismMintableERC20Factory
        calls[9] = IMulticall3.Call3({
            target: Predeploys.PROXY_ADMIN,
            allowFailure: false,
            callData: abi.encodeCall(
                ProxyAdmin.upgrade,
                (payable(prox.OptimismMintableERC20Factory), impl.OptimismMintableERC20Factory)
            )
        });

        // Upgrade the OptimismMintableERC721Factory
        calls[10] = IMulticall3.Call3({
            target: Predeploys.PROXY_ADMIN,
            allowFailure: false,
            callData: abi.encodeCall(
                ProxyAdmin.upgrade,
                (payable(prox.OptimismMintableERC721Factory), impl.OptimismMintableERC721Factory)
            )
        });

        return abi.encodeCall(IMulticall3.aggregate3, (calls));
    }

    /**
     * @notice Returns the ContractSet that represents the implementations for a given network.
     */
    function getImplementations() internal view returns (ContractSet memory) {
        ContractSet memory set = implementations[CHAIN_ID];
        require(set.BaseFeeVault != address(0), "no implementations for this network");
        return set;
    }

    /**
     * @notice Returns the ContractSet that represents the proxies for a given network.
     */
    function getProxies() internal view returns (ContractSet memory) {
        ContractSet memory set = proxies[CHAIN_ID];
        require(set.BaseFeeVault != address(0), "no proxies for this network");
        return set;
    }
}
