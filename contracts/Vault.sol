// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.5;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/lib/contracts/libraries/FixedPoint.sol';

import "./interfaces/IToken.sol";
import "./interfaces/IWETH.sol";

contract Vault is Ownable, ReentrancyGuard {

  using SafeMath for uint;

  using FixedPoint for *;

  struct User {
    uint112 stake;
    uint112 reward;
    uint64 lastUpdate;
  }

  mapping(address => User) public userInfo;

  IUniswapV2Pair public lpToken;

  IToken public rewardToken;

  IWETH public WETH;

  address public rewardContract;

  address private token0;

  bool public enableStaking;

  uint public totalStaked;

  uint public apyPercentage;

  uint public withdrawalFeePercentage;

  uint public constant DENOMINATOR = 10000;

  uint32 public constant ONE_YEAR = 365 days;

  event TokenStake(address indexed _who, uint _amount, uint _timestamp);
  event TokenWithdraw(address indexed _who, uint _amount, uint _timestamp);
  event TokenClaim(address indexed _who, uint _amount, uint _timestamp);
  event BurnAndReward(address indexed _who, uint _amountBurned, uint _amountRewarded, uint _timestamp);

  // Use this on every fn that can change user's rewards data in any way
  modifier updatesRewards(address _account) {
    _updateRewards(_account);
    _;
  }

  modifier stakingEnabled() {
    require(enableStaking, "Staking is disabled");
    _;
  }

  constructor(
    address _lpToken,
    address _rewardToken,
    address _WETH,
    address _rewardContract,
    uint _withdrawalFeePercentage,
    uint _apyPercentage
  )
  public
  {
    require(_lpToken != address(0));
    lpToken = IUniswapV2Pair(_lpToken);
    token0 = lpToken.token0();

    require(_WETH != address(0));
    WETH = IWETH(_WETH);

    setRewardToken(_rewardToken);
    setWithdrawalFeePercentage(_withdrawalFeePercentage);
    setApyPercentage(_apyPercentage);
    setEnableStaking(true);
  }

  function stake(uint _tokens)
  external
  stakingEnabled
  nonReentrant
  updatesRewards(msg.sender)
  returns (bool)
  {
    require(lpToken.transferFrom(msg.sender, address(this), _tokens), "Tokens transfer failed");

    User storage user = userInfo[msg.sender];
    user.stake = _toUint112(uint(user.stake).add(_tokens));
    totalStaked = totalStaked.add(_tokens);

    emit TokenStake(msg.sender, _tokens, block.timestamp);
    return true;
  }

  function withdraw(uint _tokens)
  external
  nonReentrant
  updatesRewards(msg.sender)
  returns (bool)
  {
    _withdraw(msg.sender, _tokens);
    return true;
  }

  // If you call this function you forfeit your rewards
  function emergencyWithdraw()
  external
  nonReentrant
  returns (bool)
  {
    User storage user = userInfo[msg.sender];
    uint112 userStake = user.stake;

    user.reward = 0;
    user.lastUpdate = uint64(block.timestamp);

    _withdraw(msg.sender, userStake);
    return true;
  }

  function claim()
  external
  nonReentrant
  updatesRewards(msg.sender)
  returns (bool)
  {
    User storage user = userInfo[msg.sender];

    uint reward = user.reward;
    user.reward = 0;

    rewardToken.mint(msg.sender, reward);

    emit TokenClaim(msg.sender, reward, block.timestamp);
    return true;
  }

  function setEnableStaking(bool _enable)
  public
  onlyOwner
  {
    enableStaking = _enable;
  }

  function setRewardToken(address _rewardToken)
  public
  onlyOwner
  {
    require(_rewardToken != address(0));
    rewardToken = IToken(_rewardToken);
  }

  function setRewardContract(address _rewardContract)
  public
  onlyOwner
  {
    require(_rewardContract != address(0));
    rewardContract = _rewardContract;
  }

  function setWithdrawalFeePercentage(uint _withdrawalFeePercentage)
  public
  onlyOwner
  {
    withdrawalFeePercentage = _withdrawalFeePercentage;
  }

  function setApyPercentage(uint _apyPercentage)
  public
  onlyOwner
  {
    apyPercentage = _apyPercentage;
  }

  function drainEth(uint _amount)
  external
  onlyOwner
  {
    msg.sender.transfer(_amount);
  }

  function drainTokens(address _token, uint _amount)
  external
  onlyOwner
  {
    if (_token == address(lpToken)) {
      uint balance = IERC20(_token).balanceOf(address(this));
      uint maxToDrain = balance.sub(totalStaked);
      require(_amount <= maxToDrain, "Cannot drain such amount");
    }
    IERC20(_token).transfer(msg.sender, _amount);
  }

  function _updateRewards(address _account)
  internal
  {
    User storage user = userInfo[_account];

    if (user.lastUpdate == 0) {
      user.lastUpdate = uint64(block.timestamp);
    }

    uint112 stakedBalance = user.stake;
    uint64 lastUpdate = user.lastUpdate;

    if (stakedBalance > 0 && lastUpdate != block.timestamp) {
      uint timeElapsed = block.timestamp - lastUpdate;
      uint144 rewardsEarned = calculateRewards(stakedBalance, timeElapsed);

      user.reward = _toUint112(uint(user.reward).add(rewardsEarned));
      user.lastUpdate = uint64(block.timestamp);
    }
  }

  function _toUint112(uint _x)
  internal
  pure
  returns (uint112)
  {
    require(_x <= uint112(- 1), "overflow");
    return uint112(_x);
  }

  function _withdraw(address _account, uint _tokens)
  internal
  {
    User storage user = userInfo[_account];

    require(_tokens <= user.stake, "withdrawal amount exceeds balance");

    uint fee = _tokens.mul(withdrawalFeePercentage).div(DENOMINATOR);
    uint tokensToWithdraw = _tokens.sub(fee);

    user.stake = _toUint112(uint(user.stake).sub(_tokens));
    totalStaked = totalStaked.sub(_tokens);

    _burnAndReward(fee);
    require(lpToken.transfer(_account, tokensToWithdraw), "Tokens transfer failed");

    emit TokenWithdraw(_account, tokensToWithdraw, block.timestamp);
  }

  // Retrieve both tokens from LP pair. Burn reward token. Send WETH to the reward contract.
  function _burnAndReward(uint _amount)
  internal
  {
    address lpTokenAddress = address(lpToken);
    address rewardTokenAddress = address(rewardToken);

    lpToken.transfer(lpTokenAddress, _amount);
    (uint amount0, uint amount1) = lpToken.burn(address(this));
    uint amountB = rewardTokenAddress == token0 ? amount1 : amount0;

    // burn the whole balance of the reward token
    uint rewardTokenBalance = IERC20(rewardTokenAddress).balanceOf(address(this));
    rewardToken.burn(rewardTokenBalance);

    // unwrap weth and send to the reward contract
    uint wethBalance = IERC20(address(WETH)).balanceOf(address(this));
    WETH.withdraw(wethBalance);

    // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
    (bool success, ) = rewardContract.call{ value: wethBalance }("");
    require(success, "BurnAndReward: unable to send value, recipient may have reverted");

    emit BurnAndReward(msg.sender, rewardTokenBalance, wethBalance, block.timestamp);
  }

  function calculateRewards()
  public
  view
  returns (uint144)
  {
    User memory user = userInfo[msg.sender];
    uint112 stakedBalance = user.stake;
    uint64 lastUpdate = user.lastUpdate;
    uint timeElapsed = block.timestamp - lastUpdate;
    return calculateRewards(stakedBalance, timeElapsed);
  }

  function calculateRewards(uint112 _stakedBalance, uint _timeElapsed)
  public
  view
  returns (uint144)
  {
    uint pairTokenReserves = IERC20(address(rewardToken)).balanceOf(address(lpToken));

    uint112 lpTotalSupply = _toUint112(lpToken.totalSupply());
    uint112 annualizedStakedValue = _toUint112(uint(_stakedBalance).mul(apyPercentage).div(DENOMINATOR));

    FixedPoint.uq112x112 memory lpFraction = annualizedStakedValue.fraction(lpTotalSupply);
    uint112 annualizedReturns = _toUint112(lpFraction.mul(pairTokenReserves).decode144());

    FixedPoint.uq112x112 memory timeFraction = _toUint112(_timeElapsed).fraction(uint112(ONE_YEAR));
    uint144 rewardsEarned = uint112(timeFraction.mul(annualizedReturns).decode144());

    return rewardsEarned;
  }

  function getUserTotalRewards()
  public
  view
  returns (uint144)
  {
    User memory user = userInfo[msg.sender];
    return _toUint112(uint(user.reward).add(calculateRewards()));
  }

  function getUserInfo()
  public
  view
  returns (uint112, uint112, uint64) {
    User memory user = userInfo[msg.sender];
    return (user.stake, user.reward, user.lastUpdate);
  }

  function getUserInfoFull()
  external
  view
  returns (uint112, uint112, uint64, uint144, uint, uint) {
    User memory user = userInfo[msg.sender];
    uint144 totalRewards = getUserTotalRewards();
    uint lpBalance = lpToken.balanceOf(msg.sender);
    uint rewardTokenBalance = IERC20(address(rewardToken)).balanceOf(msg.sender);
    return (user.stake, user.reward, user.lastUpdate, totalRewards, lpBalance, rewardTokenBalance);
  }

  function getLpAllowance()
  external
  view
  returns (uint) {
    return lpToken.allowance(msg.sender, address(this));
  }
}