import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';

library UniswapV2Library {
  using SafeMath for uint;

  // returns sorted token addresses, used to handle return values from pairs sorted in this order
  function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
    require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
    (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
  }

  // calculates the CREATE2 address for a pair without making any external calls
  function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
    (address token0, address token1) = sortTokens(tokenA, tokenB);
    pair = address(uint(keccak256(abi.encodePacked(
        hex'ff',
        factory,
        keccak256(abi.encodePacked(token0, token1)),
        hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
      ))));
  }

  // fetches and sorts the reserves for a pair
  function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
    (address token0,) = sortTokens(tokenA, tokenB);
    (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
    (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
  }

  // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
  function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
    require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
    require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
    amountB = amountA.mul(reserveB) / reserveA;
  }
}


contract UniswapV2Router02 {

  using SafeMath for uint;

  address public factory;
  address public WETH;

  modifier ensure(uint deadline) {
    require(deadline >= block.timestamp, 'UniswapV2Router: EXPIRED');
    _;
  }

  constructor(address _factory, address _WETH) public {
    factory = _factory;
    WETH = _WETH;
  }

  receive() external payable {
    assert(msg.sender == WETH);
    // only accept ETH via fallback from the WETH contract
  }

  // **** ADD LIQUIDITY ****
  function _addLiquidity(
    address tokenA,
    address tokenB,
    uint amountADesired,
    uint amountBDesired,
    uint amountAMin,
    uint amountBMin
  )
  internal
  returns (uint amountA, uint amountB)
  {
    // create the pair if it doesn't exist yet
    //        if (IUniswapV2Factory(factory).getPair(tokenA, tokenB) == address(0)) {
    //            IUniswapV2Factory(factory).createPair(tokenA, tokenB);
    //        }
    //        (uint reserveA, uint reserveB) = UniswapV2Library.getReserves(factory, tokenA, tokenB);
    //        if (reserveA == 0 && reserveB == 0) {
    (amountA, amountB) = (amountADesired, amountBDesired);
    //        }
    //        else {
    //            uint amountBOptimal = UniswapV2Library.quote(amountADesired, reserveA, reserveB);
    //            if (amountBOptimal <= amountBDesired) {
    //                require(amountBOptimal >= amountBMin, 'UniswapV2Router: INSUFFICIENT_B_AMOUNT');
    //                (amountA, amountB) = (amountADesired, amountBOptimal);
    //            } else {
    //                uint amountAOptimal = UniswapV2Library.quote(amountBDesired, reserveB, reserveA);
    //                assert(amountAOptimal <= amountADesired);
    //                require(amountAOptimal >= amountAMin, 'UniswapV2Router: INSUFFICIENT_A_AMOUNT');
    //                (amountA, amountB) = (amountAOptimal, amountBDesired);
    //            }
    //        }
  }

  function getPairAddress(address tokenA, address tokenB)
  public
  view
  returns (address)
  {
    //        return UniswapV2Library.pairFor(factory, tokenA, tokenB);
    return IUniswapV2Factory(factory).getPair(tokenA, tokenB);
  }

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint amountADesired,
    uint amountBDesired,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  )
  external
  ensure(deadline)
  returns (uint amountA, uint amountB, uint liquidity)
  {
    (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
    address pair = getPairAddress(tokenA, tokenB);// UniswapV2Library.pairFor(factory, tokenA, tokenB);
    IERC20(tokenA).transferFrom(msg.sender, pair, amountA);
    IERC20(tokenB).transferFrom(msg.sender, pair, amountB);
    liquidity = IUniswapV2Pair(pair).mint(to);
  }

  // **** LIBRARY FUNCTIONS ****
  function quote(uint amountA, uint reserveA, uint reserveB)
  public
  pure
  returns (uint amountB)
  {
    return UniswapV2Library.quote(amountA, reserveA, reserveB);
  }
}