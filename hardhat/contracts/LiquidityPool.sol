// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

// First Token
contract Token1 is ERC20 {
    constructor() ERC20("Token1", "TK1") {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }
}

// Second Token
contract Token2 is ERC20 {
    constructor() ERC20("Token2", "TK2") {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }
}

// Liquidity Pool

contract LiquidityPool is ReentrancyGuard {
    IERC20 public token1;
    IERC20 public token2;
    
    uint256 public totalShares; 
    mapping(address => uint256) public shares; 
    
    uint256 private constant MINIMUM_LIQUIDITY = 1000;
    uint256 private constant PRECISION = 1e18;
    
    event LiquidityAdded(address indexed provider, uint256 amount1, uint256 amount2, uint256 shares);
    event LiquidityRemoved(address indexed provider, uint256 amount1, uint256 amount2, uint256 shares);
    event Swap(address indexed user, uint256 amountIn, uint256 amountOut, bool token1ToToken2);
    
    constructor(address _token1, address _token2) {
        require(_token1 != address(0) && _token2 != address(0), "Invalid token addresses");
        token1 = IERC20(_token1);
        token2 = IERC20(_token2);
    }
    
    function getReserves() public view returns (uint256 reserve1, uint256 reserve2) {
        reserve1 = token1.balanceOf(address(this));
        reserve2 = token2.balanceOf(address(this));
    }
    
function addLiquidity(uint256 amount1, uint256 amount2) external nonReentrant returns (uint256 share) {
    require(amount1 > 0 && amount2 > 0, "Amounts must be greater than 0");
    
    (uint256 reserve1, uint256 reserve2) = getReserves();
    
    // If first deposit
    if (totalShares == 0) {
        share = Math.sqrt(amount1 * amount2) - MINIMUM_LIQUIDITY;
        totalShares = share + MINIMUM_LIQUIDITY;
    } else {
        // Check proportional deposit
        require(amount1 * reserve2 == amount2 * reserve1, "Non-proportional deposit");
        
        // Calculate shares - can use either token as they should yield same result
        share = Math.mulDiv(amount1, totalShares, reserve1);
        totalShares += share;
    }
    
    require(token1.transferFrom(msg.sender, address(this), amount1), "Transfer of token1 failed");
    require(token2.transferFrom(msg.sender, address(this), amount2), "Transfer of token2 failed");
    
    require(share > 0, "Insufficient liquidity minted");
    shares[msg.sender] += share;
    
    emit LiquidityAdded(msg.sender, amount1, amount2, share);
}
    function removeLiquidity(uint256 share) external nonReentrant returns (uint256 amount1, uint256 amount2) {
        require(share > 0 && shares[msg.sender] >= share, "Insufficient shares");
        require(totalShares > share, "Cannot remove all liquidity");
        
        (uint256 reserve1, uint256 reserve2) = getReserves();
        
        // Scale down calculations to avoid overflow
        uint256 shareRatio = Math.mulDiv(share, PRECISION, totalShares);
        
        // Calculate amounts using the ratio
        amount1 = Math.mulDiv(reserve1, shareRatio, PRECISION);
        amount2 = Math.mulDiv(reserve2, shareRatio, PRECISION);
        
        require(amount1 > 0 && amount2 > 0, "Insufficient liquidity burned");
        
        // Update state before transfers
        shares[msg.sender] -= share;
        totalShares -= share;
        
        // Transfer tokens back to user
        require(token1.transfer(msg.sender, amount1), "Transfer of token1 failed");
        require(token2.transfer(msg.sender, amount2), "Transfer of token2 failed");
        
        emit LiquidityRemoved(msg.sender, amount1, amount2, share);
    }
    
    function swap(uint256 amountIn, bool token1ToToken2) external nonReentrant returns (uint256 amountOut) {
        require(amountIn > 0, "Amount must be greater than 0");
        
        (uint256 reserve1, uint256 reserve2) = getReserves();
        
        if (token1ToToken2) {
            require(token1.transferFrom(msg.sender, address(this), amountIn), "Transfer of token1 failed");
            uint256 amountInWithFee = Math.mulDiv(amountIn, 997, 1000);
            amountOut = Math.mulDiv(amountInWithFee, reserve2, reserve1 + amountInWithFee);
            require(token2.transfer(msg.sender, amountOut), "Transfer of token2 failed");
        } else {
            require(token2.transferFrom(msg.sender, address(this), amountIn), "Transfer of token2 failed");
            uint256 amountInWithFee = Math.mulDiv(amountIn, 997, 1000);
            amountOut = Math.mulDiv(amountInWithFee, reserve1, reserve2 + amountInWithFee);
            require(token1.transfer(msg.sender, amountOut), "Transfer of token1 failed");
        }
        
        emit Swap(msg.sender, amountIn, amountOut, token1ToToken2);
    }
}