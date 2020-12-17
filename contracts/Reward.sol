// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.5;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./interfaces/IToken.sol";

contract Reward is Ownable, ReentrancyGuard {

  using SafeMath for uint;

  using EnumerableSet for EnumerableSet.AddressSet;

  struct EthReward {
    uint snapshotId;
    uint totalSupplyAtSnapshot;
    uint rewardAmount;
    uint claimedAmount;
    uint timestamp;
  }

  uint public constant CLAIM_DEADLINE = 182 days;

  uint public constant MIN_SNAPSHOT_INTERVAL = 1 weeks;

  IToken public token;

  EthReward[] public rewards;

  // not eligible for rewards
  EnumerableSet.AddressSet private _blacklist;

  // user -> reward id -> claimed
  mapping(address => mapping(uint => bool)) public claimedRewards;

  // reward id -> drained
  mapping(uint => bool) private drained;

  uint lastSnapshot;

  event Deposit(address _who, uint _amount, uint _timestamp);
  event NewToken(address _token, uint _timestamp);
  event NewReward(uint _rewardId, uint _snapshotId, uint _amount, uint _timestamp);
  event Claimed(address indexed _who, uint indexed _rewardId, uint _amount, uint _timestamp);
  event Drained(uint _rewardId, uint _amount, uint _timestamp);
  event Blacklisted(address _address, bool _blacklisted);

  constructor(address _token)
  {
    lastSnapshot = _getNow();
    setToken(_token);
  }

  function setToken(address _token)
  public
  onlyOwner
  {
    require(_token != address(0), "Invalid address");

    token = IToken(_token);
    emit NewToken(_token, _getNow());
  }

  receive()
  external
  payable
  {
    _deposit(msg.value);
    emit Deposit(msg.sender, msg.value, _getNow());
  }

  function claim(uint _rewardId)
  public
  nonReentrant
  {
    require(!claimedRewards[_msgSender()][_rewardId], "Already claimed");
    require(beforeDeadline(_rewardId), "Too late");

    uint myShare = getMyShare(_rewardId);
    require(myShare > 0, "Nothing to claim");

    EthReward storage reward = rewards[_rewardId];
    reward.claimedAmount = reward.claimedAmount.add(myShare);

    claimedRewards[_msgSender()][_rewardId] = true;

    // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
    (bool success,) = _msgSender().call{value : myShare}("");
    require(success, "Claim: unable to send value, recipient may have reverted");

    emit Claimed(_msgSender(), _rewardId, myShare, _getNow());
  }

  function claimBulk(uint[] calldata _rewardIds)
  external
  {
    for (uint i = 0; i < _rewardIds.length; i++) {
      claim(_rewardIds[i]);
    }
  }

  function drain(uint _rewardId)
  public
  onlyOwner
  {
    require(!beforeDeadline(_rewardId), "Too early");
    require(!drained[_rewardId], "Already drained");

    (,, uint rewardAmount, uint claimedAmount,) = getRewardInfo(_rewardId);
    uint unclaimedAmount = rewardAmount.sub(claimedAmount);
    drained[_rewardId] = true;

    _msgSender().transfer(unclaimedAmount);
    emit Drained(_rewardId, unclaimedAmount, _getNow());
  }

  function drainBulk(uint[] calldata _rewardIds)
  external
  {
    for (uint i = 0; i < _rewardIds.length; i++) {
      drain(_rewardIds[i]);
    }
  }

  function addBlacklist(address[] calldata _blacklisted)
  external
  onlyOwner
  {
    for (uint i = 0; i < _blacklisted.length; i++) {
      _blacklist.add(_blacklisted[i]);
      emit Blacklisted(_blacklisted[i], true);
    }
  }

  function removeBlacklist(address[] calldata _blacklisted)
  external
  onlyOwner
  {
    for (uint i = 0; i < _blacklisted.length; i++) {
      _blacklist.remove(_blacklisted[i]);
      emit Blacklisted(_blacklisted[i], false);
    }
  }

  function getNumberOfRewards()
  public
  view
  returns (uint)
  {
    return rewards.length;
  }

  function getRewardInfo(uint _rewardId)
  public
  view
  returns (uint snapshotId, uint totalSupplyAtSnapshot, uint rewardAmount, uint claimedAmount, uint timestamp)
  {
    require(_rewardId >= 0 && _rewardId < getNumberOfRewards(), "Invalid reward id");

    EthReward memory reward = rewards[_rewardId];
    snapshotId = reward.snapshotId;
    totalSupplyAtSnapshot = reward.totalSupplyAtSnapshot;
    rewardAmount = reward.rewardAmount;
    claimedAmount = reward.claimedAmount;
    timestamp = reward.timestamp;
  }

  function deadline(uint _rewardId)
  public
  view
  returns (uint)
  {
    (,,,, uint timestamp) = getRewardInfo(_rewardId);
    return timestamp + CLAIM_DEADLINE;
  }

  function beforeDeadline(uint _rewardId)
  public
  view
  returns (bool)
  {
    return _getNow() <= deadline(_rewardId);
  }

  function getMyShare(uint _rewardId)
  public
  view
  returns (uint)
  {
    return getShare(_msgSender(), _rewardId);
  }

  function getShare(address _account, uint _rewardId)
  public
  view
  returns (uint)
  {
    if (claimedRewards[_account][_rewardId]) {
      return 0;
    }
    (uint snapshotId, uint totalSupplyAtSnapshot, uint rewardAmount, ,) = getRewardInfo(_rewardId);
    uint balanceAtSnapshot = token.balanceOfAt(_account, snapshotId);
    return rewardAmount.mul(balanceAtSnapshot).div(totalSupplyAtSnapshot);
  }

  function blacklistContains(address _address)
  public
  view
  returns (bool)
  {
    return _blacklist.contains(_address);
  }

  function blacklistLength()
  public
  view
  returns (uint)
  {
    return _blacklist.length();
  }

  function blacklistAt(uint _index)
  public
  view
  returns (address)
  {
    return _blacklist.at(_index);
  }

  function _deposit(uint _weiAmount)
  internal
  {
    require(_weiAmount > 0, "Must deposit something");

    uint timeElapsed = _getNow() - lastSnapshot;

    // do the snapshot if at least 1 week passed since last snapshot
    if (timeElapsed >= MIN_SNAPSHOT_INTERVAL) {
      uint snapshotId = token.snapshot();
      uint totalSupplyAtSnapshot = token.totalSupplyAt(snapshotId);

      uint newId = rewards.length;

      // remove blacklisted balances from total supply
      for (uint i = 0; i < blacklistLength(); i++) {
        address blacklisted = blacklistAt(i);
        uint balanceAtSnapshot = token.balanceOfAt(blacklisted, snapshotId);
        totalSupplyAtSnapshot = totalSupplyAtSnapshot.sub(balanceAtSnapshot);
        claimedRewards[blacklisted][newId] = true;
      }

      EthReward memory newReward = EthReward({
        snapshotId : snapshotId,
        totalSupplyAtSnapshot : totalSupplyAtSnapshot,
        rewardAmount : _weiAmount,
        claimedAmount : 0,
        timestamp : _getNow()
        });

      rewards.push(newReward);

      lastSnapshot = _getNow();

      emit NewReward(newId, snapshotId, _weiAmount, _getNow());
    }
  }

  function _getNow() internal view returns (uint) {
    return block.timestamp;
  }
}