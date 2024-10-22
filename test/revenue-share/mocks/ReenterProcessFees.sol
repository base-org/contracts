// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {BalanceTracker} from "src/revenue-share/BalanceTracker.sol";

contract ReenterProcessFees {
    receive() external payable {
        BalanceTracker(payable(msg.sender)).processFees();
    }
}
