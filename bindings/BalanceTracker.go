// Code generated - DO NOT EDIT.
// This file is a generated binding and any manual changes will be lost.

package bindings

import (
	"errors"
	"math/big"
	"strings"

	ethereum "github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/event"
)

// Reference imports to suppress errors if they are not otherwise used.
var (
	_ = errors.New
	_ = big.NewInt
	_ = strings.NewReader
	_ = ethereum.NotFound
	_ = bind.Bind
	_ = common.Big1
	_ = types.BloomLookup
	_ = event.NewSubscription
	_ = abi.ConvertType
)

// BalanceTrackerMetaData contains all meta data concerning the BalanceTracker contract.
var BalanceTrackerMetaData = &bind.MetaData{
	ABI: "[{\"inputs\":[{\"internalType\":\"addresspayable\",\"name\":\"_profitWallet\",\"type\":\"address\"}],\"stateMutability\":\"nonpayable\",\"type\":\"constructor\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":false,\"internalType\":\"uint8\",\"name\":\"version\",\"type\":\"uint8\"}],\"name\":\"Initialized\",\"type\":\"event\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":true,\"internalType\":\"address\",\"name\":\"_systemAddress\",\"type\":\"address\"},{\"indexed\":true,\"internalType\":\"bool\",\"name\":\"_success\",\"type\":\"bool\"},{\"indexed\":false,\"internalType\":\"uint256\",\"name\":\"_balanceNeeded\",\"type\":\"uint256\"},{\"indexed\":false,\"internalType\":\"uint256\",\"name\":\"_balanceSent\",\"type\":\"uint256\"}],\"name\":\"ProcessedFunds\",\"type\":\"event\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":true,\"internalType\":\"address\",\"name\":\"_sender\",\"type\":\"address\"},{\"indexed\":false,\"internalType\":\"uint256\",\"name\":\"_amount\",\"type\":\"uint256\"}],\"name\":\"ReceivedFunds\",\"type\":\"event\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":true,\"internalType\":\"address\",\"name\":\"_profitWallet\",\"type\":\"address\"},{\"indexed\":true,\"internalType\":\"bool\",\"name\":\"_success\",\"type\":\"bool\"},{\"indexed\":false,\"internalType\":\"uint256\",\"name\":\"_balanceSent\",\"type\":\"uint256\"}],\"name\":\"SentProfit\",\"type\":\"event\"},{\"inputs\":[],\"name\":\"MAX_SYSTEM_ADDRESS_COUNT\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"PROFIT_WALLET\",\"outputs\":[{\"internalType\":\"addresspayable\",\"name\":\"\",\"type\":\"address\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"addresspayable[]\",\"name\":\"_systemAddresses\",\"type\":\"address[]\"},{\"internalType\":\"uint256[]\",\"name\":\"_targetBalances\",\"type\":\"uint256[]\"}],\"name\":\"initialize\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"processFees\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"name\":\"systemAddresses\",\"outputs\":[{\"internalType\":\"addresspayable\",\"name\":\"\",\"type\":\"address\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"name\":\"targetBalances\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"stateMutability\":\"payable\",\"type\":\"receive\"}]",
}

// BalanceTrackerABI is the input ABI used to generate the binding from.
// Deprecated: Use BalanceTrackerMetaData.ABI instead.
var BalanceTrackerABI = BalanceTrackerMetaData.ABI

// BalanceTracker is an auto generated Go binding around an Ethereum contract.
type BalanceTracker struct {
	BalanceTrackerCaller     // Read-only binding to the contract
	BalanceTrackerTransactor // Write-only binding to the contract
	BalanceTrackerFilterer   // Log filterer for contract events
}

// BalanceTrackerCaller is an auto generated read-only Go binding around an Ethereum contract.
type BalanceTrackerCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// BalanceTrackerTransactor is an auto generated write-only Go binding around an Ethereum contract.
type BalanceTrackerTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// BalanceTrackerFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type BalanceTrackerFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// BalanceTrackerSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type BalanceTrackerSession struct {
	Contract     *BalanceTracker   // Generic contract binding to set the session for
	CallOpts     bind.CallOpts     // Call options to use throughout this session
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// BalanceTrackerCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type BalanceTrackerCallerSession struct {
	Contract *BalanceTrackerCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts         // Call options to use throughout this session
}

// BalanceTrackerTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type BalanceTrackerTransactorSession struct {
	Contract     *BalanceTrackerTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts         // Transaction auth options to use throughout this session
}

// BalanceTrackerRaw is an auto generated low-level Go binding around an Ethereum contract.
type BalanceTrackerRaw struct {
	Contract *BalanceTracker // Generic contract binding to access the raw methods on
}

// BalanceTrackerCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type BalanceTrackerCallerRaw struct {
	Contract *BalanceTrackerCaller // Generic read-only contract binding to access the raw methods on
}

// BalanceTrackerTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type BalanceTrackerTransactorRaw struct {
	Contract *BalanceTrackerTransactor // Generic write-only contract binding to access the raw methods on
}

// NewBalanceTracker creates a new instance of BalanceTracker, bound to a specific deployed contract.
func NewBalanceTracker(address common.Address, backend bind.ContractBackend) (*BalanceTracker, error) {
	contract, err := bindBalanceTracker(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &BalanceTracker{BalanceTrackerCaller: BalanceTrackerCaller{contract: contract}, BalanceTrackerTransactor: BalanceTrackerTransactor{contract: contract}, BalanceTrackerFilterer: BalanceTrackerFilterer{contract: contract}}, nil
}

// NewBalanceTrackerCaller creates a new read-only instance of BalanceTracker, bound to a specific deployed contract.
func NewBalanceTrackerCaller(address common.Address, caller bind.ContractCaller) (*BalanceTrackerCaller, error) {
	contract, err := bindBalanceTracker(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &BalanceTrackerCaller{contract: contract}, nil
}

// NewBalanceTrackerTransactor creates a new write-only instance of BalanceTracker, bound to a specific deployed contract.
func NewBalanceTrackerTransactor(address common.Address, transactor bind.ContractTransactor) (*BalanceTrackerTransactor, error) {
	contract, err := bindBalanceTracker(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &BalanceTrackerTransactor{contract: contract}, nil
}

// NewBalanceTrackerFilterer creates a new log filterer instance of BalanceTracker, bound to a specific deployed contract.
func NewBalanceTrackerFilterer(address common.Address, filterer bind.ContractFilterer) (*BalanceTrackerFilterer, error) {
	contract, err := bindBalanceTracker(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &BalanceTrackerFilterer{contract: contract}, nil
}

// bindBalanceTracker binds a generic wrapper to an already deployed contract.
func bindBalanceTracker(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := BalanceTrackerMetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_BalanceTracker *BalanceTrackerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _BalanceTracker.Contract.BalanceTrackerCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_BalanceTracker *BalanceTrackerRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _BalanceTracker.Contract.BalanceTrackerTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_BalanceTracker *BalanceTrackerRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _BalanceTracker.Contract.BalanceTrackerTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_BalanceTracker *BalanceTrackerCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _BalanceTracker.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_BalanceTracker *BalanceTrackerTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _BalanceTracker.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_BalanceTracker *BalanceTrackerTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _BalanceTracker.Contract.contract.Transact(opts, method, params...)
}

// MAXSYSTEMADDRESSCOUNT is a free data retrieval call binding the contract method 0x6d1eb022.
//
// Solidity: function MAX_SYSTEM_ADDRESS_COUNT() view returns(uint256)
func (_BalanceTracker *BalanceTrackerCaller) MAXSYSTEMADDRESSCOUNT(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _BalanceTracker.contract.Call(opts, &out, "MAX_SYSTEM_ADDRESS_COUNT")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// MAXSYSTEMADDRESSCOUNT is a free data retrieval call binding the contract method 0x6d1eb022.
//
// Solidity: function MAX_SYSTEM_ADDRESS_COUNT() view returns(uint256)
func (_BalanceTracker *BalanceTrackerSession) MAXSYSTEMADDRESSCOUNT() (*big.Int, error) {
	return _BalanceTracker.Contract.MAXSYSTEMADDRESSCOUNT(&_BalanceTracker.CallOpts)
}

// MAXSYSTEMADDRESSCOUNT is a free data retrieval call binding the contract method 0x6d1eb022.
//
// Solidity: function MAX_SYSTEM_ADDRESS_COUNT() view returns(uint256)
func (_BalanceTracker *BalanceTrackerCallerSession) MAXSYSTEMADDRESSCOUNT() (*big.Int, error) {
	return _BalanceTracker.Contract.MAXSYSTEMADDRESSCOUNT(&_BalanceTracker.CallOpts)
}

// PROFITWALLET is a free data retrieval call binding the contract method 0x981949e8.
//
// Solidity: function PROFIT_WALLET() view returns(address)
func (_BalanceTracker *BalanceTrackerCaller) PROFITWALLET(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _BalanceTracker.contract.Call(opts, &out, "PROFIT_WALLET")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// PROFITWALLET is a free data retrieval call binding the contract method 0x981949e8.
//
// Solidity: function PROFIT_WALLET() view returns(address)
func (_BalanceTracker *BalanceTrackerSession) PROFITWALLET() (common.Address, error) {
	return _BalanceTracker.Contract.PROFITWALLET(&_BalanceTracker.CallOpts)
}

// PROFITWALLET is a free data retrieval call binding the contract method 0x981949e8.
//
// Solidity: function PROFIT_WALLET() view returns(address)
func (_BalanceTracker *BalanceTrackerCallerSession) PROFITWALLET() (common.Address, error) {
	return _BalanceTracker.Contract.PROFITWALLET(&_BalanceTracker.CallOpts)
}

// SystemAddresses is a free data retrieval call binding the contract method 0x927a1a77.
//
// Solidity: function systemAddresses(uint256 ) view returns(address)
func (_BalanceTracker *BalanceTrackerCaller) SystemAddresses(opts *bind.CallOpts, arg0 *big.Int) (common.Address, error) {
	var out []interface{}
	err := _BalanceTracker.contract.Call(opts, &out, "systemAddresses", arg0)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// SystemAddresses is a free data retrieval call binding the contract method 0x927a1a77.
//
// Solidity: function systemAddresses(uint256 ) view returns(address)
func (_BalanceTracker *BalanceTrackerSession) SystemAddresses(arg0 *big.Int) (common.Address, error) {
	return _BalanceTracker.Contract.SystemAddresses(&_BalanceTracker.CallOpts, arg0)
}

// SystemAddresses is a free data retrieval call binding the contract method 0x927a1a77.
//
// Solidity: function systemAddresses(uint256 ) view returns(address)
func (_BalanceTracker *BalanceTrackerCallerSession) SystemAddresses(arg0 *big.Int) (common.Address, error) {
	return _BalanceTracker.Contract.SystemAddresses(&_BalanceTracker.CallOpts, arg0)
}

// TargetBalances is a free data retrieval call binding the contract method 0x0a565720.
//
// Solidity: function targetBalances(uint256 ) view returns(uint256)
func (_BalanceTracker *BalanceTrackerCaller) TargetBalances(opts *bind.CallOpts, arg0 *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _BalanceTracker.contract.Call(opts, &out, "targetBalances", arg0)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// TargetBalances is a free data retrieval call binding the contract method 0x0a565720.
//
// Solidity: function targetBalances(uint256 ) view returns(uint256)
func (_BalanceTracker *BalanceTrackerSession) TargetBalances(arg0 *big.Int) (*big.Int, error) {
	return _BalanceTracker.Contract.TargetBalances(&_BalanceTracker.CallOpts, arg0)
}

// TargetBalances is a free data retrieval call binding the contract method 0x0a565720.
//
// Solidity: function targetBalances(uint256 ) view returns(uint256)
func (_BalanceTracker *BalanceTrackerCallerSession) TargetBalances(arg0 *big.Int) (*big.Int, error) {
	return _BalanceTracker.Contract.TargetBalances(&_BalanceTracker.CallOpts, arg0)
}

// Initialize is a paid mutator transaction binding the contract method 0x7fbbe46f.
//
// Solidity: function initialize(address[] _systemAddresses, uint256[] _targetBalances) returns()
func (_BalanceTracker *BalanceTrackerTransactor) Initialize(opts *bind.TransactOpts, _systemAddresses []common.Address, _targetBalances []*big.Int) (*types.Transaction, error) {
	return _BalanceTracker.contract.Transact(opts, "initialize", _systemAddresses, _targetBalances)
}

// Initialize is a paid mutator transaction binding the contract method 0x7fbbe46f.
//
// Solidity: function initialize(address[] _systemAddresses, uint256[] _targetBalances) returns()
func (_BalanceTracker *BalanceTrackerSession) Initialize(_systemAddresses []common.Address, _targetBalances []*big.Int) (*types.Transaction, error) {
	return _BalanceTracker.Contract.Initialize(&_BalanceTracker.TransactOpts, _systemAddresses, _targetBalances)
}

// Initialize is a paid mutator transaction binding the contract method 0x7fbbe46f.
//
// Solidity: function initialize(address[] _systemAddresses, uint256[] _targetBalances) returns()
func (_BalanceTracker *BalanceTrackerTransactorSession) Initialize(_systemAddresses []common.Address, _targetBalances []*big.Int) (*types.Transaction, error) {
	return _BalanceTracker.Contract.Initialize(&_BalanceTracker.TransactOpts, _systemAddresses, _targetBalances)
}

// ProcessFees is a paid mutator transaction binding the contract method 0xba69ebed.
//
// Solidity: function processFees() returns()
func (_BalanceTracker *BalanceTrackerTransactor) ProcessFees(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _BalanceTracker.contract.Transact(opts, "processFees")
}

// ProcessFees is a paid mutator transaction binding the contract method 0xba69ebed.
//
// Solidity: function processFees() returns()
func (_BalanceTracker *BalanceTrackerSession) ProcessFees() (*types.Transaction, error) {
	return _BalanceTracker.Contract.ProcessFees(&_BalanceTracker.TransactOpts)
}

// ProcessFees is a paid mutator transaction binding the contract method 0xba69ebed.
//
// Solidity: function processFees() returns()
func (_BalanceTracker *BalanceTrackerTransactorSession) ProcessFees() (*types.Transaction, error) {
	return _BalanceTracker.Contract.ProcessFees(&_BalanceTracker.TransactOpts)
}

// Receive is a paid mutator transaction binding the contract receive function.
//
// Solidity: receive() payable returns()
func (_BalanceTracker *BalanceTrackerTransactor) Receive(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _BalanceTracker.contract.RawTransact(opts, nil) // calldata is disallowed for receive function
}

// Receive is a paid mutator transaction binding the contract receive function.
//
// Solidity: receive() payable returns()
func (_BalanceTracker *BalanceTrackerSession) Receive() (*types.Transaction, error) {
	return _BalanceTracker.Contract.Receive(&_BalanceTracker.TransactOpts)
}

// Receive is a paid mutator transaction binding the contract receive function.
//
// Solidity: receive() payable returns()
func (_BalanceTracker *BalanceTrackerTransactorSession) Receive() (*types.Transaction, error) {
	return _BalanceTracker.Contract.Receive(&_BalanceTracker.TransactOpts)
}

// BalanceTrackerInitializedIterator is returned from FilterInitialized and is used to iterate over the raw logs and unpacked data for Initialized events raised by the BalanceTracker contract.
type BalanceTrackerInitializedIterator struct {
	Event *BalanceTrackerInitialized // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *BalanceTrackerInitializedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(BalanceTrackerInitialized)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(BalanceTrackerInitialized)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *BalanceTrackerInitializedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *BalanceTrackerInitializedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// BalanceTrackerInitialized represents a Initialized event raised by the BalanceTracker contract.
type BalanceTrackerInitialized struct {
	Version uint8
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterInitialized is a free log retrieval operation binding the contract event 0x7f26b83ff96e1f2b6a682f133852f6798a09c465da95921460cefb3847402498.
//
// Solidity: event Initialized(uint8 version)
func (_BalanceTracker *BalanceTrackerFilterer) FilterInitialized(opts *bind.FilterOpts) (*BalanceTrackerInitializedIterator, error) {

	logs, sub, err := _BalanceTracker.contract.FilterLogs(opts, "Initialized")
	if err != nil {
		return nil, err
	}
	return &BalanceTrackerInitializedIterator{contract: _BalanceTracker.contract, event: "Initialized", logs: logs, sub: sub}, nil
}

// WatchInitialized is a free log subscription operation binding the contract event 0x7f26b83ff96e1f2b6a682f133852f6798a09c465da95921460cefb3847402498.
//
// Solidity: event Initialized(uint8 version)
func (_BalanceTracker *BalanceTrackerFilterer) WatchInitialized(opts *bind.WatchOpts, sink chan<- *BalanceTrackerInitialized) (event.Subscription, error) {

	logs, sub, err := _BalanceTracker.contract.WatchLogs(opts, "Initialized")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(BalanceTrackerInitialized)
				if err := _BalanceTracker.contract.UnpackLog(event, "Initialized", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseInitialized is a log parse operation binding the contract event 0x7f26b83ff96e1f2b6a682f133852f6798a09c465da95921460cefb3847402498.
//
// Solidity: event Initialized(uint8 version)
func (_BalanceTracker *BalanceTrackerFilterer) ParseInitialized(log types.Log) (*BalanceTrackerInitialized, error) {
	event := new(BalanceTrackerInitialized)
	if err := _BalanceTracker.contract.UnpackLog(event, "Initialized", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// BalanceTrackerProcessedFundsIterator is returned from FilterProcessedFunds and is used to iterate over the raw logs and unpacked data for ProcessedFunds events raised by the BalanceTracker contract.
type BalanceTrackerProcessedFundsIterator struct {
	Event *BalanceTrackerProcessedFunds // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *BalanceTrackerProcessedFundsIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(BalanceTrackerProcessedFunds)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(BalanceTrackerProcessedFunds)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *BalanceTrackerProcessedFundsIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *BalanceTrackerProcessedFundsIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// BalanceTrackerProcessedFunds represents a ProcessedFunds event raised by the BalanceTracker contract.
type BalanceTrackerProcessedFunds struct {
	SystemAddress common.Address
	Success       bool
	BalanceNeeded *big.Int
	BalanceSent   *big.Int
	Raw           types.Log // Blockchain specific contextual infos
}

// FilterProcessedFunds is a free log retrieval operation binding the contract event 0x74273f98770936abfe9aad12868d2dbe403347b74b7f3a539d0359c123d5d31c.
//
// Solidity: event ProcessedFunds(address indexed _systemAddress, bool indexed _success, uint256 _balanceNeeded, uint256 _balanceSent)
func (_BalanceTracker *BalanceTrackerFilterer) FilterProcessedFunds(opts *bind.FilterOpts, _systemAddress []common.Address, _success []bool) (*BalanceTrackerProcessedFundsIterator, error) {

	var _systemAddressRule []interface{}
	for _, _systemAddressItem := range _systemAddress {
		_systemAddressRule = append(_systemAddressRule, _systemAddressItem)
	}
	var _successRule []interface{}
	for _, _successItem := range _success {
		_successRule = append(_successRule, _successItem)
	}

	logs, sub, err := _BalanceTracker.contract.FilterLogs(opts, "ProcessedFunds", _systemAddressRule, _successRule)
	if err != nil {
		return nil, err
	}
	return &BalanceTrackerProcessedFundsIterator{contract: _BalanceTracker.contract, event: "ProcessedFunds", logs: logs, sub: sub}, nil
}

// WatchProcessedFunds is a free log subscription operation binding the contract event 0x74273f98770936abfe9aad12868d2dbe403347b74b7f3a539d0359c123d5d31c.
//
// Solidity: event ProcessedFunds(address indexed _systemAddress, bool indexed _success, uint256 _balanceNeeded, uint256 _balanceSent)
func (_BalanceTracker *BalanceTrackerFilterer) WatchProcessedFunds(opts *bind.WatchOpts, sink chan<- *BalanceTrackerProcessedFunds, _systemAddress []common.Address, _success []bool) (event.Subscription, error) {

	var _systemAddressRule []interface{}
	for _, _systemAddressItem := range _systemAddress {
		_systemAddressRule = append(_systemAddressRule, _systemAddressItem)
	}
	var _successRule []interface{}
	for _, _successItem := range _success {
		_successRule = append(_successRule, _successItem)
	}

	logs, sub, err := _BalanceTracker.contract.WatchLogs(opts, "ProcessedFunds", _systemAddressRule, _successRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(BalanceTrackerProcessedFunds)
				if err := _BalanceTracker.contract.UnpackLog(event, "ProcessedFunds", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseProcessedFunds is a log parse operation binding the contract event 0x74273f98770936abfe9aad12868d2dbe403347b74b7f3a539d0359c123d5d31c.
//
// Solidity: event ProcessedFunds(address indexed _systemAddress, bool indexed _success, uint256 _balanceNeeded, uint256 _balanceSent)
func (_BalanceTracker *BalanceTrackerFilterer) ParseProcessedFunds(log types.Log) (*BalanceTrackerProcessedFunds, error) {
	event := new(BalanceTrackerProcessedFunds)
	if err := _BalanceTracker.contract.UnpackLog(event, "ProcessedFunds", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// BalanceTrackerReceivedFundsIterator is returned from FilterReceivedFunds and is used to iterate over the raw logs and unpacked data for ReceivedFunds events raised by the BalanceTracker contract.
type BalanceTrackerReceivedFundsIterator struct {
	Event *BalanceTrackerReceivedFunds // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *BalanceTrackerReceivedFundsIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(BalanceTrackerReceivedFunds)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(BalanceTrackerReceivedFunds)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *BalanceTrackerReceivedFundsIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *BalanceTrackerReceivedFundsIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// BalanceTrackerReceivedFunds represents a ReceivedFunds event raised by the BalanceTracker contract.
type BalanceTrackerReceivedFunds struct {
	Sender common.Address
	Amount *big.Int
	Raw    types.Log // Blockchain specific contextual infos
}

// FilterReceivedFunds is a free log retrieval operation binding the contract event 0x5741979df5f3e491501da74d3b0a83dd2496ab1f34929865b3e190a8ad75859a.
//
// Solidity: event ReceivedFunds(address indexed _sender, uint256 _amount)
func (_BalanceTracker *BalanceTrackerFilterer) FilterReceivedFunds(opts *bind.FilterOpts, _sender []common.Address) (*BalanceTrackerReceivedFundsIterator, error) {

	var _senderRule []interface{}
	for _, _senderItem := range _sender {
		_senderRule = append(_senderRule, _senderItem)
	}

	logs, sub, err := _BalanceTracker.contract.FilterLogs(opts, "ReceivedFunds", _senderRule)
	if err != nil {
		return nil, err
	}
	return &BalanceTrackerReceivedFundsIterator{contract: _BalanceTracker.contract, event: "ReceivedFunds", logs: logs, sub: sub}, nil
}

// WatchReceivedFunds is a free log subscription operation binding the contract event 0x5741979df5f3e491501da74d3b0a83dd2496ab1f34929865b3e190a8ad75859a.
//
// Solidity: event ReceivedFunds(address indexed _sender, uint256 _amount)
func (_BalanceTracker *BalanceTrackerFilterer) WatchReceivedFunds(opts *bind.WatchOpts, sink chan<- *BalanceTrackerReceivedFunds, _sender []common.Address) (event.Subscription, error) {

	var _senderRule []interface{}
	for _, _senderItem := range _sender {
		_senderRule = append(_senderRule, _senderItem)
	}

	logs, sub, err := _BalanceTracker.contract.WatchLogs(opts, "ReceivedFunds", _senderRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(BalanceTrackerReceivedFunds)
				if err := _BalanceTracker.contract.UnpackLog(event, "ReceivedFunds", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseReceivedFunds is a log parse operation binding the contract event 0x5741979df5f3e491501da74d3b0a83dd2496ab1f34929865b3e190a8ad75859a.
//
// Solidity: event ReceivedFunds(address indexed _sender, uint256 _amount)
func (_BalanceTracker *BalanceTrackerFilterer) ParseReceivedFunds(log types.Log) (*BalanceTrackerReceivedFunds, error) {
	event := new(BalanceTrackerReceivedFunds)
	if err := _BalanceTracker.contract.UnpackLog(event, "ReceivedFunds", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// BalanceTrackerSentProfitIterator is returned from FilterSentProfit and is used to iterate over the raw logs and unpacked data for SentProfit events raised by the BalanceTracker contract.
type BalanceTrackerSentProfitIterator struct {
	Event *BalanceTrackerSentProfit // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *BalanceTrackerSentProfitIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(BalanceTrackerSentProfit)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(BalanceTrackerSentProfit)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *BalanceTrackerSentProfitIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *BalanceTrackerSentProfitIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// BalanceTrackerSentProfit represents a SentProfit event raised by the BalanceTracker contract.
type BalanceTrackerSentProfit struct {
	ProfitWallet common.Address
	Success      bool
	BalanceSent  *big.Int
	Raw          types.Log // Blockchain specific contextual infos
}

// FilterSentProfit is a free log retrieval operation binding the contract event 0xbadd9d7563efca77438dc132e885aa156837e0b784469f68fbd810cbfb6cda77.
//
// Solidity: event SentProfit(address indexed _profitWallet, bool indexed _success, uint256 _balanceSent)
func (_BalanceTracker *BalanceTrackerFilterer) FilterSentProfit(opts *bind.FilterOpts, _profitWallet []common.Address, _success []bool) (*BalanceTrackerSentProfitIterator, error) {

	var _profitWalletRule []interface{}
	for _, _profitWalletItem := range _profitWallet {
		_profitWalletRule = append(_profitWalletRule, _profitWalletItem)
	}
	var _successRule []interface{}
	for _, _successItem := range _success {
		_successRule = append(_successRule, _successItem)
	}

	logs, sub, err := _BalanceTracker.contract.FilterLogs(opts, "SentProfit", _profitWalletRule, _successRule)
	if err != nil {
		return nil, err
	}
	return &BalanceTrackerSentProfitIterator{contract: _BalanceTracker.contract, event: "SentProfit", logs: logs, sub: sub}, nil
}

// WatchSentProfit is a free log subscription operation binding the contract event 0xbadd9d7563efca77438dc132e885aa156837e0b784469f68fbd810cbfb6cda77.
//
// Solidity: event SentProfit(address indexed _profitWallet, bool indexed _success, uint256 _balanceSent)
func (_BalanceTracker *BalanceTrackerFilterer) WatchSentProfit(opts *bind.WatchOpts, sink chan<- *BalanceTrackerSentProfit, _profitWallet []common.Address, _success []bool) (event.Subscription, error) {

	var _profitWalletRule []interface{}
	for _, _profitWalletItem := range _profitWallet {
		_profitWalletRule = append(_profitWalletRule, _profitWalletItem)
	}
	var _successRule []interface{}
	for _, _successItem := range _success {
		_successRule = append(_successRule, _successItem)
	}

	logs, sub, err := _BalanceTracker.contract.WatchLogs(opts, "SentProfit", _profitWalletRule, _successRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(BalanceTrackerSentProfit)
				if err := _BalanceTracker.contract.UnpackLog(event, "SentProfit", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseSentProfit is a log parse operation binding the contract event 0xbadd9d7563efca77438dc132e885aa156837e0b784469f68fbd810cbfb6cda77.
//
// Solidity: event SentProfit(address indexed _profitWallet, bool indexed _success, uint256 _balanceSent)
func (_BalanceTracker *BalanceTrackerFilterer) ParseSentProfit(log types.Log) (*BalanceTrackerSentProfit, error) {
	event := new(BalanceTrackerSentProfit)
	if err := _BalanceTracker.contract.UnpackLog(event, "SentProfit", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
