// File: node_modules\@openzeppelin\contracts\GSN\Context.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin\contracts\access\Ownable.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @openzeppelin\contracts\utils\ReentrancyGuard.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin\contracts\token\ERC20\IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: @openzeppelin\contracts\math\SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @uniswap\v2-core\contracts\interfaces\IUniswapV2Pair.sol

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// File: node_modules\@uniswap\lib\contracts\libraries\FullMath.sol

// SPDX-License-Identifier: CC-BY-4.0
pragma solidity >=0.4.0;

// taken from https://medium.com/coinmonks/math-in-solidity-part-3-percents-and-proportions-4db014e080b1
// license is CC-BY-4.0
library FullMath {
    function fullMul(uint256 x, uint256 y) private pure returns (uint256 l, uint256 h) {
        uint256 mm = mulmod(x, y, uint256(-1));
        l = x * y;
        h = mm - l;
        if (mm < l) h -= 1;
    }

    function fullDiv(
        uint256 l,
        uint256 h,
        uint256 d
    ) private pure returns (uint256) {
        uint256 pow2 = d & -d;
        d /= pow2;
        l /= pow2;
        l += h * ((-pow2) / pow2 + 1);
        uint256 r = 1;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        return l * r;
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 d
    ) internal pure returns (uint256) {
        (uint256 l, uint256 h) = fullMul(x, y);
        uint256 mm = mulmod(x, y, d);
        if (mm > l) h -= 1;
        l -= mm;
        require(h < d, 'FullMath: FULLDIV_OVERFLOW');
        return fullDiv(l, h, d);
    }
}

// File: node_modules\@uniswap\lib\contracts\libraries\Babylonian.sol

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

// computes square roots using the babylonian method
// https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
library Babylonian {
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        // else z = 0
    }
}

// File: node_modules\@uniswap\lib\contracts\libraries\BitMath.sol

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.5.0;

library BitMath {
    function mostSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0, 'BitMath: ZERO');

        if (x >= 0x100000000000000000000000000000000) {
            x >>= 128;
            r += 128;
        }
        if (x >= 0x10000000000000000) {
            x >>= 64;
            r += 64;
        }
        if (x >= 0x100000000) {
            x >>= 32;
            r += 32;
        }
        if (x >= 0x10000) {
            x >>= 16;
            r += 16;
        }
        if (x >= 0x100) {
            x >>= 8;
            r += 8;
        }
        if (x >= 0x10) {
            x >>= 4;
            r += 4;
        }
        if (x >= 0x4) {
            x >>= 2;
            r += 2;
        }
        if (x >= 0x2) r += 1;
    }
}

// File: @uniswap\lib\contracts\libraries\FixedPoint.sol

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.4.0;




// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // range: [0, 2**144 - 1]
    // resolution: 1 / 2**112
    struct uq144x112 {
        uint256 _x;
    }

    uint8 private constant RESOLUTION = 112;
    uint256 private constant Q112 = 0x10000000000000000000000000000;
    uint256 private constant Q224 = 0x100000000000000000000000000000000000000000000000000000000;
    uint256 private constant LOWER_MASK = 0xffffffffffffffffffffffffffff; // decimal of UQ*x112 (lower 112 bits)

    // encode a uint112 as a UQ112x112
    function encode(uint112 x) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(x) << RESOLUTION);
    }

    // encodes a uint144 as a UQ144x112
    function encode144(uint144 x) internal pure returns (uq144x112 memory) {
        return uq144x112(uint256(x) << RESOLUTION);
    }

    // decode a UQ112x112 into a uint112 by truncating after the radix point
    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }

    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint256 y) internal pure returns (uq144x112 memory) {
        uint256 z = 0;
        require(y == 0 || (z = self._x * y) / y == self._x, 'FixedPoint: MUL_OVERFLOW');
        return uq144x112(z);
    }

    // multiply a UQ112x112 by an int and decode, returning an int
    // reverts on overflow
    function muli(uq112x112 memory self, int256 y) internal pure returns (int256) {
        uint256 z = FullMath.mulDiv(self._x, uint256(y < 0 ? -y : y), Q112);
        require(z < 2**255, 'FixedPoint: MULI_OVERFLOW');
        return y < 0 ? -int256(z) : int256(z);
    }

    // multiply a UQ112x112 by a UQ112x112, returning a UQ112x112
    // lossy
    function muluq(uq112x112 memory self, uq112x112 memory other) internal pure returns (uq112x112 memory) {
        if (self._x == 0 || other._x == 0) {
            return uq112x112(0);
        }
        uint112 upper_self = uint112(self._x >> RESOLUTION); // * 2^0
        uint112 lower_self = uint112(self._x & LOWER_MASK); // * 2^-112
        uint112 upper_other = uint112(other._x >> RESOLUTION); // * 2^0
        uint112 lower_other = uint112(other._x & LOWER_MASK); // * 2^-112

        // partial products
        uint224 upper = uint224(upper_self) * upper_other; // * 2^0
        uint224 lower = uint224(lower_self) * lower_other; // * 2^-224
        uint224 uppers_lowero = uint224(upper_self) * lower_other; // * 2^-112
        uint224 uppero_lowers = uint224(upper_other) * lower_self; // * 2^-112

        // so the bit shift does not overflow
        require(upper <= uint112(-1), 'FixedPoint: MULUQ_OVERFLOW_UPPER');

        // this cannot exceed 256 bits, all values are 224 bits
        uint256 sum = uint256(upper << RESOLUTION) + uppers_lowero + uppero_lowers + (lower >> RESOLUTION);

        // so the cast does not overflow
        require(sum <= uint224(-1), 'FixedPoint: MULUQ_OVERFLOW_SUM');

        return uq112x112(uint224(sum));
    }

    // divide a UQ112x112 by a UQ112x112, returning a UQ112x112
    function divuq(uq112x112 memory self, uq112x112 memory other) internal pure returns (uq112x112 memory) {
        require(other._x > 0, 'FixedPoint: DIV_BY_ZERO_DIVUQ');
        if (self._x == other._x) {
            return uq112x112(uint224(Q112));
        }
        if (self._x <= uint144(-1)) {
            uint256 value = (uint256(self._x) << RESOLUTION) / other._x;
            require(value <= uint224(-1), 'FixedPoint: DIVUQ_OVERFLOW');
            return uq112x112(uint224(value));
        }

        uint256 result = FullMath.mulDiv(Q112, self._x, other._x);
        require(result <= uint224(-1), 'FixedPoint: DIVUQ_OVERFLOW');
        return uq112x112(uint224(result));
    }

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // lossy
    function fraction(uint112 numerator, uint112 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, 'FixedPoint: DIV_BY_ZERO_FRACTION');
        return uq112x112((uint224(numerator) << RESOLUTION) / denominator);
    }

    // take the reciprocal of a UQ112x112
    // reverts on overflow
    // lossy
    function reciprocal(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        require(self._x > 1, 'FixedPoint: DIV_BY_ZERO_RECIPROCAL_OR_OVERFLOW');
        return uq112x112(uint224(Q224 / self._x));
    }

    // square root of a UQ112x112
    // lossy between 0/1 and 40 bits
    function sqrt(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        if (self._x <= uint144(-1)) {
            return uq112x112(uint224(Babylonian.sqrt(uint256(self._x) << 112)));
        }

        uint8 safeShiftBits = 255 - BitMath.mostSignificantBit(self._x);
        safeShiftBits -= safeShiftBits % 2;
        return uq112x112(uint224(Babylonian.sqrt(uint256(self._x) << safeShiftBits) << ((112 - safeShiftBits) / 2)));
    }
}

// File: contracts\interfaces\IToken.sol

interface IToken {

  function mint(address _beneficiary, uint _amount) external;

  function burn(uint _amount) external;

  function snapshot() external returns (uint);

  function transferAndCall(address _to, uint _tokens, bytes calldata _data) external returns (bool);

  function totalSupplyAt(uint _snapshotId) external view returns (uint);

  function balanceOfAt(address _account, uint _snapshotId) external view returns (uint);
}

// File: contracts\interfaces\IWETH.sol

interface IWETH {

  function deposit() external payable;

  function transfer(address _to, uint _value) external returns (bool);

  function withdraw(uint _amount) external;
}

// File: contracts\Vault.sol

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.5;

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
    setRewardContract(_rewardContract);
    setWithdrawalFeePercentage(_withdrawalFeePercentage);
    setApyPercentage(_apyPercentage);
    setEnableStaking(true);
  }

  receive()
  external
  payable
  {}

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
