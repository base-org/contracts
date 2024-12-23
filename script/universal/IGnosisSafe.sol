// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.10;

/// @title Enum - Collection of enums used in Safe contracts.
/// @notice This contract defines common enums for Gnosis Safe operations.
abstract contract Enum {
    enum Operation {
        Call,          // Standard function call
        DelegateCall   // Delegate call, where the calling contract's context is preserved
    }
}

/// @title IGnosisSafe - Gnosis Safe Interface
/// @notice This interface provides access to the core functionality of a Gnosis Safe contract.
interface IGnosisSafe {
    // Events
    event AddedOwner(address owner); // Emitted when a new owner is added to the Safe.
    event ApproveHash(bytes32 indexed approvedHash, address indexed owner); // Emitted when a hash is approved by an owner.
    event ChangedFallbackHandler(address handler); // Emitted when the fallback handler is changed.
    event ChangedGuard(address guard); // Emitted when the guard contract is changed.
    event ChangedThreshold(uint256 threshold); // Emitted when the threshold of required signatures is updated.
    event DisabledModule(address module); // Emitted when a module is disabled.
    event EnabledModule(address module); // Emitted when a module is enabled.
    event ExecutionFailure(bytes32 txHash, uint256 payment); // Emitted when a transaction execution fails.
    event ExecutionFromModuleFailure(address indexed module); // Emitted when a module's transaction fails.
    event ExecutionFromModuleSuccess(address indexed module); // Emitted when a module's transaction succeeds.
    event ExecutionSuccess(bytes32 txHash, uint256 payment); // Emitted when a transaction is executed successfully.
    event RemovedOwner(address owner); // Emitted when an owner is removed from the Safe.
    event SafeReceived(address indexed sender, uint256 value); // Emitted when the Safe receives Ether.
    event SafeSetup(
        address indexed initiator, // Address that initiated the setup
        address[] owners,          // List of owners
        uint256 threshold,         // Number of required confirmations
        address initializer,       // Contract used for initialization
        address fallbackHandler    // Fallback handler contract address
    );
    event SignMsg(bytes32 indexed msgHash); // Emitted when a message hash is signed.

    // Functions
    function VERSION() external view returns (string memory); // Returns the version of the Safe.

    /// @notice Adds a new owner to the Safe and updates the signature threshold.
    /// @param owner Address of the new owner to be added.
    /// @param _threshold New threshold for required confirmations.
    function addOwnerWithThreshold(address owner, uint256 _threshold) external;

    /// @notice Approves a hash to authorize its execution.
    /// @param hashToApprove The hash to be approved by the caller.
    function approveHash(bytes32 hashToApprove) external;

    /// @notice Checks whether a specific hash has been approved by a specific owner.
    /// @param owner Address of the owner.
    /// @param hash Hash to check approval for.
    /// @return Returns 1 if approved, otherwise 0.
    function approvedHashes(address owner, bytes32 hash) external view returns (uint256);

    /// @notice Updates the signature threshold for the Safe.
    /// @param _threshold New threshold value.
    function changeThreshold(uint256 _threshold) external;

    /// @notice Verifies multiple signatures for a given hash and data.
    /// @param dataHash Hash of the data to be signed.
    /// @param data Data to verify signatures against.
    /// @param signatures Combined signatures.
    /// @param requiredSignatures Number of required signatures.
    function checkNSignatures(
        bytes32 dataHash,
        bytes memory data,
        bytes memory signatures,
        uint256 requiredSignatures
    ) external view;

    /// @notice Verifies signatures for a given hash and data.
    /// @param dataHash Hash of the data to be signed.
    /// @param data Data to verify signatures against.
    /// @param signatures Combined signatures.
    function checkSignatures(
        bytes32 dataHash,
        bytes memory data,
        bytes memory signatures
    ) external view;

    /// @notice Disables a module for the Safe.
    /// @param prevModule Address of the module preceding the one to disable in the module list.
    /// @param module Address of the module to disable.
    function disableModule(address prevModule, address module) external;

    /// @notice Returns the domain separator for the Safe.
    /// @return The domain separator as a `bytes32` value.
    function domainSeparator() external view returns (bytes32);

    /// @notice Enables a module for the Safe.
    /// @param module Address of the module to enable.
    function enableModule(address module) external;

    /// @notice Encodes transaction data for a Safe transaction.
    /// @return Encoded transaction data as bytes.
    function encodeTransactionData(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address refundReceiver,
        uint256 _nonce
    ) external view returns (bytes memory);

    /// @notice Executes a transaction from the Safe.
    /// @return success `true` if the transaction succeeds, otherwise `false`.
    function execTransaction(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address refundReceiver,
        bytes memory signatures
    ) external payable returns (bool success);

    /// @notice Executes a transaction directly from a module.
    /// @return success `true` if the transaction succeeds, otherwise `false`.
    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) external returns (bool success);

    /// @notice Executes a transaction from a module and returns data.
    /// @return success `true` if the transaction succeeds, otherwise `false`.
    /// @return returnData Data returned by the transaction.
    function execTransactionFromModuleReturnData(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) external returns (bool success, bytes memory returnData);

    /// @notice Returns the chain ID of the Safe.
    /// @return The chain ID as a uint256.
    function getChainId() external view returns (uint256);

    /// @notice Retrieves modules in a paginated format.
    /// @param start Address to start pagination from.
    /// @param pageSize Maximum number of modules to retrieve.
    /// @return array List of module addresses.
    /// @return next Address for the next pagination start.
    function getModulesPaginated(address start, uint256 pageSize)
        external
        view
        returns (address[] memory array, address next);

    /// @notice Retrieves the list of owners of the Safe.
    /// @return Array of owner addresses.
    function getOwners() external view returns (address[] memory);

    /// @notice Reads raw storage data from the Safe contract.
    /// @return The raw data as bytes.
    function getStorageAt(uint256 offset, uint256 length) external view returns (bytes memory);

    /// @notice Returns the current signature threshold for the Safe.
    /// @return The threshold as a uint256.
    function getThreshold() external view returns (uint256);

    /// @notice Generates the hash for a Safe transaction.
    function getTransactionHash(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address refundReceiver,
        uint256 _nonce
    ) external view returns (bytes32);

    /// @notice Checks if a module is enabled.
    /// @return `true` if the module is enabled, otherwise `false`.
    function isModuleEnabled(address module) external view returns (bool);

    /// @notice Checks if an address is an owner.
    /// @return `true` if the address is an owner, otherwise `false`.
    function isOwner(address owner) external view returns (bool);

    function nonce() external view returns (uint256);

    function removeOwner(address prevOwner, address owner, uint256 _threshold) external;

    function requiredTxGas(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) external returns (uint256);

    function setFallbackHandler(address handler) external;

    function setGuard(address guard) external;

    function setup(
        address[] memory _owners,
        uint256 _threshold,
        address to,
        bytes memory data,
        address fallbackHandler,
        address paymentToken,
        uint256 payment,
        address paymentReceiver
    ) external;

    function signedMessages(bytes32) external view returns (uint256);

    function simulateAndRevert(address targetContract, bytes memory calldataPayload) external;

    function swapOwner(address prevOwner, address oldOwner, address newOwner) external;
}
