// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Share is ERC20, Ownable {
   
    error InsufficientSupply(uint256 requested, uint256 available);
    error PriceMismatch(uint256 expected, uint256 actual);

    event OrderPlaced(uint256 orderId, address indexed user, uint256 amount, uint256 price, uint256 timestamp, bool isBuy);
    event ShareCreated(string name, string symbol, uint256 amount, uint256 price);
    event ShareBought(uint256 amount, uint256 price);
    event ShareSold(uint256 amount, uint256 price);

    struct Order {
        uint256 amount;
        uint256 price;
        uint256 timestamp;
        bool isBuy;
    }

    uint256 public immutable MAX_SUPPLY;
    uint256 public ordersCount;
    ERC20 public euro;
    mapping(uint256 => Order) private orderBook;
    mapping(uint256 => address) private orderUsers;

    /**
     * @dev Constructor for the Share contract.
     * @param _name The name of the share.
     * @param _symbol The symbol of the share.
     * @param _maxSupply The maximum supply of the share.
     * @param _price The initial price of the share (for event purposes only).
     */
    constructor(string memory _name, string memory _symbol, uint256 _maxSupply, uint256 _price, address _euro) ERC20(_name, _symbol) Ownable(msg.sender) {
        MAX_SUPPLY = _maxSupply;
        euro = ERC20(_euro);
        _mint(address(this), _maxSupply);
        emit ShareCreated(_name, _symbol, _maxSupply, _price);
    }

    /** 
     * @dev Buys the share.
     * @param amount The amount of share to buy.
     * @param _to The address to buy the share to.
     * @param _price The price of the share at the time of purchase.
     */
    function buy(uint256 amount, address _to, uint256 _price) public onlyOwner returns (bool) {
        _transfer(address(this), _to, amount);
        emit ShareBought(amount, _price);
        return true;
    }

    /**
     * @dev Sells the share.
     * @param amount The amount of share to sell.
     * @param _from The address to sell the share from.
     * @param _price The price of the share at the time of sale.
     */
    function sell(uint256 amount, address _from, uint256 _price) public onlyOwner returns (bool) {
        euro.transfer(_from, amount * _price);
        _transfer(_from, address(this), amount);
        emit ShareSold(amount, _price);
        return true;
    }

    /**
     * @dev Places an order for the share.
     * @param amount The amount of share to buy or sell.
     * @param orderPrice The price of the share.
     * @param isBuy Whether the order is a buy order or a sell order.
     * @param sender The address placing the order.
     * @return The order ID.
     */
    function placeOrder(uint256 amount, uint256 orderPrice, bool isBuy, address sender) external onlyOwner returns (uint256) {
        orderBook[ordersCount] = Order(amount, orderPrice, block.timestamp, isBuy);
        orderUsers[ordersCount] = sender;
        emit OrderPlaced(ordersCount, sender, amount, orderPrice, block.timestamp, isBuy);
        ordersCount++;
        return ordersCount - 1;
    }
    
    /**
     * @dev Executes an order for the share.
     * @param orderId The ID of the order to execute.
     * @param currentPrice The current price to verify against the order price.
     */
    function executeOrder(uint256 orderId, uint256 currentPrice) external onlyOwner returns (bool) {
        Order memory order = orderBook[orderId];
        address user = orderUsers[orderId];
        require(currentPrice == order.price, PriceMismatch(order.price, currentPrice));
        if (order.isBuy) {
            return buy(order.amount, user, currentPrice);
        } else {
            return sell(order.amount, user, currentPrice);
        }
    }

    /**
     * @dev Returns the details of an order.
     * @param orderId The ID of the order.
     * @return The order details.
     */
    function getOrder(uint256 orderId) external onlyOwner view returns (Order memory) {
        return orderBook[orderId];
    }

    /**
     * @dev Returns all orders from the order book.
     * @return The array of all orders.
     */
    function getAllOrders() external view returns (Order[] memory) {
        Order[] memory orders = new Order[](ordersCount);
        for (uint256 i = 0; i < ordersCount; i++) {
            orders[i] = orderBook[i];
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

    function balance() external view returns (uint256) {
        return euro.balanceOf(address(this));
    }
}