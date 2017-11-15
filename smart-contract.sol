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
    uint256 public constant TOTAL_TOKENS_FOR_SOLD = 70000000;//total tokens for sold
    uint256 public constant TOTAL_TOKENS_FOR_COMMAND = 25000000;//total command tokens
    uint256 public constant TOTAL_TOKENS_FOR_BONUSES = 2000000;//total tokens for bonuses
    uint256 public constant TOTAL_TOKENS_FOR_MENTORS = 3000000;//total tokens or mentors

    //variables
    address public beneficiary;//beneficiary address
    address public managmentAddress;//menegment address
    uint256 public totalTokensSolded = 0;//total tokens solded
    MintableToken public token;//Tetarise token contract
    uint8 public currentDiscount = 0;//current discount
    uint256 public collectedWei = 0;// collected wei
    uint256 private collectedWeiInEth = 0;// collected wei in eth
    uint256 public oneSouthenTokenPrice;//token price
    uint256 public currentTokenPriceWithDiscount = 0;// oe token price with discount
    uint256 public aviableTokensForSold = 0;// total tokens for sold
    mapping (address => uint256) funders;//founders list
    //ICO status
    enum State{
      Init,//initial status
      ICORunning,//ICO running
      ICOPaused,//ICO paused
      ICOFinished//ICO finished
    }

    State public currentState = State.Init; //defoult status for start

    //events
    event LogStateSwitch(State newState);// ICO state changed
    event DiscountChanged(uint8 discount);// discount changed
    event NewTokenPrice(uint256 price);// new token price
    event ReturnMoneyToFounder(address recipient, uint256 value);//return money to founder
    event TokenPurchase(address to, address _beneficiary, uint256 tokens);//token purchase

    // Modifiers:
    //only creator
    modifier onlyCreator() {
      require(msg.sender==beneficiary);
      _;
    }
    //onlu for state {state}
    modifier onlyInState(State state){
      require(state==currentState);
      _;
    }
    //only managment address
    modifier onlyManagment() {
      require(msg.sender==managmentAddress || msg.sender==beneficiary);
      _;
    }

    //CrowdFunding contract
    function CrowdFunding(
      address beneficiaryAddressValue,
      string tokenName,
      string tokenSymbol,
      uint8 discount,
      uint256 tokenPrice1500Tokens,
      address addressForManagment
      ){
        require(beneficiaryAddressValue != 0x0);
        require(tokenPrice1500Tokens != 0);
        require(addressForManagment != 0x0);

        managmentAddress = addressForManagment;
        oneSouthenTokenPrice = tokenPrice1500Tokens * 1 ether;
        beneficiary = beneficiaryAddressValue;
        token = createTokenContract(tokenName, tokenSymbol, 0);

        setState(State.Init);
        setDiscount(discount);
    }

    //function for start ICO
    function startICO() public onlyCreator onlyInState(State.Init) {
         setState(State.ICORunning);
         aviableTokensForSold = TOTAL_TOKENS_FOR_SOLD;
         token.mint(beneficiary, getSumTokensForBeneficiary());
    }

    //function for pause ICO
    function pauseICO() public onlyCreator onlyInState(State.ICORunning) {
         setState(State.ICOPaused);
    }

    // function for resume ICO
    function resumeICO() public onlyCreator onlyInState(State.ICOPaused) {
         setState(State.ICORunning);
    }

    //function for finish ICO
    function finishICO() public onlyCreator onlyInState(State.ICORunning) {
         setState(State.ICOFinished);
         token.finishMinting();
    }

    // set CrowdFunding contarct status
    function setState(State _s) internal {
         currentState = _s;
         LogStateSwitch(_s);
    }

    //Create token function
    function createTokenContract (
      string tokenName,
      string tokenSymbol,
      uint256 tokenDecimals
    ) internal returns(MintableToken)
    {
      return new MintableToken(tokenName, tokenSymbol, tokenDecimals);
    }

    //return sum tokens for beneficiary address
    function getSumTokensForBeneficiary() internal returns(uint256) {
      return TOTAL_TOKENS_FOR_COMMAND.add(TOTAL_TOKENS_FOR_MENTORS).add(TOTAL_TOKENS_FOR_BONUSES);
    }

    //Set discount for token price
    function setDiscount(uint8 discount) public onlyCreator {
      currentDiscount = discount;
      DiscountChanged(discount);
      setCurrentTokenPriceWithDiscount();
    }

    //return token price with discount
    function setCurrentTokenPriceWithDiscount() internal {
         uint256 discountSum;
         discountSum = oneSouthenTokenPrice.div(100);
         discountSum = discountSum.mul(currentDiscount);
         currentTokenPriceWithDiscount = oneSouthenTokenPrice.sub(discountSum);
         NewTokenPrice(currentTokenPriceWithDiscount);
    }

    //function run when money sent
    function () payable onlyInState(State.ICORunning){
        require(msg.value!=0);
        if (msg.value < currentTokenPriceWithDiscount.div(1500)){
          returnMoneyToSender();
        }else{
          //uint256 weiAmount = msg.value;
          uint256 tokens = msg.value.div(currentTokenPriceWithDiscount.div(1500));
          if (aviableTokensForSold >= tokens) {
            collectedWei = collectedWei.add(msg.value);
            collectedWeiInEth = collectedWeiInEth.add(msg.value);
            funders[msg.sender] = funders[msg.sender].add(msg.value);
            sendTokens(msg.sender, tokens);
          }else{
            returnMoneyToSender();
          }
        }
   }

   // send tokens to founder address
   function sendTokens(address to, uint256 tokens) internal {
     token.mint(to, tokens);
     totalTokensSolded = totalTokensSolded.add(tokens);
     aviableTokensForSold = TOTAL_TOKENS_FOR_SOLD.sub(totalTokensSolded);
     TokenPurchase(to, beneficiary, tokens);
   }

   //return money to sender
   function returnMoneyToSender() internal{
       address returnAddress = msg.sender;
       returnAddress.transfer(msg.value);
       ReturnMoneyToFounder(returnAddress, msg.value);
   }

   //send collected wei to beneficiary address from contract
   function sendCollectedWeiToBeneficiary() public onlyCreator {
       beneficiary.transfer(collectedWeiInEth);
   }

   //send tokens to founders if founders pay in other currency
   function sendTokensForAnotherCurrency(address to, uint256 tokens) public onlyManagment {
      require(aviableTokensForSold >= tokens);
      sendTokens(to, tokens);
   }
}
