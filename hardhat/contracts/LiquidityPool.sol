// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

// First Token
contract TokenA is ERC20 {
    constructor() ERC20("TokenA", "TKA") {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }
}

// Second Token
contract TokenB is ERC20 {
    constructor() ERC20("TokenB", "TKB") {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }
}

// Liquidity Pool
contract LiquidityPool is ReentrancyGuard {
    IERC20 public tokenA;
    IERC20 public tokenB;
    
    uint256 public totalLiquidityShares; 
    mapping(address => uint256) public liquidityShares; 
    
    uint256 private constant MINIMUM_LIQUIDITY = 1000;
    uint256 private constant PRECISION = 1e18;
    
    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB, uint256 liquidityShares);
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB, uint256 liquidityShares);
    event TokenSwap(address indexed user, uint256 amountIn, uint256 amountOut, bool isTokenAToTokenB);
    
    constructor(address _tokenA, address _tokenB) {
        require(_tokenA != address(0) && _tokenB != address(0), "Invalid token addresses");
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }
    
    function getReserves() public view returns (uint256 reserveA, uint256 reserveB) {
        reserveA = tokenA.balanceOf(address(this));
        reserveB = tokenB.balanceOf(address(this));
    }
    
    function addLiquidity(uint256 amountA, uint256 amountB) external nonReentrant returns (uint256 liquidityShare) {
        require(amountA > 0 && amountB > 0, "Amounts must be greater than 0");
        
        (uint256 reserveA, uint256 reserveB) = getReserves();
        
        // If first deposit
        if (totalLiquidityShares == 0) {
            liquidityShare = Math.sqrt(amountA * amountB) - MINIMUM_LIQUIDITY;
            totalLiquidityShares = liquidityShare + MINIMUM_LIQUIDITY;
        } else {
            // Check proportional deposit
            require(amountA * reserveB == amountB * reserveA, "Non-proportional deposit");
            
            // Calculate liquidity shares - can use either token as they should yield same result
            liquidityShare = Math.mulDiv(amountA, totalLiquidityShares, reserveA);
            totalLiquidityShares += liquidityShare;
        }
        
        require(tokenA.transferFrom(msg.sender, address(this), amountA), "Transfer of tokenA failed");
        require(tokenB.transferFrom(msg.sender, address(this), amountB), "Transfer of tokenB failed");
        
        require(liquidityShare > 0, "Insufficient liquidity minted");
        liquidityShares[msg.sender] += liquidityShare;
        
        emit LiquidityAdded(msg.sender, amountA, amountB, liquidityShare);
    }
    
    function removeLiquidity(uint256 liquidityShare) external nonReentrant returns (uint256 amountA, uint256 amountB) {
        require(liquidityShare > 0 && liquidityShares[msg.sender] >= liquidityShare, "Insufficient shares");
        require(totalLiquidityShares > liquidityShare, "Cannot remove all liquidity");
        
        (uint256 reserveA, uint256 reserveB) = getReserves();
        
        // Scale down calculations to avoid overflow
        uint256 shareRatio = Math.mulDiv(liquidityShare, PRECISION, totalLiquidityShares);
        
        // Calculate amounts using the ratio
        amountA = Math.mulDiv(reserveA, shareRatio, PRECISION);
        amountB = Math.mulDiv(reserveB, shareRatio, PRECISION);
        
        require(amountA > 0 && amountB > 0, "Insufficient liquidity burned");
        
        // Update state before transfers
        liquidityShares[msg.sender] -= liquidityShare;
        totalLiquidityShares -= liquidityShare;
        
        // Transfer tokens back to user
        require(tokenA.transfer(msg.sender, amountA), "Transfer of tokenA failed");
        require(tokenB.transfer(msg.sender, amountB), "Transfer of tokenB failed");
        
        emit LiquidityRemoved(msg.sender, amountA, amountB, liquidityShare);
    }
    
    function swap(uint256 amountIn, bool isTokenAToTokenB) external nonReentrant returns (uint256 amountOut) {
        require(amountIn > 0, "Amount must be greater than 0");
        
        (uint256 reserveA, uint256 reserveB) = getReserves();
        
        if (isTokenAToTokenB) {
            require(tokenA.transferFrom(msg.sender, address(this), amountIn), "Transfer of tokenA failed");
            uint256 amountInWithFee = Math.mulDiv(amountIn, 997, 1000);
            amountOut = Math.mulDiv(amountInWithFee, reserveB, reserveA + amountInWithFee);
            require(tokenB.transfer(msg.sender, amountOut), "Transfer of tokenB failed");
        } else {
            require(tokenB.transferFrom(msg.sender, address(this), amountIn), "Transfer of tokenB failed");
            uint256 amountInWithFee = Math.mulDiv(amountIn, 997, 1000);
            amountOut = Math.mulDiv(amountInWithFee, reserveA, reserveB + amountInWithFee);
            require(tokenA.transfer(msg.sender, amountOut), "Transfer of tokenA failed");
        }
        
        emit TokenSwap(msg.sender, amountIn, amountOut, isTokenAToTokenB);
    }
}
