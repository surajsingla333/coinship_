pragma solidity ^0.4.25;

contract CoshToken {
    string  public name = "Cosh Token";
    string  public symbol = "COSH";
    string  public standard = "Cosh Token v1.0";
    uint256 public totalSupply;
    address public owner;
    uint256 public i;
    
    struct nativeTokens {
        string name;
        uint256 amount;
    }
    
    mapping (uint256 => nativeTokens) public tokens;
    
    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function setNativeTokens(string _name, uint256 _initialSupply) public {
        tokens[i].name = _name;
        tokens[i].amount = _initialSupply;
        i++;
    }
    
    function getTokens(string _name) public view returns (bool){
        uint256 j=1;
        while(keccak256(tokens[j].name) != keccak256("")){
            if(keccak256(_name) == keccak256(tokens[j].name))
                return true;
            else {
                j++;
                continue;
            }
        }
        return false;
    }
    
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor (uint256 _initialSupply) public {
        balanceOf[msg.sender] = _initialSupply;
        totalSupply = _initialSupply;
        owner = msg.sender;
        i=1;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);

        return true;
    }
}
