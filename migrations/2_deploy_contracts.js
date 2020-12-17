const Token = artifacts.require("./Token.sol");
const Vault = artifacts.require("./Vault.sol");
const Reward = artifacts.require("./Reward.sol");

const MockERC20 = artifacts.require("./MockERC20.sol");
const UniswapV2Factory = artifacts.require("./UniswapV2Factory.sol");
const UniswapV2Router02 = artifacts.require("./UniswapV2Router02.sol");
const LiquidityAdder = artifacts.require("./LiquidityAdder.sol");

module.exports = async function (deployer, network, accounts) {

  let lpTokenAddress = "0x0000000000000000000000000000000000000000";
  let WETHAddress = "0x0000000000000000000000000000000000000000";

  await deployer.deploy(Token,
    "Test Token",   // _name
    "TEST",         // _symbol
    "100000"        // _initialSupplyWithoutDecimals
  );

  await deployer.deploy(Reward,
    Token.address, // _token
  );

  const tokenInstance = await Token.deployed();
  const MINTING_ROLE = await tokenInstance.MINTING_ROLE();
  const SNAPSHOT_ROLE = await tokenInstance.SNAPSHOT_ROLE();

  if (network !== 'live') {
    await deployer.deploy(MockERC20, "Wrapped Ether", "WETH");
    await deployer.deploy(UniswapV2Factory, "0x0000000000000000000000000000000000000000");
    await deployer.deploy(UniswapV2Router02, UniswapV2Factory.address, MockERC20.address);
    await deployer.deploy(LiquidityAdder, MockERC20.address, UniswapV2Factory.address, UniswapV2Router02.address);

    const weth = await MockERC20.deployed();
    await weth.getFreeTokens(accounts[0], "999000000000000000000");
    WETHAddress = MockERC20.address;

    const uniswapFactory = await UniswapV2Factory.deployed();
    await uniswapFactory.createPair(Token.address, MockERC20.address);
    lpTokenAddress = await uniswapFactory.getPair(Token.address, MockERC20.address);
    console.log("Created pair", lpTokenAddress);

    await tokenInstance.grantRole(MINTING_ROLE, LiquidityAdder.address);

    const router = await UniswapV2Router02.deployed();
    const checkPairAddress = await router.getPairAddress(Token.address, MockERC20.address);
    console.log("Pair address check", checkPairAddress);
    // console.log("test1", await uniswapFactory.allPairs(0));
    // console.log("test2", await uniswapFactory.getPair(MockERC20.address, Token.address));
    // console.log("test3", await router.getPairAddress(MockERC20.address, Token.address));

    const liquidityAdder = await LiquidityAdder.deployed();
    await liquidityAdder.addLiquiditySingle(Token.address, "7770000000000000000000", "888000000000000000000");
  }

  await deployer.deploy(Vault,
    lpTokenAddress, // _lpToken
    Token.address,  // _rewardToken
    WETHAddress,    // _WETH
    Reward.address, // _rewardContract,
    800,            // _withdrawalFeePercentage (DENOMINATOR = 10000)
    30000           // _apyPercentage (DENOMINATOR = 10000)
  );

  await tokenInstance.grantRole(MINTING_ROLE, Vault.address);
  await tokenInstance.grantRole(SNAPSHOT_ROLE, Reward.address);

  await tokenInstance.transfer(accounts[1], "20000000000000000000000", {from: accounts[0]});  // 20%
  await tokenInstance.transfer(accounts[2], "1000000000000000000000", {from: accounts[0]});  // 1%

  const rewardInstance = await Reward.deployed();
  // blacklist owner wallet and LP token address
  await rewardInstance.addBlacklist([accounts[0], lpTokenAddress]);
};