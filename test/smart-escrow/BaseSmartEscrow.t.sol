// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { CommonTest } from "test/CommonTest.t.sol";
import { MockERC20 } from "test/MockERC20.t.sol";
import "src/smart-escrow/SmartEscrow.sol";

contract BaseSmartEscrowTest is CommonTest {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event BenefactorUpdated(address indexed oldBenefactor, address indexed newBenefactor);
    event BeneficiaryUpdated(address indexed oldBeneficiary, address indexed newBeneficiary);
    event ContractTerminated();
    event ContractResumed();
    event TokensWithdrawn(address indexed benefactor, uint256 amount);
    event TokensReleased(address indexed beneficiary, uint256 amount);

    MockERC20 public constant OP_TOKEN = MockERC20(0x4200000000000000000000000000000000000042);
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 public constant BENEFACTOR_OWNER_ROLE = keccak256("smartescrow.roles.benefactorowner");
    bytes32 public constant BENEFICIARY_OWNER_ROLE = keccak256("smartescrow.roles.beneficiaryowner");
    bytes32 public constant TERMINATOR_ROLE = keccak256("smartescrow.roles.terminator");

    SmartEscrow public smartEscrow;
    address public benefactor = address(1);
    address public benefactorOwner = address(2);
    address public beneficiary = address(3);
    address public beneficiaryOwner = address(4);
    address public escrowOwner = address(5);
    uint256 public start = 1720674000;
    uint256 public cliffStart = 1724976000;
    uint256 public end = 1878462000;
    uint256 public vestingPeriod = 7889400;
    uint256 public initialTokens = 17895697;
    uint256 public vestingEventTokens = 4473924;
    uint256 public totalTokensToRelease = 107374177;

    function setUp() public override {
        smartEscrow = new SmartEscrow(
            benefactor,
            beneficiary,
            benefactorOwner,
            beneficiaryOwner,
            escrowOwner,
            start,
            cliffStart,
            end,
            vestingPeriod,
            initialTokens,
            vestingEventTokens
        );

        MockERC20 opToken = new MockERC20("Optimism", "OP");
        vm.etch(0x4200000000000000000000000000000000000042, address(opToken).code);

        vm.prank(address(smartEscrow));
        OP_TOKEN.mint(totalTokensToRelease);
    }

    function accessControlErrorMessage(address account, bytes32 role) internal pure returns (bytes memory) {
        return bytes(
            abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(account),
                " is missing role ",
                Strings.toHexString(uint256(role), 32)
            )
        );
    }
}