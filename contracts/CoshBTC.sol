pragma solidity ^0.4.25 ;
import "./CoshToken.sol";

contract CoshBTC {
    string  public name = "CoshBTC";
    string  public symbol = "C_BTC";
    string  public standard = "CoshBTC v1.0";
    uint256 public totalSupply;
    CoshToken public CT;
    
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
    mapping(address => mapping(address => uint256)) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor (uint256 _initialSupply, address addr) public {
        CT = CoshToken(addr);
        if(CT.getTokens(name))
            revert();
        balanceOf[msg.sender][address(this)] = _initialSupply;
        totalSupply = _initialSupply;
        CT.setNativeTokens(address(this), name, _initialSupply);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender][address(this)] >= _value);

        balanceOf[msg.sender][address(this)] -= _value;
        balanceOf[_to][address(this)] += _value;

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balanceOf[_from][address(this)]);
        require(_value <= allowance[_from][msg.sender]);

        balanceOf[_from][address(this)] -= _value;
        balanceOf[_to][address(this)] += _value;

        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);

        return true;
    }
}
