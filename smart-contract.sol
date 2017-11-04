pragma solidity ^0.4.16;

library SafeMath {
  function mul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value);
  function approve(address spender, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}


contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint256 _value) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // if (_value > _allowance) throw;

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) revert();

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

contract Ownable {
  address public owner;


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    if (msg.sender != owner) {
      revert();
    }
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}


contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  string public name;
  string public symbol;
  uint256 public decimals;

  bool public mintingFinished = false;

  function MintableToken(
    string _name,
    string _symbol,
    uint256 _decimals
    )
  {
  //  require(_name != '');
  //  require(_symbol != '');
//    require(_decimals != 0);

    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }

  modifier canMint() {
    if(mintingFinished) revert();
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will recieve the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

contract CrowdFunding {
    using SafeMath for uint256;

    //constants
    uint256 public constant TOTAL_TOKENS_FOR_SOLD = 70000000;
    uint256 public constant TOTAL_TOKENS_FOR_COMMAND = 25000000;
    uint256 public constant TOTAL_TOKENS_FOR_BONUSES = 2000000;
    uint256 public constant TOTAL_TOKENS_FOR_MENTORS = 3000000;

    //variables
    address public beneficiary;
    uint256 public totalTokensSolded = 0;
    MintableToken public token;
    uint8 public currentDiscount = 0;
    uint256 public collectedWei = 0;
    uint256 private collectedWeiInEth = 0;
    uint256 public oneSouthenTokenPrice;
    uint256 public currentTokenPriceWithDiscount = 0;
    uint256 public aviableTokensForSold = 0;
    mapping (address => uint256) funders;
    enum State{
      Init,
      ICORunning,
      ICOPaused,
      ICOFinished
    }

    State public currentState = State.Init;

    //events
    event LogStateSwitch(State newState);
    event DiscountChanged(uint8 discount);
    event NewTokenPrice(uint256 price);
    event ReturnMoneyToFounder(address recipient, uint256 value);
    event TokenPurchase(address to, address _beneficiary, uint256 weiAmount, uint256 tokens);

    // Modifiers:
    modifier onlyCreator() {
      require(msg.sender==beneficiary);
      _;
    }
    modifier onlyInState(State state){
      require(state==currentState);
      _;
    }

    function CrowdFunding(
      address beneficiaryAddressValue,
      string tokenName,
      string tokenSymbol,
      uint8 discount,
      uint256 tokenPrice1000Tokens
      ){
        require(beneficiaryAddressValue != 0x0);
        require(tokenPrice1000Tokens != 0);

        oneSouthenTokenPrice = tokenPrice1000Tokens * 1 ether;
        beneficiary = beneficiaryAddressValue;
        token = createTokenContract(tokenName, tokenSymbol, 0);

        setState(State.Init);
        setDiscount(discount);
    }

    function startICO() public onlyCreator onlyInState(State.Init) {
         setState(State.ICORunning);
         aviableTokensForSold = TOTAL_TOKENS_FOR_SOLD;
         token.mint(beneficiary, getSumTokensForBeneficiary());
    }

    function pauseICO() public onlyCreator onlyInState(State.ICORunning) {
         setState(State.ICOPaused);
    }

    function resumeICO() public onlyCreator onlyInState(State.ICOPaused) {
         setState(State.ICORunning);
    }

    function finishICO() public onlyCreator onlyInState(State.ICORunning) {
         setState(State.ICOFinished);
         token.finishMinting();
    }

    function setState(State _s) internal {
         currentState = _s;
         LogStateSwitch(_s);
    }

    function createTokenContract (
      string tokenName,
      string tokenSymbol,
      uint256 tokenDecimals
    ) internal returns(MintableToken)
    {
      return new MintableToken(tokenName, tokenSymbol, tokenDecimals);
    }

    function getSumTokensForBeneficiary() internal returns(uint256) {
      return TOTAL_TOKENS_FOR_COMMAND.add(TOTAL_TOKENS_FOR_MENTORS).add(TOTAL_TOKENS_FOR_BONUSES);
    }

    function setDiscount(uint8 discount) public onlyCreator {
      currentDiscount = discount;
      DiscountChanged(discount);
      setCurrentTokenPriceWithDiscount();
    }

    function setCurrentTokenPriceWithDiscount() internal {
         uint256 discountSum;
         discountSum = oneSouthenTokenPrice.div(100);
         discountSum = discountSum.mul(currentDiscount);
         currentTokenPriceWithDiscount = oneSouthenTokenPrice.sub(discountSum);
         NewTokenPrice(currentTokenPriceWithDiscount);
    }

    function () payable onlyInState(State.ICORunning){
        require(msg.value!=0);
        if (msg.value < currentTokenPriceWithDiscount){
          returnMoneyToSender();
        }else{
          uint256 weiAmount = msg.value;
          uint256 tokens = weiAmount.div(currentTokenPriceWithDiscount.div(1000));
          if (aviableTokensForSold >= tokens) {
            collectedWei = collectedWei.add(weiAmount);
            collectedWeiInEth = collectedWeiInEth.add(weiAmount);
            funders[msg.sender] = funders[msg.sender].add(weiAmount);
            sendTokens(msg.sender, tokens, weiAmount);
          }else{
            returnMoneyToSender();
          }
        }
   }

   function sendTokens(address to, uint256 tokens, uint256 weiAmount) internal {
     token.mint(to, tokens);
     totalTokensSolded = totalTokensSolded.add(tokens);
     aviableTokensForSold = TOTAL_TOKENS_FOR_SOLD.sub(totalTokensSolded);
     TokenPurchase(to, beneficiary, weiAmount, tokens);
   }

   function returnMoneyToSender() internal{
       address returnAddress = msg.sender;
       returnAddress.transfer(msg.value);
       ReturnMoneyToFounder(returnAddress, msg.value);
   }

   function sendCollectedWeiToBeneficiary() public onlyCreator {
       beneficiary.transfer(collectedWeiInEth);
   }

   function sendTokensForAnotherCurrency(address to, uint256 tokens, uint256 weiAmount) public onlyCreator onlyInState(State.ICORunning){
      require(aviableTokensForSold >= tokens);
      sendTokens(to, tokens, weiAmount);
      funders[to] = funders[to].add(weiAmount);
   }
}
