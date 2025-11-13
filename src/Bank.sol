// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Euro} from "./Euro.sol";
import {Account} from "./Account.sol";
import {Share} from "./Share.sol";
import {Staking} from "./Staking.sol";

contract Bank is Ownable {
    error StakingDoesNotExist(string name);

    error AccountAlreadyExists();
    error AccountDoesNotExist();
    error ShareDoesNotExist(string name, string symbol);
    error ShareAlreadyExists(string name, string symbol);

    event BankCreated(string bankName);
    event AccountCreated();
    event MoneyTransferred(address indexed fromAccount, address indexed to, uint256 amount);
    event ShareCreated(string indexed name, string indexed symbol, uint256 initialSupply);

    event StakingCreated(string indexed name, uint256 interestRate);

    string public bankName;
    Euro public euroToken;

    mapping(string name => mapping(string symbol => Share)) private shares;

    mapping(bytes32 hashCode => Account) private accounts;

    mapping(string name => Staking) private stakings;

    /**
     * @dev Constructor for the Bank contract.
     * @param _bankName The name of the bank.
     */
    constructor(string memory _bankName) Ownable(msg.sender) {
        bankName = _bankName;
        euroToken = new Euro("Euro Token", "EUR");
        emit BankCreated(_bankName);
    }

    /**
     * @dev Creates a new account.
     * @param _firstname The first name of the account holder.
     * @param _lastname The last name of the account holder.
     * @param _numberAccount The account number.
     * @return The address of the newly created account.
     */
    function createAccount(string memory _firstname, string memory _lastname, uint256 _numberAccount)
        external
        onlyOwner
        returns (address)
    {
        bytes32 hashCode = getHashCode(_firstname, _lastname, _numberAccount);
        require(address(accounts[hashCode]) == address(0), AccountAlreadyExists());
        Account newAccount = new Account(euroToken);
        accounts[hashCode] = newAccount;
        euroToken.mint(address(newAccount), 1000 ether);
        emit AccountCreated();
        return address(newAccount);
    }

    /**
     * @dev Retrieves the address of an account.
     * @param _firstname The first name of the account holder.
     * @param _lastname The last name of the account holder.
     * @param _numberAccount The account number.
     * @return The address of the account.
     */
    function getAccount(string memory _firstname, string memory _lastname, uint256 _numberAccount)
        external
        view
        onlyOwner
        returns (address)
    {
        bytes32 hashCode = getHashCode(_firstname, _lastname, _numberAccount);
        Account account = accounts[hashCode];
        require(address(account) != address(0), AccountDoesNotExist());
        return address(account);
    }

    /**
     * @dev Retrieves the balance of an account.
     * @param _account The address of the account.
     * @return The balance of the account.
     */
    function getBalanceOfAccount(address _account) external view onlyOwner returns (uint256) {
        require(address(_account) != address(0), AccountDoesNotExist());
        return euroToken.balanceOf(address(_account));
    }

    /**
     * @dev Transfers money from one account to another.
     * @param _from The address of the account to transfer money from.
     * @param _to The address of the account to transfer money to.
     * @param _amount The amount of money to transfer.
     * @return A boolean indicating whether the transfer was successful.
     */
    function transferMoneyToAccount(address _from, address _to, uint256 _amount) external onlyOwner returns (bool) {
        bool success = Account(_from).transfer(_to, _amount);
        emit MoneyTransferred(_from, _to, _amount);
        return success;
    }

    /**
     * @dev Creates a new share.
     * @param _name The name of the share.
     * @param _symbol The symbol of the share.
     * @param _initialSupply The initial supply of the share.
     * @param _price The price of the share.
     */
    function createShare(string memory _name, string memory _symbol, uint256 _initialSupply, uint256 _price)
        external
        onlyOwner
    {
        require(address(shares[_name][_symbol]) == address(0), ShareAlreadyExists(_name, _symbol));
        Share newShare = new Share(_name, _symbol, _initialSupply, _price, address(euroToken));
        shares[_name][_symbol] = newShare;
        emit ShareCreated(_name, _symbol, _initialSupply);
    }

    /**
     * @dev Retrieves the address of a share.
     * @param _name The name of the share.
     * @param _symbol The symbol of the share.
     * @return The address of the share.
     */
    function getShareAddress(string memory _name, string memory _symbol) external view onlyOwner returns (Share) {
        Share share = shares[_name][_symbol];
        require(address(share) != address(0), ShareDoesNotExist(_name, _symbol));
        return share;
    }

    function getOrderOnShare(string memory _name, string memory _symbol, uint256 orderId)
        external
        view
        onlyOwner
        returns (Share.Order memory)
    {
        require(address(shares[_name][_symbol]) != address(0), ShareDoesNotExist(_name, _symbol));
        Share share = shares[_name][_symbol];
        return share.getOrder(orderId);
    }

    /**
     * @dev Places an order on a share.
     * @param _name The name of the share.
     * @param _symbol The symbol of the share.
     * @param amount The amount of share to buy or sell.
     * @param orderPrice The price of the share.
     * @param isBuy Whether the order is a buy order or a sell order.
     * @param _from The address placing the order.
     * @return The order ID.
     */
    function placeOrderOnShare(
        string memory _name,
        string memory _symbol,
        uint256 amount,
        uint256 orderPrice,
        bool isBuy,
        address _from
    ) external onlyOwner returns (uint256) {
        require(address(shares[_name][_symbol]) != address(0), ShareDoesNotExist(_name, _symbol));
        Share share = shares[_name][_symbol];
        return share.placeOrder(amount, orderPrice, isBuy, _from);
    }

    /**
     * @dev Buys a share.
     * @param _name The name of the share.
     * @param _symbol The symbol of the share.
     * @param amount The amount of share to buy.
     * @param _to The address to buy the share to.
     * @return A boolean indicating whether the purchase was successful.
     */
    function buyShare(string memory _name, string memory _symbol, uint256 amount, address _to)
        external
        onlyOwner
        returns (bool)
    {
        require(address(shares[_name][_symbol]) != address(0), ShareDoesNotExist(_name, _symbol));
        Share share = shares[_name][_symbol];
        uint256 totalCost = amount * share.price() / 1 ether;
        approveBank(_to, totalCost);
        euroToken.transferFrom(_to, address(share), totalCost);
        return share.buy(amount, _to);
    }

    /**
     * @dev Sells a share.
     * @param _name The name of the share.
     * @param _symbol The symbol of the share.
     * @param amount The amount of share to sell.
     * @param _from The address to sell the share from.
     * @return A boolean indicating whether the sale was successful.
     */
    function sellShare(string memory _name, string memory _symbol, uint256 amount, address _from)
        external
        onlyOwner
        returns (bool)
    {
        require(address(shares[_name][_symbol]) != address(0), ShareDoesNotExist(_name, _symbol));
        Share share = shares[_name][_symbol];
        uint256 totalCost = amount * share.price() / 1 ether;
        approveBank(address(share), totalCost);
        return share.sell(amount, _from, totalCost);
    }

    /**
     * @dev Executes an order on a share.
     * @param _name The name of the share.
     * @param _symbol The symbol of the share.
     * @param orderId The ID of the order to execute.
     * @param executedPrice The price at which the order is executed.
     * @return A boolean indicating whether the execution was successful.
     */
    function executeOrderOnShare(string memory _name, string memory _symbol, uint256 orderId, uint256 executedPrice)
        external
        onlyOwner
        returns (bool)
    {
        require(address(shares[_name][_symbol]) != address(0), ShareDoesNotExist(_name, _symbol));
        Share share = shares[_name][_symbol];
        return share.executeOrder(orderId, executedPrice);
    }

    function createStaking(string memory _name, uint256 _interestRate) external onlyOwner {
        require(address(stakings[_name]) == address(0), "Staking already exists");
        Staking newStaking = new Staking(euroToken, _name, _interestRate);
        stakings[_name] = newStaking;
        emit StakingCreated(_name, _interestRate);
    }

    function depositToStaking(string memory _name, address _from, uint256 amount) external onlyOwner returns (bool) {
        require(address(stakings[_name]) != address(0), StakingDoesNotExist(_name));
        Staking staking = stakings[_name];
        approveBank(_from, amount);
        euroToken.transferFrom(_from, address(staking), amount);
        return staking.deposit(_from, amount);
    }

    function withdrawAllFromStaking(string memory _name, address to) external onlyOwner returns (bool) {
        require(address(stakings[_name]) != address(0), StakingDoesNotExist(_name));
        Staking staking = stakings[_name];
        return staking.withdrawAll(to);
    }

    function withdrawRewardFromStaking(string memory _name, address to) external onlyOwner returns (bool) {
        require(address(stakings[_name]) != address(0), StakingDoesNotExist(_name));
        Staking staking = stakings[_name];
        return staking.withdrawReward(to);
    }

    /**
     * @dev Approves the bank to spend euros on behalf of an account.
     * @param _from The address of the account.
     * @param amount The amount of euros to approve.
     * @return A boolean indicating whether the approval was successful.
     */
    function approveBank(address _from, uint256 amount) internal onlyOwner returns (bool) {
        return euroToken.approveFrom(_from, address(this), amount);
    }

    /**
     * @dev Retrieves the allowance of the bank to spend euros on behalf of an account.
     * @param _from The address of the account.
     * @return The allowance of the bank.
     */
    function allowanceBank(address _from) internal view onlyOwner returns (uint256) {
        return euroToken.allowance(_from, address(this));
    }

    /**
     * @dev Generates a hash code for an account based on the account holder's details.
     * @param _firstname The first name of the account holder.
     * @param _lastname The last name of the account holder.
     * @param _numberAccount The account number.
     * @return The generated hash code.
     */
    function getHashCode(string memory _firstname, string memory _lastname, uint256 _numberAccount)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_firstname, _lastname, _numberAccount));
    }
}
