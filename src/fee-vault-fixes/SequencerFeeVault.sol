// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { Semver } from "@eth-optimism-bedrock/src/universal/Semver.sol";
import { FeeVault } from "./FeeVault.sol";

/// @custom:proxied
/// @custom:predeploy 0x4200000000000000000000000000000000000011
/// @title SequencerFeeVault
/// @notice The SequencerFeeVault is the contract that holds any fees paid to the Sequencer during
///         transaction processing and block production.
contract SequencerFeeVault is FeeVault, Semver {
    /// @custom:semver 1.2.2
    /// @notice Constructs the SequencerFeeVault contract.
    constructor() Semver(1, 2, 2) {}
}
