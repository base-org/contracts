// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { Semver } from "@eth-optimism-bedrock/src/universal/Semver.sol";
import { FeeVault } from "./FeeVault.sol";

/// @custom:proxied
/// @custom:predeploy 0x4200000000000000000000000000000000000011
/// @title L1FeeVault
/// @notice The L1FeeVault accumulates the L1 portion of the transaction fees.
contract L1FeeVault is FeeVault, Semver {
    /// @custom:semver 1.2.2
    /// @notice Constructs the L1FeeVault contract.
    constructor() Semver(1, 2, 2) {}
}
