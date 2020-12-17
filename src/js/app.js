const PAIR_ADDRESS = '0x67D46Fc5F544B431D601e547c8A1fC21Ff71a141';

const PAIR_ABI = [
  {
    "constant": false,
    "inputs": [
      {
        "internalType": "address",
        "name": "spender",
        "type": "address"
      },
      {
        "internalType": "uint256",
        "name": "value",
        "type": "uint256"
      }
    ],
    "name": "approve",
    "outputs": [
      {
        "internalType": "bool",
        "name": "",
        "type": "bool"
      }
    ],
    "payable": false,
    "stateMutability": "nonpayable",
    "type": "function"
  },
];

App = {
  web3Provider: null,
  contracts: {},
  tokenBalance: null,
  lpBalance: null,
  stakeBalance: null,
  rewardBalance: null,
  rewardTokenBalance: null,

  init: async function () {
    return await App.initWeb3();
  },

  initWeb3: async function () {
    // Modern dapp browsers...
    if (window.ethereum) {
      App.web3Provider = window.ethereum;
      try {
        // Request account access
        await window.ethereum.enable();
      } catch (error) {
        // User denied account access...
        console.error("User denied account access")
      }
    }
    // Legacy dapp browsers...
    else if (window.web3) {
      App.web3Provider = window.web3.currentProvider;
    }
    // If no injected web3 instance is detected, fall back to Ganache
    else {
      App.web3Provider = new Web3.providers.HttpProvider('http://localhost:7545');
    }
    web3 = new Web3(App.web3Provider);

    return App.initContract();
  },

  initContract: function () {
    $.getJSON('contracts/Token.json', function (data) {
      App.contracts.Token = TruffleContract(data);
      App.contracts.Token.setProvider(App.web3Provider);
      return App.loadTokenData();
    });
    $.getJSON('contracts/Vault.json', function (data) {
      App.contracts.Vault = TruffleContract(data);
      App.contracts.Vault.setProvider(App.web3Provider);
      App.loadVaultMetadata();
      return App.loadVaultData();
    });
    $.getJSON('contracts/Reward.json', function (data) {
      App.contracts.Reward = TruffleContract(data);
      App.contracts.Reward.setProvider(App.web3Provider);
      return App.loadRewardData();
    });

    App.contracts.Pair = web3.eth.contract(PAIR_ABI).at(PAIR_ADDRESS);
    console.log("Pair contract", App.contracts.Pair);

    return App.bindEvents();
  },

  bindEvents: function () {
    $(document).on('click', '#stakeBtn', App.stakeFunc);
    $(document).on('click', '#withdrawBtn', App.withdrawFunc);
    $(document).on('click', '#claimBtn', App.claimFun);

    $(document).on('click', '.btn-claim', App.claim);
  },

  loadTokenData: function () {
    let TokenInstance;

    web3.eth.getAccounts(function (error, accounts) {
      if (error) {
        console.log(error);
      }

      const account = accounts[0];
      $('#account').text(account);

      App.contracts.Token.deployed().then(function (instance) {
        TokenInstance = instance;
        console.log(TokenInstance);
        return TokenInstance.balanceOf.call(account);
      }).then(function (balance) {
        console.log("User balance", balance.toString());
        App.tokenBalance = balance;
        const balanceFormatted = formatNumber(parseFloat(web3.fromWei(App.tokenBalance, 'ether')), 5);
        $('#tokenBalance').text(balanceFormatted);
      }).catch(function (err) {
        console.log(err.message);
      });
    });
  },

  loadVaultData: function () {
    let VaultInstance;

    web3.eth.getAccounts(function (error, accounts) {
      if (error) {
        console.log(error);
      }

      App.contracts.Vault.deployed().then(function (instance) {
        VaultInstance = instance;
        console.log(VaultInstance);
        return VaultInstance.getUserInfoFull.call();
      }).then(function (userInfo) {
        console.log("User info", userInfo.toString());

        App.lpBalance = userInfo[4];
        App.stakeBalance = userInfo[0];
        App.rewardBalance = userInfo[3];
        App.rewardTokenBalance = userInfo[5];

        const myLpTokens = formatNumber(parseFloat(web3.fromWei(App.lpBalance, 'ether')), 5);
        $('#lpBalance').text(myLpTokens);

        const myStake = formatNumber(parseFloat(web3.fromWei(App.stakeBalance, 'ether')), 5);
        $('#stakeBalance').text(myStake);

        const myRewards = formatNumber(parseFloat(web3.fromWei(App.rewardBalance, 'ether')), 5);
        $('#rewardBalance').text(myRewards);

        const rewardTokenBalance = formatNumber(parseFloat(web3.fromWei(App.rewardTokenBalance, 'ether')), 5);
        $('#rewardTokenBalance').text(rewardTokenBalance);
      }).catch(function (err) {
        console.log(err.message);
      });
    });
  },

  loadVaultMetadata: function () {
    const DENOMINATOR = 10000;
    let VaultInstance;

    web3.eth.getAccounts(function (error, accounts) {
      if (error) {
        console.log(error);
      }

      App.contracts.Vault.deployed().then(function (instance) {
        VaultInstance = instance;
        console.log(VaultInstance);

        VaultInstance.totalStaked.call().then(function (totalStaked) {
          console.log("Total staked", totalStaked.toString());
          const totalStakedTokens = formatNumber(parseFloat(web3.fromWei(totalStaked, 'ether')), 5);
          $('#totalStaked').text(totalStakedTokens);
        });

        VaultInstance.apyPercentage.call().then(function (apyPercentage) {
          console.log("APY %", apyPercentage.toString());
          const apy = apyPercentage.mul(100).div(DENOMINATOR).toString();
          $('#apyPercentage').text(apy);
        });

        VaultInstance.withdrawalFeePercentage.call().then(function (withdrawalFeePercentage) {
          console.log("Withdrawal %", withdrawalFeePercentage.toString());
          const withdrawalFee = withdrawalFeePercentage.mul(100).div(DENOMINATOR).toString();
          $('#withdrawalFeePercentage').text(withdrawalFee);
        });
      }).catch(function (err) {
        console.log(err.message);
      });
    });
  },

  loadRewardData: function () {
    let RewardInstance;

    web3.eth.getAccounts(function (error, accounts) {
      if (error) {
        console.log(error);
      }

      // const account = accounts[0];

      App.contracts.Reward.deployed().then(function (instance) {
        RewardInstance = instance;
        console.log(RewardInstance);
        return RewardInstance.getNumberOfRewards.call();
      }).then(function (numberOfRewards) {
        console.log("numberOfRewards", numberOfRewards.toString());

        let dataRow = $('#dataRow');
        dataRow.find(".tempItem").remove();
        const template = $('#template');

        for (let i = 0; i < numberOfRewards; i++) {
          RewardInstance.getMyShare.call(i)
            .then(function (myShare) {
              console.log("myShare", myShare.toString(), i);
              if (myShare && !myShare.isZero()) {
                RewardInstance.getRewardInfo.call(i)
                  .then(function (rewardInfo) {
                    console.log("rewardInfo", rewardInfo.toString());

                    const rewardAmount = rewardInfo[2];
                    const rewardAmountFormatted = formatNumber(parseFloat(web3.fromWei(rewardAmount, 'ether')), 5);

                    const myShareFormatted = formatNumber(parseFloat(web3.fromWei(myShare, 'ether')), 5);

                    template.find('.reward-title').text(i + 1);
                    template.find('.reward-amount').text(rewardAmountFormatted);
                    template.find('.reward-my-share').text(myShareFormatted);
                    template.find('.btn-claim').attr('data-id', i);

                    dataRow.append(template.html());
                  });
              }
            });
        }
      }).catch(function (err) {
        console.log(err.message);
      });
    });
  },

  stakeFunc: function (event) {
    event.preventDefault();

    const amount = parseFloat($('#stakeAmount').val());
    console.log("stake amount", amount);
    const amountWithDecimals = web3.toWei(amount, 'ether');
    console.log("stake amount with decimals", amountWithDecimals.toString());

    let VaultInstance;

    web3.eth.getAccounts(function (error, accounts) {
      if (error) {
        console.error(error);
        return;
      }

      const account = accounts[0];

      App.contracts.Vault.deployed().then(function (instance) {
        VaultInstance = instance;

        VaultInstance.getLpAllowance.call().then(function (allowance) {
          console.log("LP allowance", allowance.toString());

          if (allowance.lt(amountWithDecimals)) {
            console.log("Need to approve first. Has to be done only once");
            return App.approveAndStakeFunc(account, amountWithDecimals);
          } else {
            return App.stakeOnlyFunc(account, amountWithDecimals);
          }
        });
      });
    });
  },

  approveAndStakeFunc: function (account, amountWithDecimals) {
    const MAX_AMOUNT = -1;
    const Pair = App.contracts.Pair;
    const VaultInstance = App.contracts.Vault;

    Pair.approve(VaultInstance.address, MAX_AMOUNT, {from: account}, function (error, txHash) {
      if (error) {
        console.error(error);
        return;
      }

      console.log('TX hash', txHash);

      getTransactionReceiptMined(txHash, 2000, function (error, receipt) {
        if (error) {
          console.error(error);
          return;
        }

        if (receipt.status === '0x1') {
          console.log('TX mined successfully');
          return App.stakeOnlyFunc(account, amountWithDecimals);
        } else {
          console.log('TX failed. Please check Etherscan for more details');
        }
      })
    });
  },

  stakeOnlyFunc: function (account, amountWithDecimals) {
    let VaultInstance;

    web3.eth.getAccounts(function (error, accounts) {
      if (error) {
        console.error(error);
        return;
      }

      const account = accounts[0];

      App.contracts.Vault.deployed().then(function (instance) {
        VaultInstance = instance;

        VaultInstance.stake(amountWithDecimals.toString(), {from: account}).then(function (txHash) {
          console.log('TX hash', txHash);
          App.loadVaultMetadata();
          return App.loadVaultData();
        });
      });
    });
  },

  withdrawFunc: function (event) {
    event.preventDefault();

    const amount = parseFloat($('#withdrawAmount').val());
    console.log("withdraw amount", amount);
    const amountWithDecimals = web3.toWei(amount, 'ether');
    console.log("withdraw amount with decimals", amountWithDecimals.toString());

    let VaultInstance;

    web3.eth.getAccounts(function (error, accounts) {
      if (error) {
        console.error(error);
        return;
      }

      const account = accounts[0];

      App.contracts.Vault.deployed().then(function (instance) {
        VaultInstance = instance;

        VaultInstance.withdraw(amountWithDecimals.toString(), {from: account}).then(function (txHash) {
          console.log('TX hash', txHash);
          App.loadVaultMetadata();
          return App.loadVaultData();
        });
      });
    });
  },

  claimFun: function (event) {
    event.preventDefault();

    let VaultInstance;

    web3.eth.getAccounts(function (error, accounts) {
      if (error) {
        console.error(error);
        return;
      }

      const account = accounts[0];

      App.contracts.Vault.deployed().then(function (instance) {
        VaultInstance = instance;

        VaultInstance.claim({from: account}).then(function (txHash) {
          console.log('TX hash', txHash);
          return App.loadVaultData();
        });
      });
    });
  },

  claim: function (event) {
    event.preventDefault();

    const rewardId = parseInt($(event.target).data('id'));
    console.log("Claim", rewardId);

    let RewardInstance;

    web3.eth.getAccounts(function (error, accounts) {
      if (error) {
        console.error(error);
        return;
      }

      const account = accounts[0];

      App.contracts.Reward.deployed().then(function (instance) {
        RewardInstance = instance;

        RewardInstance.claim(rewardId, {from: account}).then(function (txHash) {
          console.log('TX hash', txHash);
          return App.loadRewardData();
        });
      });
    });
  },
};

const getTransactionReceiptMined = (txnHash, interval, callback) => {
  let transactionReceiptAsync;
  interval = interval ? interval : 1000;
  transactionReceiptAsync = function (txnHash, resolve, reject) {
    try {
      web3.eth.getTransactionReceipt(txnHash, function (error, receipt) {
        if (receipt == null) {
          setTimeout(function () {
            transactionReceiptAsync(txnHash, resolve, reject);
          }, interval);
        } else {
          // resolve(receipt);
          callback(error, receipt);
        }
      });
    } catch (e) {
      console.error(e);
      // reject(e);
      callback(e);
    }
  };

  if (Array.isArray(txnHash)) {
    let promises = [];
    txnHash.forEach(function (oneTxHash) {
      promises.push(web3.eth.getTransactionReceiptMined(oneTxHash, interval));
    });
    return Promise.all(promises);
  } else {
    return new Promise(function (resolve, reject) {
      transactionReceiptAsync(txnHash, resolve, reject);
    });
  }
};

function log10(val) {
  return Math.log(val) / Math.log(10);
}

function formatNumber(n, maxDecimals) {
  let zeroes = Math.floor(log10(Math.abs(n)));
  let postfix = '';
  if (zeroes >= 9) {
    postfix = 'B';
    n /= 1e9;
    zeroes -= 9;
  } else if (zeroes >= 6) {
    postfix = 'M';
    n /= 1e6;
    zeroes -= 6;
  }

  zeroes = Math.min(maxDecimals, maxDecimals - zeroes);

  return (
    n.toLocaleString(undefined, {
      minimumFractionDigits: 0,
      maximumFractionDigits: Math.max(zeroes, 0)
    }) + postfix
  );
}

$(function () {
  $(window).load(function () {
    App.init();
  });
});