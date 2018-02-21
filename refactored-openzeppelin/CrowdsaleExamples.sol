pragma solidity ^0.4.18;

import "./TokenExamples.sol";
import "../Ownable.sol";
import "../SafeMath.sol";

contract Crowdsale {
  using SafeMath for uint256;

  MintableToken public token;
  uint256 public startTime;
  uint256 public endTime;
  address public wallet;
  uint256 public rate; // Количество токенов за 1 wei
  uint256 public weiRaised;

  event TokenPurchase(address indexed _purchaser, address indexed _beneficiary, uint256 _value, uint256 _amount);

  function Crowdsale(
      uint256 _startTime, 
      uint256 _endTime, 
      uint256 _rate, 
      address _wallet
      ) public {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != address(0));
    
    token = createTokenContract();
    startTime = _startTime;
    endTime = _endTime; 
    rate = _rate;
    wallet = _wallet;
  }

  function createTokenContract() internal returns (MintableToken) {
      return new MintableToken();
  }

  function () external payable {
    buyTokens(msg.sender);
  }

  /**
   * Низкоуровневая функция для покупки токенов
   */
  function buyTokens(address _beneficiary) public payable {
    require(_beneficiary != address(0));
    require(validPurchase());

    uint256 weiAmount = msg.value;
    
    uint256 tokens = weiAmount.mul(rate);

    weiRaised = weiRaised.add(weiAmount);

    token.mint(_beneficiary, tokens);

    TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);

    forwardFunds();
  }

  /**
   * Отправляет эфиры на кошелёк для сбора средств
   */
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

  /**
   * Валидация покупки токенов
   */
  function validPurchase() internal constant returns (bool) {
      bool withinPeriod = now >= startTime && now <= endTime;
      bool nonZeroPurchase = msg.value != 0;
      return withinPeriod && nonZeroPurchase;
  }

  /**
   * Проверяет, закончилось ли ICO
   */
  function hasEnded() public constant returns (bool) {
      return now > endTime;
  }
}

contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public hardCap;

  function CappedCrowdsale(uint256 _hardCap) public {
    require(_hardCap > 0);
    hardCap = _hardCap;
  }

  /**
   * Проверяет, достигнут ли hardcap
   */
  function validPurchase() internal constant returns (bool) {
      bool withinCap = weiRaised.add(msg.value) <= hardCap;
      return super.validPurchase() && withinPeriod;
  }

  /**
   * Проверяет, проданы ли все токены
   */
  function hasEnded() public constant returns (bool) {
      bool hardCapReached = weiRaised >= hardCap;
      return super.hasEnded() && hardCapReached;
  }

}