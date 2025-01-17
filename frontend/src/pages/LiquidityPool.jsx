import React, { useEffect, useState } from 'react';
import { ArrowDownUp, Plus, Minus } from 'lucide-react';
import { ethers } from 'ethers';
import { abi } from '../scdata/abi.json';
import depadd from '../scdata/deployed_address.json';

const deployedAddress = depadd.LiquidityModuleLiquidityPool;

const tokens = {
  TKA: "0x50E00bC33d107108D935B07EF7D82594651B1968", 
  TKB: "0x3070ef83F647838DB86f276c7D9E58B83559a788",
};

const LiquidityPool = () => {
  const [connected, setConnected] = useState(false);
  const [loading, setLoading] = useState(false);
  const [activeTab, setActiveTab] = useState('swap');
  const [swapAmount, setSwapAmount] = useState('');
  const [swapDirection, setSwapDirection] = useState(true);
  const [tokenAAmount, setTokenAAmount] = useState('');
  const [tokenBAmount, setTokenBAmount] = useState('');
  const [removeAmount, setRemoveAmount] = useState('');
  const [tokenABalance, setTokenABalance] = useState('0.0');
  const [tokenBBalance, setTokenBBalance] = useState('0.0');
  const [poolShare, setPoolShare] = useState('0.0');
  const [signer, setSigner] = useState(null);
  const [account, setAccount] = useState('');
  const [contract, setContract] = useState(null);
  const [error, setError] = useState('');
  
  async function updateBalances() {
    if (!contract || !connected || !account) return;
    
    try {
      setError('');
      
      const [reserveA, reserveB] = await contract.getReserves();
      setTokenABalance(ethers.formatEther(reserveA));
      setTokenBBalance(ethers.formatEther(reserveB));

      const totalShares = await contract.totalShares();
      const userShares = await contract.shares(account);

      if (totalShares && Number(totalShares) > 0) {
        const sharePercentage = (Number(userShares) / Number(totalShares) * 100);
        setPoolShare(sharePercentage.toFixed(2));
      } else {
        setPoolShare('0.00');
      }
    } catch (error) {
      console.error("Error updating balances:", error);
      setError('Failed to fetch pool data. Please check your connection and try again.');
    }
  }

  const connectWallet = async () => {
    if (window.ethereum) {
      try {
        setLoading(true);
        const provider = new ethers.BrowserProvider(window.ethereum);
        const accounts = await provider.send("eth_requestAccounts", []);
        const newSigner = await provider.getSigner();
        const lpContract = new ethers.Contract(deployedAddress, abi, newSigner);
        
        setSigner(newSigner);
        setContract(lpContract);
        setAccount(accounts[0]);
        setConnected(true);
  
        await updateBalances();
      } catch (error) {
        console.error("Failed to connect wallet:", error);
      } finally {
        setLoading(false);
      }
    } else {
      console.error("Please install MetaMask!");
    }
  };

  const handleSwap = async () => {
    if (!contract || !swapAmount) return;
    
    try {
      setLoading(true);
      setError('');
      
      const tokenContract = new ethers.Contract(
        swapDirection ? tokens.TKA : tokens.TKB,
        ['function approve(address spender, uint256 amount) public returns (bool)'],
        signer
      );
      
      const amount = ethers.parseEther(swapAmount);
      const approveTx = await tokenContract.approve(deployedAddress, amount);
      await approveTx.wait();
      
      const tx = await contract.swap(amount, swapDirection);
      await tx.wait();
      await updateBalances();
      setSwapAmount('');
    } catch (error) {
      console.error("Swap failed:", error);
      setError(error.message || 'Swap failed. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const handleAddLiquidity = async () => {
    if (!contract || !tokenAAmount || !tokenBAmount) return;
    
    try {
      setLoading(true);
      setError('');
      
      const amountA = ethers.parseEther(tokenAAmount);
      const amountB = ethers.parseEther(tokenBAmount);

      const tokenAContract = new ethers.Contract(
        tokens.TKA,
        ['function approve(address spender, uint256 amount) public returns (bool)'],
        signer
      );
      const tokenBContract = new ethers.Contract(
        tokens.TKB,
        ['function approve(address spender, uint256 amount) public returns (bool)'],
        signer
      );
      
      const approve1Tx = await tokenAContract.approve(deployedAddress, amountA);
      await approve1Tx.wait();
      
      const approve2Tx = await tokenBContract.approve(deployedAddress, amountB);
      await approve2Tx.wait();
      
      const tx = await contract.addLiquidity(amountA, amountB);
      await tx.wait();
      
      await updateBalances();
      setTokenAAmount('');
      setTokenBAmount('');
    } catch (error) {
      console.error("Adding liquidity failed:", error);
      setError(error.message || 'Failed to add liquidity. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const handleRemoveLiquidity = async () => {
    if (!contract || !removeAmount) return;
    
    try {
      setLoading(true);
      setError('');
      const amount = ethers.parseEther(removeAmount);
      
      const tx = await contract.removeLiquidity(amount);
      await tx.wait();
      await updateBalances();
      setRemoveAmount('');
    } catch (error) {
      console.error("Removing liquidity failed:", error);
      setError(error.message || 'Failed to remove liquidity. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    connectWallet();
  }, []);

  return (
    <div className="min-h-screen bg-gray-900 py-12">
      <div className="max-w-lg mx-auto p-6 bg-white rounded-xl shadow-lg space-y-8">
        <div className="flex justify-center items-center">
          <h1 className="text-3xl font-semibold text-gray-900">
            Liquidity Pool Dashboard
          </h1>
        </div>
        <div className="flex justify-center space-x-6">
          <button
            onClick={() => setActiveTab('swap')}
            className={`px-4 py-2 rounded-full transition-all font-medium ${activeTab === 'swap' ? 'bg-purple-600 text-white' : 'bg-gray-200 text-gray-700'}`}
          >
            Swap
          </button>
          <button
            onClick={() => setActiveTab('add')}
            className={`px-4 py-2 rounded-full transition-all font-medium ${activeTab === 'add' ? 'bg-purple-600 text-white' : 'bg-gray-200 text-gray-700'}`}
          >
            Add Liquidity
          </button>
          <button
            onClick={() => setActiveTab('remove')}
            className={`px-4 py-2 rounded-full transition-all font-medium ${activeTab === 'remove' ? 'bg-purple-600 text-white' : 'bg-gray-200 text-gray-700'}`}
          >
            Remove Liquidity
          </button>
        </div>

        {activeTab === 'swap' && (
          <div className="space-y-4">
            <input
              type="number"
              className="w-full p-4 bg-gray-100 rounded-lg text-gray-800"
              placeholder="Amount to Swap"
              value={swapAmount}
              onChange={(e) => setSwapAmount(e.target.value)}
              disabled={loading}
            />
            <button
              onClick={() => setSwapDirection(!swapDirection)}
              className="w-full py-3 bg-gray-300 rounded-lg text-gray-900"
              disabled={loading}
            >
              Swap Direction
            </button>
            <button
              onClick={handleSwap}
              className="w-full py-3 bg-purple-600 text-white rounded-lg font-semibold"
              disabled={loading || !swapAmount}
            >
              {loading ? 'Processing...' : 'Swap'}
            </button>
          </div>
        )}

        {activeTab === 'add' && (
          <div className="space-y-4">
            <input
              type="number"
              className="w-full p-4 bg-gray-100 rounded-lg text-gray-800"
              placeholder="Token A Amount"
              value={tokenAAmount}
              onChange={(e) => setTokenAAmount(e.target.value)}
              disabled={loading}
            />
            <input
              type="number"
              className="w-full p-4 bg-gray-100 rounded-lg text-gray-800"
              placeholder="Token B Amount"
              value={tokenBAmount}
              onChange={(e) => setTokenBAmount(e.target.value)}
              disabled={loading}
            />
            <button
              onClick={handleAddLiquidity}
              className="w-full py-3 bg-purple-600 text-white rounded-lg font-semibold"
              disabled={loading || !tokenAAmount || !tokenBAmount}
            >
              {loading ? 'Processing...' : 'Add Liquidity'}
            </button>
          </div>
        )}

        {activeTab === 'remove' && (
          <div className="space-y-4">
            <div className="bg-gray-800 text-white p-4 rounded-lg">
              Your Pool Share: {poolShare}%
            </div>
            <input
              type="number"
              className="w-full p-4 bg-gray-100 rounded-lg text-gray-800"
              placeholder="Amount to Remove"
              value={removeAmount}
              onChange={(e) => setRemoveAmount(e.target.value)}
              disabled={loading}
            />
            <button
              onClick={handleRemoveLiquidity}
              className="w-full py-3 bg-purple-600 text-white rounded-lg font-semibold"
              disabled={loading || !removeAmount}
            >
              {loading ? 'Processing...' : 'Remove Liquidity'}
            </button>
          </div>
        )}
      </div>
    </div>
  );
};

export default LiquidityPool;
