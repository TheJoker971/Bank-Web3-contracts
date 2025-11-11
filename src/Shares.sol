// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {ERC20Upgradeable} from "@openzeppelin/contracts/token/ERC20/ERC20Upgradeable.sol";

contract Shares is ERC20Upgradeable {
   
    event OrderPlaced(uint256 orderId, address user, uint256 amount, uint256 price, uint256 timestamp, bool isBuy);
    event SharesCreated(string name, string symbol,uint256 amount,uint256 prices);
    event SharesBought(uint256 amount, uint256 price);
    event SharesSold(uint256 amount, uint256 price);

    struct Order {
        uint256 amount;
        uint256 price;
        uint256 timestamp;
        address user;
        bool isBuy;
    }
    uint256 private immutable  MAX_SUPPLY;
    uint256 public ordersCount;
    mapping(uint256 orderId => Order order) public orderBook;
    uint256 public price;
    uint256 public lowerPrice;
    uint256 public higherPrice;


    /**
     * @dev Constructor for the Shares contract.
     * @param _name The name of the shares.
     * @param _symbol The symbol of the shares.
     * @param _maxSupply The maximum supply of the shares.
     * @param _price The price of the shares.
     */
    constructor(string _name, string _symbol, uint256 _maxSupply,uint256 _price) ERC20Upgradeable(_name,_symbol) {
        this.MAX_SUPPLY = _maxSupply;
        this.price = _price;
        _mint(address(this),_maxSupply);
        emit SharesCreated(_name, _symbol, _maxSupply,_price);
    }

    /** 
     * @dev Buys the shares.
     * @param amount The amount of shares to buy.
     */
    function buy(uint256 amount) public {
        uint256 price = getPrice();
        uint256 totalPrice = amount * price;
        require(totalPrice <= availableSupply(), "Insufficient supply");
        _transfer(address(this), msg.sender, amount);
        emit SharesBought(amount, price);
    }

    /**
     * @dev Sells the shares.
     * @param amount The amount of shares to sell.
     */
    function sell(uint256 amount) public {
        uint256 price = getPrice();
        uint256 totalPrice = amount * price;
        require(totalPrice <= availableSupply(), "Insufficient supply");
        _transfer(msg.sender, address(this), amount);
        emit SharesSold(amount, price);
    }

    /**
     * @dev Places an order for the shares.
     * @param amount The amount of shares to buy or sell.
     * @param price The price of the shares.
     * @param isBuy Whether the order is a buy order or a sell order.
     * @return The order ID.
     */
    function placeOrder(uint256 amount, uint256 price, bool isBuy) public returns(uint256){
        if(price > this.higher){
            this.higherPrice = price;
        }
        if(price < this.lowerPrice){
            this.lowerPrice = price;
        }
        calculatePrice();
        ordersCount++;
        orderBook[ordersCount] = Order(amount, price, block.timestamp, msg.sender, isBuy, false, false, false, false);
        emit OrderPlaced(ordersCount, msg.sender, amount, price, block.timestamp, isBuy);
        return ordersCount;
    }
    
    /**
     * @dev Executes an order for the shares.
     * @param orderId The ID of the order to execute.
     */
    function executeOrder(uint256 orderId) public {
        Order memory order = orderBook[orderId];
        calculatePrice();
        require(this.price == order.price, "Price mismatch");
        if(order.isBuy){
            buy(order.amount);
        } else {
            sell(order.amount);
        }
    }

    /**
     * @dev Returns the price of the shares.
     * @return The price of the shares.
     */
    function getPrice() public view returns (uint256) {
        return this.price;
    }

    /**
     * @dev Returns the maximum supply of the shares.
     * @return The maximum supply of the shares.
     */
    function maxSupply() public view returns(uint256) {
        return this.MAX_SUPPLY;
    }

    /**
     * @dev Returns the order book.
     * @return The order book.
     */
    function orderBook() public view returns (Order[] memory) {
        Order[] memory orders = new Order[](ordersCount);
        for (uint256 i = 0; i < ordersCount; i++) {
            orders[i] = orderBook[i];
        }
        return orders;
    }

    /**
     * @dev Returns the available supply of the shares.
     * @return The available supply of the shares.
     */
    function availableSupply() public view returns (uint256) {
        return balanceOf(address(this));
    }    

    /**
     * @dev Returns the total supply of the shares.
     * @return The total supply of the shares.
     */
    function totalSupply() public view override returns (uint256) {
        return this.MAX_SUPPLY - balanceOf(address(this));
    }

    /**
     * @dev Calculates the price of the shares based on the lower and higher prices.
     * @return The price of the shares.
     */
    function calculatePrice() internal {
        this.price = (this.lowerPrice + this.higherPrice) / 2;
    }
}