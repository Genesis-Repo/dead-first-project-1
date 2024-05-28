// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DecentralizedExchange is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    mapping(address => mapping(address => uint256)) public tokens; // token address => user address => token balance
    mapping(address => mapping(address => uint256)) public limitOrders; // token address => user address => limit order amount

    event TokensSwapped(address indexed user, address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut);
    event LimitOrderSet(address indexed user, address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut);

    function swapTokens(address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut) external nonReentrant {
        require(tokens[tokenIn][msg.sender] >= amountIn, "Insufficient balance");

        tokens[tokenIn][msg.sender] = tokens[tokenIn][msg.sender].sub(amountIn);
        tokens[tokenOut][msg.sender] = tokens[tokenOut][msg.sender].add(amountOut);

        emit TokensSwapped(msg.sender, tokenIn, tokenOut, amountIn, amountOut);
    }

    function deposit(address token, uint256 amount) external {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        tokens[token][msg.sender] = tokens[token][msg.sender].add(amount);
    }

    function withdraw(address token, uint256 amount) external {
        require(tokens[token][msg.sender] >= amount, "Insufficient balance");

        tokens[token][msg.sender] = tokens[token][msg.sender].sub(amount);
        IERC20(token).safeTransfer(msg.sender, amount);
    }

    function setLimitOrder(address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut) external {
        require(tokens[tokenIn][msg.sender] >= amountIn, "Insufficient balance");
        
        tokens[tokenIn][msg.sender] = tokens[tokenIn][msg.sender].sub(amountIn);
        limitOrders[tokenIn][msg.sender] = amountOut;

        emit LimitOrderSet(msg.sender, tokenIn, tokenOut, amountIn, amountOut);
    }

    function fulfillLimitOrder(address tokenIn, address tokenOut, address user, uint256 amount) external nonReentrant {
        require(limitOrders[tokenIn][user] >= amount, "Insufficient limit order amount");

        limitOrders[tokenIn][user] = limitOrders[tokenIn][user].sub(amount);
        tokens[tokenOut][msg.sender] = tokens[tokenOut][msg.sender].add(amount);

        emit TokensSwapped(user, tokenIn, tokenOut, amount, amount);
    }

    function getTokenBalance(address token, address user) external view returns (uint256) {
        return tokens[token][user];
    }

    function getLimitOrderAmount(address tokenIn, address user) external view returns (uint256) {
        return limitOrders[tokenIn][user];
    }
}