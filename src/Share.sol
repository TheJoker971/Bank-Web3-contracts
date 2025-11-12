// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Share is ERC20 , Ownable{
   
    event OrderPlaced(uint256 orderId, address indexed user, uint256 amount, uint256 price, uint256 timestamp, bool isBuy);
    event ShareCreated(string name, string symbol,uint256 amount,uint256 price);
    event ShareBought(uint256 amount, uint256 price);
    event ShareSold(uint256 amount, uint256 price);

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
    uint256 public bestBid;
    uint256 public bestAsk;


    /**
     * @dev Constructor for the Share contract.
     * @param _name The name of the share.
     * @param _symbol The symbol of the share.
     * @param _maxSupply The maximum supply of the share.
     * @param _price The price of the share.
     */
    constructor(string memory _name, string memory _symbol, uint256 _maxSupply,uint256 _price) ERC20(_name,_symbol) Ownable(msg.sender) {
        MAX_SUPPLY = _maxSupply;
        price = _price;
        _mint(address(this),_maxSupply);
        emit ShareCreated(_name, _symbol, _maxSupply,_price);
    }

    /** 
     * @dev Buys the share.
     * @param amount The amount of share to buy.
     * @param _to The address to buy the share to.
     */
    function buy(uint256 amount, address _to) public onlyOwner {
        uint256 currentPrice = getPrice();
        uint256 totalPrice = amount * currentPrice;
        require(totalPrice <= availableSupply(), "Insufficient supply");
        _transfer(address(this),_to, amount);
        emit ShareBought(amount, currentPrice);
    }

    /**
     * @dev Sells the share.
     * @param amount The amount of share to sell.
     * @param _from The address to sell the share from.
     */
    function sell(uint256 amount, address _from) public onlyOwner {
        uint256 currentPrice = getPrice();
        uint256 totalPrice = amount * currentPrice;
        require(totalPrice <= availableSupply(), "Insufficient supply");
        _transfer(_from, address(this), amount);
        emit ShareSold(amount, currentPrice);
    }

    /**
     * @dev Places an order for the share.
     * @param amount The amount of share to buy or sell.
     * @param orderPrice The price of the share.
     * @param isBuy Whether the order is a buy order or a sell order.
     * @return The order ID.
     */
    function placeOrder(uint256 amount, uint256 orderPrice, bool isBuy) public returns(uint256){
        if(orderPrice > bestAsk){
            bestAsk = orderPrice;
        }
        if(orderPrice < bestBid){
            bestBid = orderPrice;
        }
        calculatePrice();
        ordersCount++;
        orderBook[ordersCount] = Order(amount, orderPrice, block.timestamp, msg.sender, isBuy);
        emit OrderPlaced(ordersCount, msg.sender, amount, orderPrice, block.timestamp, isBuy);
        return ordersCount;
    }
    
    /**
     * @dev Executes an order for the share.
     * @param orderId The ID of the order to execute.
     */
    function executeOrder(uint256 orderId) public {
        Order memory order = orderBook[orderId];
        calculatePrice();
        require(price == order.price, "Price mismatch");
        if(order.isBuy){
            buy(order.amount, order.user);
        } else {
            sell(order.amount, order.user);
        }
    }

    /**
     * @dev Returns the price of the share.
     * @return The price of the share.
     */
    function getPrice() public view returns (uint256) {
        return price;
    }

    /**
     * @dev Returns the maximum supply of the share.
     * @return The maximum supply of the share.
     */
    function maxSupply() public view returns(uint256) {
        return MAX_SUPPLY;
    }

    /**
     * @dev Returns all orders from the order book.
     * @return The array of all orders.
     */
    function getAllOrders() public view returns (Order[] memory) {
        Order[] memory orders = new Order[](ordersCount);
        for (uint256 i = 1; i <= ordersCount; i++) {
            orders[i-1] = orderBook[i];
        }
        return orders;
    }

    /**
     * @dev Returns the available supply of the share.
     * @return The available supply of the share.
     */
    function availableSupply() public view returns (uint256) {
        return balanceOf(address(this));
    }    

    /**
     * @dev Returns the total supply of the share.
     * @return The total supply of the share.
     */
    function totalSupply() public view override returns (uint256) {
        return MAX_SUPPLY - balanceOf(address(this));
    }

    /**
     * @dev Calculates the price of the share based on the lower and higher prices.
     */
    function calculatePrice() internal {
        price = (bestBid + bestAsk) / 2;
    }
}