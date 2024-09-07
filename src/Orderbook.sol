// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.27;

import "../lib/openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "./GamePositions.sol";

contract OrderBook {
    uint public orderIdCounter;

    enum OrderType { Buy, Sell }

    struct Order {
        uint id;
        address creator;
        OrderType orderType;
        string optionName;
        uint price; // Price in ERC20 tokens
        uint quantity;
        uint remainingQuantity; // Track remaining quantity for partial fills
        bool isFilled;
    }

    ERC20 public money;
    GamePositions public positions;
    mapping(uint => Order) public orders;
    mapping(address => uint[]) public userOrders; // User's list of order IDs

    event OrderPlaced(uint orderId, address indexed creator, OrderType orderType, string optionName, uint price, uint quantity);
    event OrderFilled(uint orderId, address indexed fulfiller, uint amountFilled, uint remainingQuantity, bool fullyFilled);
    event OrderCancelled(uint orderId, address indexed creator);

    constructor(ERC20 _money, GamePositions _positions) {
        money = _money;
        positions = _positions;
    }

    // Place a buy order
    function placeBuyOrder(string memory optionName, uint price, uint quantity) external {
        uint orderId = _createOrder(OrderType.Buy, optionName, price, quantity);
        emit OrderPlaced(orderId, msg.sender, OrderType.Buy, optionName, price, quantity);
    }

    // Place a sell order
    function placeSellOrder(string memory optionName, uint price, uint quantity) external {
        uint tokenId = positions.getTokenId(optionName);
        require(positions.balanceOf(msg.sender, tokenId) >= quantity, "Insufficient token balance");

        uint orderId = _createOrder(OrderType.Sell, optionName, price, quantity);
        emit OrderPlaced(orderId, msg.sender, OrderType.Sell, optionName, price, quantity);
    }

    // Fill an existing order with partial matching
    function fillOrder(uint orderId, uint amountToFill) external {
        Order storage order = orders[orderId];
        require(!order.isFilled, "Order is already filled");
        require(amountToFill > 0 && amountToFill <= order.remainingQuantity, "Invalid amount to fill");

        uint totalCost = order.price * amountToFill;

        if (order.orderType == OrderType.Sell) {
            // Fulfill a sell order
            require(money.balanceOf(msg.sender) >= totalCost, "Insufficient balance to buy");
            money.transferFrom(msg.sender, order.creator, totalCost);

            uint tokenId = positions.getTokenId(order.optionName);
            positions.safeTransferFrom(order.creator, msg.sender, tokenId, amountToFill, "");
        } else if (order.orderType == OrderType.Buy) {
            // Fulfill a buy order
            uint tokenId = positions.getTokenId(order.optionName);
            require(positions.balanceOf(msg.sender, tokenId) >= amountToFill, "Insufficient token balance");
            positions.safeTransferFrom(msg.sender, order.creator, tokenId, amountToFill, "");

            money.transferFrom(order.creator, msg.sender, totalCost);
        }

        order.remainingQuantity -= amountToFill;
        bool fullyFilled = order.remainingQuantity == 0;
        if (fullyFilled) {
            order.isFilled = true;
        }

        emit OrderFilled(orderId, msg.sender, amountToFill, order.remainingQuantity, fullyFilled);
    }

    // Cancel an existing order and return tokens
    function cancelOrder(uint orderId) external {
        Order storage order = orders[orderId];
        require(order.creator == msg.sender, "Only creator can cancel this order");
        require(!order.isFilled, "Order is already filled");

        if (order.orderType == OrderType.Sell) {
            // Return the remaining GamePositionToken1155 tokens to the creator
            uint tokenId = positions.getTokenId(order.optionName);
            positions.safeTransferFrom(address(this), order.creator, tokenId, order.remainingQuantity, "");
        } else if (order.orderType == OrderType.Buy) {
            // Return the remaining ERC20 tokens to the creator
            uint refundAmount = order.remainingQuantity * order.price;
            money.transfer(order.creator, refundAmount);
        }

        order.isFilled = true; // Mark order as filled to prevent future filling
        emit OrderCancelled(orderId, msg.sender);
    }

    // Helper function to create a new order
    function _createOrder(OrderType orderType, string memory optionName, uint price, uint quantity) internal returns (uint) {
        uint orderId = orderIdCounter;
        orders[orderId] = Order({
            id: orderId,
            creator: msg.sender,
            orderType: orderType,
            optionName: optionName,
            price: price,
            quantity: quantity,
            remainingQuantity: quantity, // Initially, remaining quantity is the full quantity
            isFilled: false
        });

        userOrders[msg.sender].push(orderId);
        orderIdCounter++;
        return orderId;
    }

    // View user's open orders
    function getUserOrders(address user) external view returns (uint[] memory) {
        return userOrders[user];
    }

    // View specific order details
    function getOrderDetails(uint orderId) external view returns (Order memory) {
        return orders[orderId];
    }
}
