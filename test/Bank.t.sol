// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Test} from "forge-std/Test.sol";
import {Bank} from "../src/Bank.sol";
import {Account} from "../src/Account.sol";
import {Euro} from "../src/Euro.sol";
import {Share} from "../src/Share.sol";

contract BankTest is Test {
    Bank bank;
    Euro euro;
    Share share;

    function setUp() public {
        bank = new Bank("Test Bank");
        euro = bank.euroToken();
        share = new Share("Test Share", "TSH", 1000 ether, 1 ether, address(euro));
    }

    function testConstrutor() public view {
        assertEq(bank.bankName(), "Test Bank");
        assert(address(bank.euroToken()) != address(0));
        assertEq(bank.euroToken().totalSupply(), 1_000_000_000_000 ether);
        assertEq(bank.getBalanceOfAccount(address(bank)),1_000_000_000_000 ether);
    }

    function testCreateAccount() public {
        address accountAddress = bank.createAccount("John", "Doe", 123456);
        assert(accountAddress != address(0));
    }

    function testGetAccount() public {
        address account = bank.createAccount("Jane", "Doe", 654321);
        address accountAddress = bank.getAccount("Jane", "Doe", 654321);
        assert(accountAddress != address(0));
        assertEq(account, accountAddress);
    }

    function testCreateDuplicateAccount() public {
        bank.createAccount("Alice", "Smith", 111111);
        vm.expectRevert(Bank.AccountAlreadyExists.selector);
        bank.createAccount("Alice", "Smith", 111111);
    }

    function testGetNonExistentAccount() public {
        vm.expectRevert(Bank.AccountDoesNotExist.selector);
        bank.getAccount("Bob", "Smith", 222222);
    }

    function testEuroMinting() public {
        address accountAddress = bank.createAccount("Charlie", "Brown", 333333);
        uint256 balance = euro.balanceOf(accountAddress);
        assertEq(balance, 1000 ether);
        assertEq(euro.totalSupply(), 1_000_000_001_000 ether);
        assertEq(bank.getBalanceOfAccount(accountAddress), 1000 ether);
    }

    function testShareCreation() public {
        bank.createShare("My Share", "MSH", 5000 ether, 2 ether);
        Share createdShare = bank.getShareAddress("My Share", "MSH");
        assert(address(createdShare) != address(0));
        assertEq(createdShare.totalSupply(), 0);
    }

    function testGetNonExistentShare() public {
        vm.expectRevert(abi.encodeWithSelector(Bank.ShareDoesNotExist.selector, "NonExistent", "NES"));
        bank.getShareAddress("NonExistent", "NES");
    }

    function testGetBalanceOfAccount() public {
        address accountAddress = bank.createAccount("Diana", "Prince", 777777);
        uint256 balance = bank.getBalanceOfAccount(accountAddress);
        assertEq(balance, 1000 ether);
        vm.expectRevert(Bank.AccountDoesNotExist.selector);
        bank.getBalanceOfAccount(address(0));
    }

    function testCreateShareAndCheckSupply() public {
        bank.createShare("Another Share", "ASH", 2000 ether, 3 ether);
        Share anotherShare = bank.getShareAddress("Another Share", "ASH");
        assertEq(anotherShare.availableSupply(), 2000 ether);
        assertEq(anotherShare.totalSupply(), 0);
    }

    function testTransferMoneyAccount() public {
        address accountAddress = bank.createAccount("Daisy", "Johnson", 444444);
        uint256 initialBalance = euro.balanceOf(accountAddress);
        assertEq(initialBalance, 1000 ether);

        bank.transferMoneyToAccount(accountAddress,address(1), 100 ether);
        uint256 finalBalance = euro.balanceOf(accountAddress);
        assertEq(finalBalance, 900 ether);
    }

    function testTransferMoneyAccountInsufficientFunds() public {
        address accountAddress = bank.createAccount("Ethan", "Hunt", 555555);
        vm.expectRevert();
        bank.transferMoneyToAccount(accountAddress, address(1), 2000 ether);
    }

    function testCreateShareDuplicate() public {
        bank.createShare("Unique Share", "USH", 3000 ether, 4 ether);
        vm.expectRevert(abi.encodeWithSelector(Bank.ShareAlreadyExists.selector, "Unique Share", "USH"));
        bank.createShare("Unique Share", "USH", 3000 ether, 4 ether);
    }

    function testPlaceOrderAndExecute() public {
        address account = bank.createAccount("Frank", "Castle", 666666);
        bank.createShare("Trade Share", "TSH", 1000 ether, 1 ether);
        uint256 orderId = bank.placeOrderOnShare("Trade Share", "TSH", 100 ether, 1 ether, true, account);
        assertEq(orderId, 0);

        bool executed = bank.executeOrderOnShare("Trade Share", "TSH", orderId, 1 ether);
        assert(executed);
    }

    function testPlaceOrderOnNonExistentShare() public {
        vm.expectRevert(abi.encodeWithSelector(Bank.ShareDoesNotExist.selector, "Fake Share", "FSH"));
        bank.placeOrderOnShare("Fake Share", "FSH", 50 ether, 1 ether, true, address(0));
    }

    function testExecuteOrderOnNonExistentShare() public {
        vm.expectRevert(abi.encodeWithSelector(Bank.ShareDoesNotExist.selector, "Fake Share", "FSH"));
        bank.executeOrderOnShare("Fake Share", "FSH", 0, 1 ether);
    }

    function testBuyShare() public {
        address account = bank.createAccount("Grace", "Hopper", 777777);
        bank.createShare("Market Share", "MSH", 1000 ether, 1 ether);
        address shareAddress = address(bank.getShareAddress("Market Share", "MSH"));
        bool buySuccess = bank.buyShare("Market Share", "MSH", 10 ether, account);
        assert(buySuccess);
        assertEq(bank.getBalanceOfAccount(account), 1000 ether - 10 ether);
        assertEq(bank.getBalanceOfAccount(shareAddress), 10 ether);
        vm.expectRevert();
        bank.buyShare("Market Share", "MSH", 2000 ether, account);
        vm.expectRevert(abi.encodeWithSelector(Bank.ShareDoesNotExist.selector, "Unknown Share", "USH"));
        bank.buyShare("Unknown Share", "USH", 10 ether, account);
    }

    function testSellShare() public {
        address account = bank.createAccount("Hank", "Pym", 888888);
        bank.createShare("Sellable Share", "SSH", 1000 ether, 1 ether);
        address shareAddress = address(bank.getShareAddress("Sellable Share", "SSH"));
        bank.buyShare("Sellable Share", "SSH", 20 ether, account);
        assertEq(bank.getBalanceOfAccount(account), 1000 ether - 20 ether);
        bool sellSuccess = bank.sellShare("Sellable Share", "SSH", 10 ether, account);
        assert(sellSuccess);
        assertEq(bank.getBalanceOfAccount(shareAddress), 10 ether);
        assertEq(bank.getBalanceOfAccount(account), 1000 ether - 10 ether);
        vm.expectRevert();
        bank.sellShare("Sellable Share", "SSH", 2000 ether, account);
        vm.expectRevert(abi.encodeWithSelector(Bank.ShareDoesNotExist.selector, "NonSellable", "NSS"));
        bank.sellShare("NonSellable", "NSS", 10 ether, account);
    }

    function testGetOrderOnShare() public {
        address account = bank.createAccount("Ivy", "Pepper", 999999);
        bank.createShare("Order Share", "OSH", 1000 ether, 1 ether);
        uint256 orderId = bank.placeOrderOnShare("Order Share", "OSH", 50 ether, 1 ether, true, account);
        Share.Order memory order = bank.getOrderOnShare("Order Share", "OSH", orderId);
        assertEq(order.amount, 50 ether);
        assertEq(order.price, 1 ether);
        assert(order.isBuy);
        vm.expectRevert(abi.encodeWithSelector(Bank.ShareDoesNotExist.selector, "Ghost Share", "GSH"));
        bank.getOrderOnShare("Ghost Share", "GSH", 0);
        vm.expectRevert(abi.encodeWithSelector(Share.OrderDoesNotExist.selector, 1));
        bank.getOrderOnShare("Order Share", "OSH", 1);
    }
    
}