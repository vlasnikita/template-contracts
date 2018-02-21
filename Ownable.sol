pragma solidity ^0.4.18;


contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * Создатель контракта становится его единственным владельцем, навсегда. 
   * Приватное поле -> недоступно за пределами контракта
   */
  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * Передача права собственности на контракт указанному адресу
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}