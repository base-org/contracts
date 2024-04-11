// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title Vetoer1of2
 * @dev This contract serves the role of the Vetoer, defined in DelayedVetoable.sol:
 * https://github.com/ethereum-optimism/optimism/blob/d72fb46daf3a6831cb01a78931f8c6e0d52ae243/packages/contracts-bedrock/src/L1/DelayedVetoable.sol
 * It enforces a simple 1 of 2 design, where neither party can remove the other's
 * permissions to execute a Veto call.
 */
contract Vetoer1of2 {
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
    address public immutable DELAYED_VETOABLE;

    /*//////////////////////////////////////////////////////////////
                            EVENTS
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev Emitted when a Veto call is made by a signer.
     * @param _caller The signer making the call.
     * @param _data The data of the call being made.
     * @param _result The result of the call being made.
     */
    event VetoCallExecuted(
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
     * @param _delayedVetoable Address of the DelayedVetoable contract.
     */
    constructor(address _opSigner, address _otherSigner, address _delayedVetoable) {
        require(_opSigner != address(0), "Vetoer1of2: opSigner cannot be zero address");
        require(_otherSigner != address(0), "Vetoer1of2: otherSigner cannot be zero address");
        require(
            _delayedVetoable.isContract(),
            "Vetoer1of2: delayedVetoable must be a contract"
        );

        OP_SIGNER = _opSigner;
        OTHER_SIGNER = _otherSigner;
        DELAYED_VETOABLE = _delayedVetoable;
    }

    /*//////////////////////////////////////////////////////////////
                        External Functions
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev Executes a call as the Vetoer (must be called by
     * Optimism or counter party signer).
     * @param _data Data for function call.
     */
    function execute(bytes memory _data) external {
        require(
            msg.sender == OTHER_SIGNER || msg.sender == OP_SIGNER,
            "Vetoer1of2: must be an approved signer to execute"
        );

        bytes memory result = Address.functionCall(
            DELAYED_VETOABLE,
            _data,
            "Vetoer1of2: failed to execute"
        );

        emit VetoCallExecuted(msg.sender, _data, result);
    }
}
