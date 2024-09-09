// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.27;

import "../lib/openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "./UserBets.sol";

contract OrderBook {
    uint public orderIdCounter;

    enum OrderType { Buy, Sell }

    struct Order {
        uint id;
        address creator;
        OrderType orderType;
        bytes32 option;
        uint price; // Price in ERC20 tokens
        uint quantity;
        uint remainingQuantity; // Track remaining quantity for partial fills
        bool isFilled;
    }

    ERC20 public money;
    UserBets public bets;
    mapping(uint => Order) public orders;
    mapping(address => uint[]) public userOrders; // User's list of order IDs

    event OrderPlaced(uint orderId, address indexed creator, OrderType orderType, bytes32 option, uint price, uint quantity);
    event OrderFilled(uint orderId, address indexed fulfiller, uint amountFilled, uint remainingQuantity, bool fullyFilled);
    event OrderCancelled(uint orderId, address indexed creator);

    error InsufficientTokenBalance();
    error OrderAlreadyFilled();
    error InvalidFillAmount();
    error InsufficientBalanceToBuy();
    error OnlyCreatorCanCancel();
    error OrderCannotBeFilled();

    constructor(ERC20 _money, UserBets _positions) {
        money = _money;
        bets = _positions;
    }

    // Place a buy order
    function placeBuyOrder(bytes32 option, uint price, uint quantity) external {
        uint orderId = _createOrder(OrderType.Buy, option, price, quantity);
        emit OrderPlaced(orderId, msg.sender, OrderType.Buy, option, price, quantity);
    }

    // Place a sell order
    function placeSellOrder(bytes32 option, uint price, uint quantity) external {
        uint tokenId = bets.getTokenId(option);
        if (bets.balanceOf(msg.sender, tokenId) < quantity) {
            revert InsufficientTokenBalance();
        }

        uint orderId = _createOrder(OrderType.Sell, option, price, quantity);
        emit OrderPlaced(orderId, msg.sender, OrderType.Sell, option, price, quantity);
    }

    // Fill an existing order with partial matching
    function fillOrder(uint orderId, uint amountToFill) external {
        Order storage order = orders[orderId];
        if (order.isFilled) {
            revert OrderAlreadyFilled();
        }
        if (amountToFill == 0 || amountToFill > order.remainingQuantity) {
            revert InvalidFillAmount();
        }

        uint totalCost = order.price * amountToFill;

        if (order.orderType == OrderType.Sell) {
            // Fulfill a sell order
            if (money.balanceOf(msg.sender) < totalCost) {
                revert InsufficientBalanceToBuy();
            }
            money.transferFrom(msg.sender, order.creator, totalCost);

            uint tokenId = bets.getTokenId(order.option);
            bets.safeTransferFrom(order.creator, msg.sender, tokenId, amountToFill, "");
        } else if (order.orderType == OrderType.Buy) {
            // Fulfill a buy order
            uint tokenId = bets.getTokenId(order.option);
            if (bets.balanceOf(msg.sender, tokenId) < amountToFill) {
                revert InsufficientTokenBalance();
            }
            bets.safeTransferFrom(msg.sender, order.creator, tokenId, amountToFill, "");

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
        if (order.creator != msg.sender) {
            revert OnlyCreatorCanCancel();
        }
        if (order.isFilled) {
            revert OrderAlreadyFilled();
        }

        if (order.orderType == OrderType.Sell) {
            // Return the remaining GamePositionToken1155 tokens to the creator
            uint tokenId = bets.getTokenId(order.option);
            bets.safeTransferFrom(address(this), order.creator, tokenId, order.remainingQuantity, "");
        } else if (order.orderType == OrderType.Buy) {
            // Return the remaining ERC20 tokens to the creator
            uint refundAmount = order.remainingQuantity * order.price;
            money.transfer(order.creator, refundAmount);
        }

        order.isFilled = true; // Mark order as filled to prevent future filling
        emit OrderCancelled(orderId, msg.sender);
    }

    // Helper function to create a new order
    function _createOrder(OrderType orderType, bytes32 option, uint price, uint quantity) internal returns (uint) {
        uint orderId = orderIdCounter;
        orders[orderId] = Order({
            id: orderId,
            creator: msg.sender,
            orderType: orderType,
            option: option,
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
