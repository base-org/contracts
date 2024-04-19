// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {DelayedVetoable} from "@eth-optimism-bedrock/src/L1/DelayedVetoable.sol";

/// @title Vetoer1of2
///
/// @dev This contract serves the role of the Vetoer, defined in DelayedVetoable.sol:
///      https://github.com/ethereum-optimism/optimism/blob/d72fb46daf3a6831cb01a78931f8c6e0d52ae243/packages/contracts-bedrock/src/L1/DelayedVetoable.sol
///      It enforces a simple 1 of 2 design, where neither party can remove the other's
///      permissions to execute a Veto call.
///
contract Vetoer1of2 {
    using Address for address;

    /////////////////////////////////////////////////////////////
    //                        CONSTANTS                        //
    /////////////////////////////////////////////////////////////

    /// @notice The address of Optimism's signer (likely a multisig)
    address public immutable opSigner;

    /// @notice The address of counter party's signer (likely a multisig)
    address public immutable otherSigner;

    /// @notice The address of the DelayedVetoable contract.
    address public immutable delayedVetoable;

    //////////////////////////////////////////////////////////////
    //                        EVENTS                            //
    //////////////////////////////////////////////////////////////

    /// @notice Emitted when a Veto call is made by a signer.
    ///
    /// @param caller The signer making the call.
    /// @param result The result of the call being made.
    event VetoCallExecuted(address indexed caller, bytes result);

    //////////////////////////////////////////////////////////////
    //                        Constructor                       //
    //////////////////////////////////////////////////////////////

    /// @notice Constructor to set the values of the constants.
    ///
    /// @dev The `DelayedVetoable` contract is deployed in this constructor to easily establish
    ///      the link between both contracts.
    ///
    /// @param opSigner_ Address of Optimism signer.
    /// @param otherSigner_ Address of counter party signer.
    /// @param initiator Address of the initiator.
    /// @param target Address of the target.
    /// @param operatingDelay Time to delay when the system is operational.
    constructor(address opSigner_, address otherSigner_, address initiator, address target, uint256 operatingDelay) {
        require(opSigner_ != address(0), "Vetoer1of2: opSigner cannot be zero address");
        require(otherSigner_ != address(0), "Vetoer1of2: otherSigner cannot be zero address");

        opSigner = opSigner_;
        otherSigner = otherSigner_;

        delayedVetoable = address(
            new DelayedVetoable({
                vetoer_: address(this),
                initiator_: initiator,
                target_: target,
                operatingDelay_: operatingDelay
            })
        );
    }

    //////////////////////////////////////////////////////////////
    //                    External Functions                    //
    //////////////////////////////////////////////////////////////

    /// @notice Passthrough for either signer to execute a veto on the `DelayedVetoable` contract.
    ///
    /// @dev Revert if not called by `opSigner` or `otherSigner`.
    function veto() external {
        require(
            msg.sender == otherSigner || msg.sender == opSigner, "Vetoer1of2: must be an approved signer to execute"
        );

        bytes memory result = Address.functionCall({
            target: delayedVetoable,
            data: msg.data,
            errorMessage: "Vetoer1of2: failed to execute"
        });

        emit VetoCallExecuted({caller: msg.sender, result: result});
    }
}
