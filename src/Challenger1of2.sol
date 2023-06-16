// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title Challenger1of2
 * @dev This contract serves the role of the Challenger, defined in L2OutputOracle.sol:
 * https://github.com/ethereum-optimism/optimism/blob/3580bf1b41d80fcb2b895d5610836bfad27fc989/packages/contracts-bedrock/contracts/L1/L2OutputOracle.sol
 * It enforces a simple 1 of 2 design, where neither party can remove the other's
 * permissions to execute a Challenger call.
 */
contract Challenger1of2 {
    using Address for address;

    /*//////////////////////////////////////////////////////////////
                            CONSTANTS
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev The address of Optimism's signer (likely a multisig)
     */
    address public immutable OP_SIGNER;

    /**
     * @dev The address of counter party's signer (likely a multisig)
     */
    address public immutable OTHER_SIGNER;

    /**
     * @dev The address of the L2OutputOracleProxy contract.
     */
    address public immutable L2_OUTPUT_ORACLE_PROXY;

    /*//////////////////////////////////////////////////////////////
                            EVENTS
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev Emitted when a Challenger call is made by a signer.
     * @param _caller The signer making the call.
     * @param _data The data of the call being made.
     * @param _result The result of the call being made.
     */
    event ChallengerCallExecuted(
        address indexed _caller,
        bytes _data,
        bytes _result
    );

    /*//////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev Constructor to set the values of the constants.
     * @param _opSigner Address of Optimism signer.
     * @param _otherSigner Address of counter party signer.
     * @param _l2OutputOracleProxy Address of the L2OutputOracleProxy contract.
     */
    constructor(address _opSigner, address _otherSigner, address _l2OutputOracleProxy) {
        require(_opSigner != address(0), "Challenger1of2: opSigner cannot be zero address");
        require(_otherSigner != address(0), "Challenger1of2: otherSigner cannot be zero address");
        require(
            _l2OutputOracleProxy.isContract(),
            "Challenger1of2: l2OutputOracleProxy must be a contract"
        );

        OP_SIGNER = _opSigner;
        OTHER_SIGNER = _otherSigner;
        L2_OUTPUT_ORACLE_PROXY = _l2OutputOracleProxy;
    }

    /*//////////////////////////////////////////////////////////////
                        External Functions
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev Executes a call as the Challenger (must be called by 
     * Optimism or counter party signer).
     * @param _data Data for function call.
     */
    function execute(bytes memory _data) external {
        require(
            msg.sender == OTHER_SIGNER || msg.sender == OP_SIGNER,
            "Challenger1of2: must be an approved signer to execute"
        );

        bytes memory result = Address.functionCall(
            L2_OUTPUT_ORACLE_PROXY,
            _data,
            "Challenger1of2: failed to execute"
        );

        emit ChallengerCallExecuted(msg.sender, _data, result);
    }
}