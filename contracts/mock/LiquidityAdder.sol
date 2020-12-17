import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./MockERC20.sol";
import "../interfaces/IToken.sol";

interface IUniswapV2Router02 {

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint amountADesired,
    uint amountBDesired,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  ) external returns (uint amountA, uint amountB, uint liquidity);
}


contract LiquidityAdder {

  MockERC20 public weth;
  IUniswapV2Factory public factory;
  IUniswapV2Router02 public router;

  constructor(
    address weth_,
    address factory_,
    address router_
  )
  public
  {
    weth = MockERC20(weth_);
    factory = IUniswapV2Factory(factory_);
    router = IUniswapV2Router02(router_);
  }

  function addLiquiditySingle(
    IToken token,
    uint256 amountToken,
    uint256 amountWeth
  )
  public
  {
    IToken(token).mint(address(this), amountToken);
    weth.getFreeTokens(address(this), amountWeth);
    IERC20(address(token)).approve(address(router), amountToken);
    weth.approve(address(router), amountWeth);
    router.addLiquidity(
      address(token),
      address(weth),
      amountToken,
      amountWeth,
      amountToken / 2,
      amountWeth / 2,
      msg.sender,
      block.timestamp
    );
  }
}