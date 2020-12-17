interface IWETH {

  function deposit() external payable;

  function transfer(address _to, uint _value) external returns (bool);

  function withdraw(uint _amount) external;
}