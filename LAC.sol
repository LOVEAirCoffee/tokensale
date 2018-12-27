pragma solidity ^0.4.0;

/******************************************/
/*              SafeMath                  */
/******************************************/
library SafeMath {
	function mul(uint256 a, uint256 b) internal constant returns (uint256) {
		uint256 c = a * b;
		assert(a == 0 || c / a == b);
		return c;
	}

	function div(uint256 a, uint256 b) internal constant returns (uint256) {
		uint256 c = a / b;
		return c;
	}

	function sub(uint256 a, uint256 b) internal constant returns (uint256) {
		assert(b <= a);
		return a - b;
	}

	function add(uint256 a, uint256 b) internal constant returns (uint256) {
		uint256 c = a + b;
		assert(c >= a);
		return c;
	}
}

/******************************************/
/*              ERC20 Basic               */
/******************************************/
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/******************************************/
/*                  ERC20                */
/******************************************/
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/******************************************/
/*              Basic Token               */
/******************************************/
contract BasicToken is ERC20Basic {
    
  using SafeMath for uint256;
  
  bool enabledTransfer =false;
  
  modifier openedTransfer {
        require(enabledTransfer);
        _;
    }

  mapping(address => uint256) balances;

  function transfer(address _to, uint256 _value) openedTransfer returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}

/******************************************/
/*              Standard Token            */
/******************************************/
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;

  function transferFrom(address _from, address _to, uint256 _value) openedTransfer returns (bool) {
    var _allowance = allowed[_from][msg.sender];

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) openedTransfer returns (bool) {

    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

/******************************************/
/*              Ownable                   */
/******************************************/
contract Ownable {
    
   address public owner;

    function Ownable() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));      
    owner = newOwner;
  }
}


/******************************************/
/*          Crowdsale                     */
/******************************************/
contract Crowdsale is Ownable,StandardToken {
    
    using SafeMath for uint;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    enum State { Disabled, Enabled }
    
    State public state = State.Disabled;
    
    uint public stageNr=0;
    
    uint256 public maxTokensForSale;

    uint256 public rate;
    
    bool refundPayAfterTokenSale=false;
    
    mapping(uint => uint256) public stages;
    
    mapping(address => uint256) public balances;
    
    function setTransfer(bool value) onlyOwner returns(bool){
        enabledTransfer=value;
        return enabledTransfer;
    }
    
    function startTokensSale(uint256 _maxTokensForSale,uint _rate,bool _refundPayAfterTokenSale) public onlyOwner {
       require(state == State.Disabled);
        
        stageNr+=1;
        maxTokensForSale=_maxTokensForSale.mul(1 ether);
        rate=_rate;
        refundPayAfterTokenSale=_refundPayAfterTokenSale;
        state = State.Enabled;
    }
    
    function finishSellingTokens() public onlyOwner {
        require(state == State.Enabled);
        state = State.Disabled;
    }

    function() external payable {
        require(state == State.Enabled);
        require(msg.value > 0);
        require(msg.sender != 0x0);
        
        if(refundPayAfterTokenSale){
            uint256 tokens=msg.value.mul(rate);
            balances[msg.sender] = balances[msg.sender].add(tokens);
            balances[owner] = balances[owner].sub(tokens);
            Transfer(owner, msg.sender, tokens);   
        }
        
        owner.transfer(msg.value);
    }
  
  // transfer balance to owner
	function withdrawEther() onlyOwner {
		owner.transfer(this.balance);
	}
}

/******************************************/
/*          LAC Token Coin                */
/******************************************/
contract LACTokenCoin is Crowdsale {
    
    string public constant name = "LOVE Air Coffee";
    
    string public constant symbol = "LAC";
    
    uint32 public constant decimals = 18;
    
    function LACTokenCoin(uint256 _totalSupply){
        totalSupply=_totalSupply.mul(1 ether);
        balances[msg.sender]=totalSupply;
        Transfer(address(0x0), msg.sender, totalSupply);
    }
}
