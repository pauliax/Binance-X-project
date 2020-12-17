interface IToken {

  function mint(address _beneficiary, uint _amount) external;

  function burn(uint _amount) external;

  function snapshot() external returns (uint);

  function transferAndCall(address _to, uint _tokens, bytes calldata _data) external returns (bool);
}