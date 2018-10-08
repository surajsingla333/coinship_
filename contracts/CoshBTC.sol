// erc20 token which will be used to exchange BTC with other crypto currencies
// 1 CoshBTC = 1 BTC
/* CoshBTC  

    @author: Suraj singla */

    
pragma solidity ^0.4.25 ;
import "./Tokens.sol";

contract CoshBTC {
    string  public name = "CoshBTC"; //name of the token
    string  public symbol = "C_BTC"; // symbol of the token
    string  public standard = "CoshBTC v1.0"; // standard of token
    uint256 public totalSupply; // stores total number of tokens
    Tokens public CT; // get the Token.sol instance
    
    /* creates the contract with initialSupply and address of Tokens contract*/
    constructor (uint256 _initialSupply, address addr) public {
        CT = Tokens(addr); // stores the Token instance in CT
        
        if(CT.getTokens(name))  // ensures that the contract in created only once
            revert();
        
        // sets the initialSupply(also the total supply) to the msg.sender(who creates the contract)    
        CT.setBalance(msg.sender, address(this), _initialSupply); 
        
        totalSupply = _initialSupply;
        
        // sets the token in Native tokens mapping
        CT.setNativeTokens(address(this), name, "Bitcoin", _initialSupply);
    }
    
    /* basic erc20 function which transfer funds (tokens) from msg.sender
        to the address which is given. */
    function transfer(address _to, uint256 _value) public payable returns(bool){
        address _from = msg.sender;
        bool suc =CT.transferTokens(_from, _to, _value);
        return suc;
    }
    
    /* basic erc20 function which approve  _spender to transfer
        funds (tokens) from msg.sender's account. */
    function approve(address _spender, uint256 _value) public returns (bool) {
        address _approver = msg.sender;
        bool suc = CT.approve(_approver, _spender, _value);
        return suc;
    }

    /* basic erc20 function which transfer funds (tokens) from _from account
        to the address which is given. */
    function transferFrom(address _from, address _to, uint256 _value) public payable returns (bool) {
        address _requester = msg.sender;
        bool suc = CT.transferFrom(_requester, _from, _to, _value);
        return suc;
    }
}
