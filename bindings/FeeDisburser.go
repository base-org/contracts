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

// FeeDisburserMetaData contains all meta data concerning the FeeDisburser contract.
var FeeDisburserMetaData = &bind.MetaData{
	ABI: "[{\"inputs\":[{\"internalType\":\"addresspayable\",\"name\":\"_optimismWallet\",\"type\":\"address\"},{\"internalType\":\"address\",\"name\":\"_l1Wallet\",\"type\":\"address\"},{\"internalType\":\"uint256\",\"name\":\"_feeDisbursementInterval\",\"type\":\"uint256\"}],\"stateMutability\":\"nonpayable\",\"type\":\"constructor\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":false,\"internalType\":\"uint256\",\"name\":\"_disbursementTime\",\"type\":\"uint256\"},{\"indexed\":false,\"internalType\":\"uint256\",\"name\":\"_paidToOptimism\",\"type\":\"uint256\"},{\"indexed\":false,\"internalType\":\"uint256\",\"name\":\"_totalFeesDisbursed\",\"type\":\"uint256\"}],\"name\":\"FeesDisbursed\",\"type\":\"event\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":true,\"internalType\":\"address\",\"name\":\"_sender\",\"type\":\"address\"},{\"indexed\":false,\"internalType\":\"uint256\",\"name\":\"_amount\",\"type\":\"uint256\"}],\"name\":\"FeesReceived\",\"type\":\"event\"},{\"anonymous\":false,\"inputs\":[],\"name\":\"NoFeesCollected\",\"type\":\"event\"},{\"inputs\":[],\"name\":\"BASIS_POINT_SCALE\",\"outputs\":[{\"internalType\":\"uint32\",\"name\":\"\",\"type\":\"uint32\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"FEE_DISBURSEMENT_INTERVAL\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"L1_WALLET\",\"outputs\":[{\"internalType\":\"address\",\"name\":\"\",\"type\":\"address\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"OPTIMISM_GROSS_REVENUE_SHARE_BASIS_POINTS\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"OPTIMISM_NET_REVENUE_SHARE_BASIS_POINTS\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"OPTIMISM_WALLET\",\"outputs\":[{\"internalType\":\"addresspayable\",\"name\":\"\",\"type\":\"address\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"WITHDRAWAL_MIN_GAS\",\"outputs\":[{\"internalType\":\"uint32\",\"name\":\"\",\"type\":\"uint32\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"disburseFees\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"lastDisbursementTime\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"netFeeRevenue\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"stateMutability\":\"payable\",\"type\":\"receive\"}]",
}

// FeeDisburserABI is the input ABI used to generate the binding from.
// Deprecated: Use FeeDisburserMetaData.ABI instead.
var FeeDisburserABI = FeeDisburserMetaData.ABI

// FeeDisburser is an auto generated Go binding around an Ethereum contract.
type FeeDisburser struct {
	FeeDisburserCaller     // Read-only binding to the contract
	FeeDisburserTransactor // Write-only binding to the contract
	FeeDisburserFilterer   // Log filterer for contract events
}

// FeeDisburserCaller is an auto generated read-only Go binding around an Ethereum contract.
type FeeDisburserCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// FeeDisburserTransactor is an auto generated write-only Go binding around an Ethereum contract.
type FeeDisburserTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// FeeDisburserFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type FeeDisburserFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// FeeDisburserSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type FeeDisburserSession struct {
	Contract     *FeeDisburser     // Generic contract binding to set the session for
	CallOpts     bind.CallOpts     // Call options to use throughout this session
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// FeeDisburserCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type FeeDisburserCallerSession struct {
	Contract *FeeDisburserCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts       // Call options to use throughout this session
}

// FeeDisburserTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type FeeDisburserTransactorSession struct {
	Contract     *FeeDisburserTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts       // Transaction auth options to use throughout this session
}

// FeeDisburserRaw is an auto generated low-level Go binding around an Ethereum contract.
type FeeDisburserRaw struct {
	Contract *FeeDisburser // Generic contract binding to access the raw methods on
}

// FeeDisburserCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type FeeDisburserCallerRaw struct {
	Contract *FeeDisburserCaller // Generic read-only contract binding to access the raw methods on
}

// FeeDisburserTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type FeeDisburserTransactorRaw struct {
	Contract *FeeDisburserTransactor // Generic write-only contract binding to access the raw methods on
}

// NewFeeDisburser creates a new instance of FeeDisburser, bound to a specific deployed contract.
func NewFeeDisburser(address common.Address, backend bind.ContractBackend) (*FeeDisburser, error) {
	contract, err := bindFeeDisburser(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &FeeDisburser{FeeDisburserCaller: FeeDisburserCaller{contract: contract}, FeeDisburserTransactor: FeeDisburserTransactor{contract: contract}, FeeDisburserFilterer: FeeDisburserFilterer{contract: contract}}, nil
}

// NewFeeDisburserCaller creates a new read-only instance of FeeDisburser, bound to a specific deployed contract.
func NewFeeDisburserCaller(address common.Address, caller bind.ContractCaller) (*FeeDisburserCaller, error) {
	contract, err := bindFeeDisburser(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &FeeDisburserCaller{contract: contract}, nil
}

// NewFeeDisburserTransactor creates a new write-only instance of FeeDisburser, bound to a specific deployed contract.
func NewFeeDisburserTransactor(address common.Address, transactor bind.ContractTransactor) (*FeeDisburserTransactor, error) {
	contract, err := bindFeeDisburser(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &FeeDisburserTransactor{contract: contract}, nil
}

// NewFeeDisburserFilterer creates a new log filterer instance of FeeDisburser, bound to a specific deployed contract.
func NewFeeDisburserFilterer(address common.Address, filterer bind.ContractFilterer) (*FeeDisburserFilterer, error) {
	contract, err := bindFeeDisburser(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &FeeDisburserFilterer{contract: contract}, nil
}

// bindFeeDisburser binds a generic wrapper to an already deployed contract.
func bindFeeDisburser(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := FeeDisburserMetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_FeeDisburser *FeeDisburserRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _FeeDisburser.Contract.FeeDisburserCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_FeeDisburser *FeeDisburserRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _FeeDisburser.Contract.FeeDisburserTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_FeeDisburser *FeeDisburserRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _FeeDisburser.Contract.FeeDisburserTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_FeeDisburser *FeeDisburserCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _FeeDisburser.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_FeeDisburser *FeeDisburserTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _FeeDisburser.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_FeeDisburser *FeeDisburserTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _FeeDisburser.Contract.contract.Transact(opts, method, params...)
}

// BASISPOINTSCALE is a free data retrieval call binding the contract method 0x5b201d83.
//
// Solidity: function BASIS_POINT_SCALE() view returns(uint32)
func (_FeeDisburser *FeeDisburserCaller) BASISPOINTSCALE(opts *bind.CallOpts) (uint32, error) {
	var out []interface{}
	err := _FeeDisburser.contract.Call(opts, &out, "BASIS_POINT_SCALE")

	if err != nil {
		return *new(uint32), err
	}

	out0 := *abi.ConvertType(out[0], new(uint32)).(*uint32)

	return out0, err

}

// BASISPOINTSCALE is a free data retrieval call binding the contract method 0x5b201d83.
//
// Solidity: function BASIS_POINT_SCALE() view returns(uint32)
func (_FeeDisburser *FeeDisburserSession) BASISPOINTSCALE() (uint32, error) {
	return _FeeDisburser.Contract.BASISPOINTSCALE(&_FeeDisburser.CallOpts)
}

// BASISPOINTSCALE is a free data retrieval call binding the contract method 0x5b201d83.
//
// Solidity: function BASIS_POINT_SCALE() view returns(uint32)
func (_FeeDisburser *FeeDisburserCallerSession) BASISPOINTSCALE() (uint32, error) {
	return _FeeDisburser.Contract.BASISPOINTSCALE(&_FeeDisburser.CallOpts)
}

// FEEDISBURSEMENTINTERVAL is a free data retrieval call binding the contract method 0x54664de5.
//
// Solidity: function FEE_DISBURSEMENT_INTERVAL() view returns(uint256)
func (_FeeDisburser *FeeDisburserCaller) FEEDISBURSEMENTINTERVAL(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _FeeDisburser.contract.Call(opts, &out, "FEE_DISBURSEMENT_INTERVAL")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// FEEDISBURSEMENTINTERVAL is a free data retrieval call binding the contract method 0x54664de5.
//
// Solidity: function FEE_DISBURSEMENT_INTERVAL() view returns(uint256)
func (_FeeDisburser *FeeDisburserSession) FEEDISBURSEMENTINTERVAL() (*big.Int, error) {
	return _FeeDisburser.Contract.FEEDISBURSEMENTINTERVAL(&_FeeDisburser.CallOpts)
}

// FEEDISBURSEMENTINTERVAL is a free data retrieval call binding the contract method 0x54664de5.
//
// Solidity: function FEE_DISBURSEMENT_INTERVAL() view returns(uint256)
func (_FeeDisburser *FeeDisburserCallerSession) FEEDISBURSEMENTINTERVAL() (*big.Int, error) {
	return _FeeDisburser.Contract.FEEDISBURSEMENTINTERVAL(&_FeeDisburser.CallOpts)
}

// L1WALLET is a free data retrieval call binding the contract method 0x36f1a6e5.
//
// Solidity: function L1_WALLET() view returns(address)
func (_FeeDisburser *FeeDisburserCaller) L1WALLET(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _FeeDisburser.contract.Call(opts, &out, "L1_WALLET")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// L1WALLET is a free data retrieval call binding the contract method 0x36f1a6e5.
//
// Solidity: function L1_WALLET() view returns(address)
func (_FeeDisburser *FeeDisburserSession) L1WALLET() (common.Address, error) {
	return _FeeDisburser.Contract.L1WALLET(&_FeeDisburser.CallOpts)
}

// L1WALLET is a free data retrieval call binding the contract method 0x36f1a6e5.
//
// Solidity: function L1_WALLET() view returns(address)
func (_FeeDisburser *FeeDisburserCallerSession) L1WALLET() (common.Address, error) {
	return _FeeDisburser.Contract.L1WALLET(&_FeeDisburser.CallOpts)
}

// OPTIMISMGROSSREVENUESHAREBASISPOINTS is a free data retrieval call binding the contract method 0x235d506d.
//
// Solidity: function OPTIMISM_GROSS_REVENUE_SHARE_BASIS_POINTS() view returns(uint256)
func (_FeeDisburser *FeeDisburserCaller) OPTIMISMGROSSREVENUESHAREBASISPOINTS(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _FeeDisburser.contract.Call(opts, &out, "OPTIMISM_GROSS_REVENUE_SHARE_BASIS_POINTS")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// OPTIMISMGROSSREVENUESHAREBASISPOINTS is a free data retrieval call binding the contract method 0x235d506d.
//
// Solidity: function OPTIMISM_GROSS_REVENUE_SHARE_BASIS_POINTS() view returns(uint256)
func (_FeeDisburser *FeeDisburserSession) OPTIMISMGROSSREVENUESHAREBASISPOINTS() (*big.Int, error) {
	return _FeeDisburser.Contract.OPTIMISMGROSSREVENUESHAREBASISPOINTS(&_FeeDisburser.CallOpts)
}

// OPTIMISMGROSSREVENUESHAREBASISPOINTS is a free data retrieval call binding the contract method 0x235d506d.
//
// Solidity: function OPTIMISM_GROSS_REVENUE_SHARE_BASIS_POINTS() view returns(uint256)
func (_FeeDisburser *FeeDisburserCallerSession) OPTIMISMGROSSREVENUESHAREBASISPOINTS() (*big.Int, error) {
	return _FeeDisburser.Contract.OPTIMISMGROSSREVENUESHAREBASISPOINTS(&_FeeDisburser.CallOpts)
}

// OPTIMISMNETREVENUESHAREBASISPOINTS is a free data retrieval call binding the contract method 0x93819a3f.
//
// Solidity: function OPTIMISM_NET_REVENUE_SHARE_BASIS_POINTS() view returns(uint256)
func (_FeeDisburser *FeeDisburserCaller) OPTIMISMNETREVENUESHAREBASISPOINTS(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _FeeDisburser.contract.Call(opts, &out, "OPTIMISM_NET_REVENUE_SHARE_BASIS_POINTS")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// OPTIMISMNETREVENUESHAREBASISPOINTS is a free data retrieval call binding the contract method 0x93819a3f.
//
// Solidity: function OPTIMISM_NET_REVENUE_SHARE_BASIS_POINTS() view returns(uint256)
func (_FeeDisburser *FeeDisburserSession) OPTIMISMNETREVENUESHAREBASISPOINTS() (*big.Int, error) {
	return _FeeDisburser.Contract.OPTIMISMNETREVENUESHAREBASISPOINTS(&_FeeDisburser.CallOpts)
}

// OPTIMISMNETREVENUESHAREBASISPOINTS is a free data retrieval call binding the contract method 0x93819a3f.
//
// Solidity: function OPTIMISM_NET_REVENUE_SHARE_BASIS_POINTS() view returns(uint256)
func (_FeeDisburser *FeeDisburserCallerSession) OPTIMISMNETREVENUESHAREBASISPOINTS() (*big.Int, error) {
	return _FeeDisburser.Contract.OPTIMISMNETREVENUESHAREBASISPOINTS(&_FeeDisburser.CallOpts)
}

// OPTIMISMWALLET is a free data retrieval call binding the contract method 0x0c8cd070.
//
// Solidity: function OPTIMISM_WALLET() view returns(address)
func (_FeeDisburser *FeeDisburserCaller) OPTIMISMWALLET(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _FeeDisburser.contract.Call(opts, &out, "OPTIMISM_WALLET")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// OPTIMISMWALLET is a free data retrieval call binding the contract method 0x0c8cd070.
//
// Solidity: function OPTIMISM_WALLET() view returns(address)
func (_FeeDisburser *FeeDisburserSession) OPTIMISMWALLET() (common.Address, error) {
	return _FeeDisburser.Contract.OPTIMISMWALLET(&_FeeDisburser.CallOpts)
}

// OPTIMISMWALLET is a free data retrieval call binding the contract method 0x0c8cd070.
//
// Solidity: function OPTIMISM_WALLET() view returns(address)
func (_FeeDisburser *FeeDisburserCallerSession) OPTIMISMWALLET() (common.Address, error) {
	return _FeeDisburser.Contract.OPTIMISMWALLET(&_FeeDisburser.CallOpts)
}

// WITHDRAWALMINGAS is a free data retrieval call binding the contract method 0xad41d09c.
//
// Solidity: function WITHDRAWAL_MIN_GAS() view returns(uint32)
func (_FeeDisburser *FeeDisburserCaller) WITHDRAWALMINGAS(opts *bind.CallOpts) (uint32, error) {
	var out []interface{}
	err := _FeeDisburser.contract.Call(opts, &out, "WITHDRAWAL_MIN_GAS")

	if err != nil {
		return *new(uint32), err
	}

	out0 := *abi.ConvertType(out[0], new(uint32)).(*uint32)

	return out0, err

}

// WITHDRAWALMINGAS is a free data retrieval call binding the contract method 0xad41d09c.
//
// Solidity: function WITHDRAWAL_MIN_GAS() view returns(uint32)
func (_FeeDisburser *FeeDisburserSession) WITHDRAWALMINGAS() (uint32, error) {
	return _FeeDisburser.Contract.WITHDRAWALMINGAS(&_FeeDisburser.CallOpts)
}

// WITHDRAWALMINGAS is a free data retrieval call binding the contract method 0xad41d09c.
//
// Solidity: function WITHDRAWAL_MIN_GAS() view returns(uint32)
func (_FeeDisburser *FeeDisburserCallerSession) WITHDRAWALMINGAS() (uint32, error) {
	return _FeeDisburser.Contract.WITHDRAWALMINGAS(&_FeeDisburser.CallOpts)
}

// LastDisbursementTime is a free data retrieval call binding the contract method 0x394d2731.
//
// Solidity: function lastDisbursementTime() view returns(uint256)
func (_FeeDisburser *FeeDisburserCaller) LastDisbursementTime(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _FeeDisburser.contract.Call(opts, &out, "lastDisbursementTime")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// LastDisbursementTime is a free data retrieval call binding the contract method 0x394d2731.
//
// Solidity: function lastDisbursementTime() view returns(uint256)
func (_FeeDisburser *FeeDisburserSession) LastDisbursementTime() (*big.Int, error) {
	return _FeeDisburser.Contract.LastDisbursementTime(&_FeeDisburser.CallOpts)
}

// LastDisbursementTime is a free data retrieval call binding the contract method 0x394d2731.
//
// Solidity: function lastDisbursementTime() view returns(uint256)
func (_FeeDisburser *FeeDisburserCallerSession) LastDisbursementTime() (*big.Int, error) {
	return _FeeDisburser.Contract.LastDisbursementTime(&_FeeDisburser.CallOpts)
}

// NetFeeRevenue is a free data retrieval call binding the contract method 0x447eb5ac.
//
// Solidity: function netFeeRevenue() view returns(uint256)
func (_FeeDisburser *FeeDisburserCaller) NetFeeRevenue(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _FeeDisburser.contract.Call(opts, &out, "netFeeRevenue")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// NetFeeRevenue is a free data retrieval call binding the contract method 0x447eb5ac.
//
// Solidity: function netFeeRevenue() view returns(uint256)
func (_FeeDisburser *FeeDisburserSession) NetFeeRevenue() (*big.Int, error) {
	return _FeeDisburser.Contract.NetFeeRevenue(&_FeeDisburser.CallOpts)
}

// NetFeeRevenue is a free data retrieval call binding the contract method 0x447eb5ac.
//
// Solidity: function netFeeRevenue() view returns(uint256)
func (_FeeDisburser *FeeDisburserCallerSession) NetFeeRevenue() (*big.Int, error) {
	return _FeeDisburser.Contract.NetFeeRevenue(&_FeeDisburser.CallOpts)
}

// DisburseFees is a paid mutator transaction binding the contract method 0xb87ea8d4.
//
// Solidity: function disburseFees() returns()
func (_FeeDisburser *FeeDisburserTransactor) DisburseFees(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _FeeDisburser.contract.Transact(opts, "disburseFees")
}

// DisburseFees is a paid mutator transaction binding the contract method 0xb87ea8d4.
//
// Solidity: function disburseFees() returns()
func (_FeeDisburser *FeeDisburserSession) DisburseFees() (*types.Transaction, error) {
	return _FeeDisburser.Contract.DisburseFees(&_FeeDisburser.TransactOpts)
}

// DisburseFees is a paid mutator transaction binding the contract method 0xb87ea8d4.
//
// Solidity: function disburseFees() returns()
func (_FeeDisburser *FeeDisburserTransactorSession) DisburseFees() (*types.Transaction, error) {
	return _FeeDisburser.Contract.DisburseFees(&_FeeDisburser.TransactOpts)
}

// Receive is a paid mutator transaction binding the contract receive function.
//
// Solidity: receive() payable returns()
func (_FeeDisburser *FeeDisburserTransactor) Receive(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _FeeDisburser.contract.RawTransact(opts, nil) // calldata is disallowed for receive function
}

// Receive is a paid mutator transaction binding the contract receive function.
//
// Solidity: receive() payable returns()
func (_FeeDisburser *FeeDisburserSession) Receive() (*types.Transaction, error) {
	return _FeeDisburser.Contract.Receive(&_FeeDisburser.TransactOpts)
}

// Receive is a paid mutator transaction binding the contract receive function.
//
// Solidity: receive() payable returns()
func (_FeeDisburser *FeeDisburserTransactorSession) Receive() (*types.Transaction, error) {
	return _FeeDisburser.Contract.Receive(&_FeeDisburser.TransactOpts)
}

// FeeDisburserFeesDisbursedIterator is returned from FilterFeesDisbursed and is used to iterate over the raw logs and unpacked data for FeesDisbursed events raised by the FeeDisburser contract.
type FeeDisburserFeesDisbursedIterator struct {
	Event *FeeDisburserFeesDisbursed // Event containing the contract specifics and raw log

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
func (it *FeeDisburserFeesDisbursedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(FeeDisburserFeesDisbursed)
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
		it.Event = new(FeeDisburserFeesDisbursed)
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
func (it *FeeDisburserFeesDisbursedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *FeeDisburserFeesDisbursedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// FeeDisburserFeesDisbursed represents a FeesDisbursed event raised by the FeeDisburser contract.
type FeeDisburserFeesDisbursed struct {
	DisbursementTime   *big.Int
	PaidToOptimism     *big.Int
	TotalFeesDisbursed *big.Int
	Raw                types.Log // Blockchain specific contextual infos
}

// FilterFeesDisbursed is a free log retrieval operation binding the contract event 0xe155e054cfe69655d6d2f8bbfb856aa8cdf49ecbea6557901533364539caad94.
//
// Solidity: event FeesDisbursed(uint256 _disbursementTime, uint256 _paidToOptimism, uint256 _totalFeesDisbursed)
func (_FeeDisburser *FeeDisburserFilterer) FilterFeesDisbursed(opts *bind.FilterOpts) (*FeeDisburserFeesDisbursedIterator, error) {

	logs, sub, err := _FeeDisburser.contract.FilterLogs(opts, "FeesDisbursed")
	if err != nil {
		return nil, err
	}
	return &FeeDisburserFeesDisbursedIterator{contract: _FeeDisburser.contract, event: "FeesDisbursed", logs: logs, sub: sub}, nil
}

// WatchFeesDisbursed is a free log subscription operation binding the contract event 0xe155e054cfe69655d6d2f8bbfb856aa8cdf49ecbea6557901533364539caad94.
//
// Solidity: event FeesDisbursed(uint256 _disbursementTime, uint256 _paidToOptimism, uint256 _totalFeesDisbursed)
func (_FeeDisburser *FeeDisburserFilterer) WatchFeesDisbursed(opts *bind.WatchOpts, sink chan<- *FeeDisburserFeesDisbursed) (event.Subscription, error) {

	logs, sub, err := _FeeDisburser.contract.WatchLogs(opts, "FeesDisbursed")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(FeeDisburserFeesDisbursed)
				if err := _FeeDisburser.contract.UnpackLog(event, "FeesDisbursed", log); err != nil {
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

// ParseFeesDisbursed is a log parse operation binding the contract event 0xe155e054cfe69655d6d2f8bbfb856aa8cdf49ecbea6557901533364539caad94.
//
// Solidity: event FeesDisbursed(uint256 _disbursementTime, uint256 _paidToOptimism, uint256 _totalFeesDisbursed)
func (_FeeDisburser *FeeDisburserFilterer) ParseFeesDisbursed(log types.Log) (*FeeDisburserFeesDisbursed, error) {
	event := new(FeeDisburserFeesDisbursed)
	if err := _FeeDisburser.contract.UnpackLog(event, "FeesDisbursed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// FeeDisburserFeesReceivedIterator is returned from FilterFeesReceived and is used to iterate over the raw logs and unpacked data for FeesReceived events raised by the FeeDisburser contract.
type FeeDisburserFeesReceivedIterator struct {
	Event *FeeDisburserFeesReceived // Event containing the contract specifics and raw log

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
func (it *FeeDisburserFeesReceivedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(FeeDisburserFeesReceived)
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
		it.Event = new(FeeDisburserFeesReceived)
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
func (it *FeeDisburserFeesReceivedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *FeeDisburserFeesReceivedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// FeeDisburserFeesReceived represents a FeesReceived event raised by the FeeDisburser contract.
type FeeDisburserFeesReceived struct {
	Sender common.Address
	Amount *big.Int
	Raw    types.Log // Blockchain specific contextual infos
}

// FilterFeesReceived is a free log retrieval operation binding the contract event 0x2ccfc58c2cef4ee590b5f16be0548cc54afc12e1c66a67b362b7d640fd16bb2d.
//
// Solidity: event FeesReceived(address indexed _sender, uint256 _amount)
func (_FeeDisburser *FeeDisburserFilterer) FilterFeesReceived(opts *bind.FilterOpts, _sender []common.Address) (*FeeDisburserFeesReceivedIterator, error) {

	var _senderRule []interface{}
	for _, _senderItem := range _sender {
		_senderRule = append(_senderRule, _senderItem)
	}

	logs, sub, err := _FeeDisburser.contract.FilterLogs(opts, "FeesReceived", _senderRule)
	if err != nil {
		return nil, err
	}
	return &FeeDisburserFeesReceivedIterator{contract: _FeeDisburser.contract, event: "FeesReceived", logs: logs, sub: sub}, nil
}

// WatchFeesReceived is a free log subscription operation binding the contract event 0x2ccfc58c2cef4ee590b5f16be0548cc54afc12e1c66a67b362b7d640fd16bb2d.
//
// Solidity: event FeesReceived(address indexed _sender, uint256 _amount)
func (_FeeDisburser *FeeDisburserFilterer) WatchFeesReceived(opts *bind.WatchOpts, sink chan<- *FeeDisburserFeesReceived, _sender []common.Address) (event.Subscription, error) {

	var _senderRule []interface{}
	for _, _senderItem := range _sender {
		_senderRule = append(_senderRule, _senderItem)
	}

	logs, sub, err := _FeeDisburser.contract.WatchLogs(opts, "FeesReceived", _senderRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(FeeDisburserFeesReceived)
				if err := _FeeDisburser.contract.UnpackLog(event, "FeesReceived", log); err != nil {
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

// ParseFeesReceived is a log parse operation binding the contract event 0x2ccfc58c2cef4ee590b5f16be0548cc54afc12e1c66a67b362b7d640fd16bb2d.
//
// Solidity: event FeesReceived(address indexed _sender, uint256 _amount)
func (_FeeDisburser *FeeDisburserFilterer) ParseFeesReceived(log types.Log) (*FeeDisburserFeesReceived, error) {
	event := new(FeeDisburserFeesReceived)
	if err := _FeeDisburser.contract.UnpackLog(event, "FeesReceived", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// FeeDisburserNoFeesCollectedIterator is returned from FilterNoFeesCollected and is used to iterate over the raw logs and unpacked data for NoFeesCollected events raised by the FeeDisburser contract.
type FeeDisburserNoFeesCollectedIterator struct {
	Event *FeeDisburserNoFeesCollected // Event containing the contract specifics and raw log

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
func (it *FeeDisburserNoFeesCollectedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(FeeDisburserNoFeesCollected)
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
		it.Event = new(FeeDisburserNoFeesCollected)
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
func (it *FeeDisburserNoFeesCollectedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *FeeDisburserNoFeesCollectedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// FeeDisburserNoFeesCollected represents a NoFeesCollected event raised by the FeeDisburser contract.
type FeeDisburserNoFeesCollected struct {
	Raw types.Log // Blockchain specific contextual infos
}

// FilterNoFeesCollected is a free log retrieval operation binding the contract event 0x8c887b1215d5e6b119c1c1008fe1d0919b4c438301d5a0357362a13fb56f6a40.
//
// Solidity: event NoFeesCollected()
func (_FeeDisburser *FeeDisburserFilterer) FilterNoFeesCollected(opts *bind.FilterOpts) (*FeeDisburserNoFeesCollectedIterator, error) {

	logs, sub, err := _FeeDisburser.contract.FilterLogs(opts, "NoFeesCollected")
	if err != nil {
		return nil, err
	}
	return &FeeDisburserNoFeesCollectedIterator{contract: _FeeDisburser.contract, event: "NoFeesCollected", logs: logs, sub: sub}, nil
}

// WatchNoFeesCollected is a free log subscription operation binding the contract event 0x8c887b1215d5e6b119c1c1008fe1d0919b4c438301d5a0357362a13fb56f6a40.
//
// Solidity: event NoFeesCollected()
func (_FeeDisburser *FeeDisburserFilterer) WatchNoFeesCollected(opts *bind.WatchOpts, sink chan<- *FeeDisburserNoFeesCollected) (event.Subscription, error) {

	logs, sub, err := _FeeDisburser.contract.WatchLogs(opts, "NoFeesCollected")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(FeeDisburserNoFeesCollected)
				if err := _FeeDisburser.contract.UnpackLog(event, "NoFeesCollected", log); err != nil {
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

// ParseNoFeesCollected is a log parse operation binding the contract event 0x8c887b1215d5e6b119c1c1008fe1d0919b4c438301d5a0357362a13fb56f6a40.
//
// Solidity: event NoFeesCollected()
func (_FeeDisburser *FeeDisburserFilterer) ParseNoFeesCollected(log types.Log) (*FeeDisburserNoFeesCollected, error) {
	event := new(FeeDisburserNoFeesCollected)
	if err := _FeeDisburser.contract.UnpackLog(event, "NoFeesCollected", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
