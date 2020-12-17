import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {

  constructor(string memory _name, string memory _symbol)
  public
  ERC20(_name, _symbol)
  {

  }

  // Mocks WETH deposit fn
  function deposit() external payable {
    _mint(msg.sender, msg.value);
  }

  function getFreeTokens(address to, uint256 amount) public {
    _mint(to, amount);
  }
}