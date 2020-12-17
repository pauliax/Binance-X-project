// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.5;

import "@openzeppelin/contracts/token/ERC20/ERC20Snapshot.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./interfaces/IToken.sol";
import "./interfaces/ICallable.sol";

contract Token is IToken, ERC20Snapshot, ERC20Burnable, Ownable, AccessControl {

  using SafeMath for uint;

  bytes32 public constant SNAPSHOT_ROLE = keccak256("SNAPSHOT_ROLE");

  bytes32 public constant MINTING_ROLE = keccak256("MINTING_ROLE");

  constructor(
    string memory _name,
    string memory _symbol,
    uint _initialSupplyWithoutDecimals
  )
  ERC20(_name, _symbol)
  {
    _mint(msg.sender, _initialSupplyWithoutDecimals * (10 ** uint(decimals())));
  }

  function mint(address _beneficiary, uint _amount)
  public
  override(IToken)
  {
    require(hasRole(MINTING_ROLE, _msgSender()), "AccessControl: not minting address");
    _mint(_beneficiary, _amount);
  }

  function snapshot()
  public
  override(IToken)
  returns (uint)
  {
    require(hasRole(SNAPSHOT_ROLE, _msgSender()), "AccessControl: not snapshot address");
    return super._snapshot();
  }

  function burn(uint _amount)
  public
  virtual
  override(ERC20Burnable, IToken)
  {
    super.burn(_amount);
  }

  function transferAndCall(address _to, uint _tokens, bytes calldata _data)
  external
  override
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