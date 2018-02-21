pragma solidity ^0.4.18;

/**
Советы, best-practice и уязвимости. Раздел постоянно пополняется.
 */

contract ReferalConverterCase {
    /**
     * Есть Реферал - msg.sender, есть размер инвестиций - msg.value
     * Реферал передаёт адрес пригласившего через msg.data.
     * Fallback-функция использует тип callvalue
     * -> который конвертируется в bytes
     * -> который конвертируется в uint
     * -> который конвертируется в address,
     * того, кто привёл реферала
     */

     // Реализация конвертера через Solidity
    function bytesToAddress(bytes source) internal pure returns(address) {
        uint result;
        uint mul = 1;
        for(uint i = 20; i > 0; i--) {
        result += uint8(source[i-1])*mul;
        mul = mul*256;
        }
        return address(result);
    }

     // Реализация конвертера через ассемблер EVM
    function bytesToAddress1(bytes source) internal constant returns(address parsedReferer) {
        assembly {
        parsedReferer := mload(add(source,0x14))
        }
        return parsedReferer;
    }
}

/**
 * Уязвимость заключается в возможности задеплоить скаммерский контракт 
 * и отправить на него немного эфира, дабы вызвать анонимный fallback,
 * который в свою очередь вызывает refund() у атакуемого контракта.
 * Из-за того, что функция вызывается через скаммерский контракт,
 * контекст this сменился, и адрес скаммера - это msg.sender.
 * Соответственно, он переводит деньги сам себе "сквозь" атакуемый контракт,
 * вызывая fallback в скаммерском контракте и, таким образом,
 * несколько раз (сколько укажет, например, через цикл) грабит атакуемый контракт 
 */
contract ReentrancyVulnerableContract {
  mapping (address => uint) balances;
 
  function refund() public {
    msg.sender.transfer(balances[msg.sender]);
    balances[msg.sender] = 0;
  }
 
  function () public payable {
    balances[msg.sender] = balances[msg.sender] + msg.value;
  }
}

contract ReentrancyScammerContract {

  ReentrancyVulnerableContract public reentrancyContract;

  function setReentrancyVulnerableContract(address _reentrancyContract) public {
    reentrancyContract = ReentrancyVulnerableContract(_reentrancyContract);
  }

  function () public payable {
    reentrancyContract.refund();
  }
}

contract Tips {
    /**
    28% смарт-контрактов никак не обрабатывают send(), возвращающий boolean.
    С версии 0.4+ send() отмечен, как deprecated.
    Вместо него небходимо использовать transfer(), останавливающий выполнение всей транзакции,
    т.н. throw, который откатывает все до состояния до вызова, но сжигает газ
     */

    /**
    Вызов constant функций контракта, которые никак не изменяют состояния контракта, по сути - getter'ы,
    тем не менее сжигают газ не хуже non-constant.
    Однако их можно вызвать из JavaScript без траты газа, т.к. только вычислять будет только одна локальная нода.
    Далее полученное значение можно передать уже в "нечистую" функцию.
    И хотя газ съэкономлен на лишнем вызове, внутри принимающей полученное значение функции
    необходимо произвести дополнительную проверку.
    Риск: между обращением к getter'у через web3 и вызывом функции смарт-контракта данные могут поменяться.  
     */
}