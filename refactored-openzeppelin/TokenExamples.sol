pragma solidity ^0.4.18;

import "../ERC20.sol";
import "../Ownable.sol";
import "../SafeMath.sol";

contract ERC20Basic {
  uint256 public totalSupply;

  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
}

contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender) public view returns (uint256);
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
  function approve(address _spender, uint256 _value) public returns (bool);
  
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
  * Переводит токены на заданный адрес 
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // Если недостаточно средств SafeMath выбрасывает ошибку 
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * Получает баланс переданного адреса 
  */
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * Переводит токены с одного адреса на другой
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * Подтверждение для указанного адреса на перевод указанного количества токенов от msg.sender'a
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * Возвращает количество токенов, которые owner'ом разрешено потратить spender'у (или то, сколько от этого осталось) 
   */
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  /**
   * Повышает количество токенов, которое указанный адрес может тратить
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * Снижает количество токенов, которое указанный адрес может тратить
   */
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;

  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  /**
   * Выпуск ("чеканка") токенов на указанный адрес
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * Запрет на дальнейший выпуск токенов
   */
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

contract BurnableToken is BasicToken {

  event Burn(address indexed _burner, uint256 _value);

  /**
   * Сжигает указанное количество токенов.
   */
  function burn(uint256 _value) public {
    // Проверяем отправляемое в топку количество на "положительность", чтобы не жечь попусту газ
    require(_value > 0);
    require(_value <= balances[msg.sender]);

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    Burn(burner, _value);
    Transfer(burner, address(0), _value);
  }
}