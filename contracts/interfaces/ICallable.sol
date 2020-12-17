interface ICallable {

  function tokenCallback(address _from, uint _tokens, bytes calldata _data) external returns (bool);

}