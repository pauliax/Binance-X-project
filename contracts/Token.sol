// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.5;

import "@openzeppelin/contracts/token/ERC20/ERC20Snapshot.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./interfaces/ICallable.sol";

contract Token is ERC20Snapshot, ERC20Burnable, Ownable, AccessControl  {

  using SafeMath for uint;

  bytes32 public constant SNAPSHOT_ROLE = keccak256("SNAPSHOT_ROLE");

  constructor(
    string memory _name,
    string memory _symbol,
    uint _initialSupplyWithoutDecimals
  )
  ERC20(_name, _symbol)
  {
    _mint(msg.sender, _initialSupplyWithoutDecimals * (10 ** uint(decimals())));
  }

  function grantSnapshotRole(address _snapshotAddress)
  external
  onlyOwner
  {
    _setupRole(SNAPSHOT_ROLE, _snapshotAddress);
  }

  function snapshot()
  public
  returns (uint)
  {
    require(hasRole(SNAPSHOT_ROLE, _msgSender()), "AccessControl: not snapshot address");
    return super._snapshot();
  }

  function transferAndCall(address _to, uint _tokens, bytes calldata _data)
  external
  returns (bool)
  {
    transfer(_to, _tokens);
    uint32 _size;
    assembly {
      _size := extcodesize(_to)
    }
    if (_size > 0) {
      require(ICallable(_to).tokenCallback(msg.sender, _tokens, _data));
    }
    return true;
  }

  function _beforeTokenTransfer(address from, address to, uint amount)
  internal
  virtual
  override(ERC20, ERC20Snapshot)
  {
    super._beforeTokenTransfer(from, to, amount);
  }
}