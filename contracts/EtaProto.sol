// This contract carries out the eta protocol to exchange cosh tokens
/* Zeta Protocol */

pragma solidity ^0.4.25;
import "./Tokens.sol";

contract EtaProto {

    address public owner;   // who deploy the contract
    Tokens public CT;   // Token contract instance
    uint256 public i; // random variable to generate uuid of transaction

    // user defined datatype to chech order Status
    enum Status {open, closed, locked, canceled }

    // Order details
    struct Order {
        address maker;  // address of the user who made the request
        string tokenHave;   // token which maker has
        string tokenNeed;   // token which maker need
        uint256 quantity;   // qantity of tokens to exchange
        uint256 value;      // market value of tokens to exchange
        uint256 timestamp;  // time of placing the order
        Status status;  // check the status of the order
    }

    // deployes the contract
    constructor (address addr) public {
        owner = msg.sender; // sets the deployer as owner
        CT = Tokens(addr);  // instance of token contract
    }

    // maps the unique byte32 id to open and locked orders
    mapping (bytes32 => Order) public listed_orders;

    // maps the unique byte32 id to canceled and closed orders
    mapping (bytes32 => Order) public completed_orders;
    
    // called by user who wants to exchange the token
    function makeOrder(string _tokenHave, string _tokenNeed, uint256 _quantity) public payable returns(bool){
        
        require(CT.getTokens(_tokenHave) && CT.getTokens(_tokenNeed));
        // checks if the tokens which user mentiond are available or not
        
        address tokensHave = CT.getAdd(_tokenHave);
        // get address of the token which use rhas

        uint256 bal = CT.getBalance(msg.sender, tokensHave);
        // gets the balance of the user

        require(bal >= _quantity);
        //checks if user has sufficient balance
        
        bytes32 order_id = keccak256(i);
        // generates uuid for the order
        
        listed_orders[order_id].maker = msg.sender;
        listed_orders[order_id].tokenHave = _tokenHave;
        listed_orders[order_id].tokenNeed = _tokenNeed;
        listed_orders[order_id].quantity = _quantity;
        listed_orders[order_id].value = _quantity;
        listed_orders[order_id].timestamp = now ;
        listed_orders[order_id].status = Status.open;
        
        bool suc = CT.transferProto(msg.sender, tokensHave,  _quantity);
        i++;
        return suc;
    }
    
    // This function cancels the listed order.
    function cancel(bytes32 id) public payable{
        
        require(msg.sender == listed_orders[id].maker);
        // checks if the function is called by the maker only

        address tokensHave = CT.getAdd(listed_orders[id].tokenHave);
        CT.transferProtoEx(address(this), tokensHave, msg.sender, listed_orders[id].value);
        // above lines get the contract address of the token and transfer it back to the user(maker)
        
        listed_orders[id].status = Status.canceled;
        completed_orders[id] = listed_orders[id];
        delete listed_orders[id];
        // above lines change the status of the order to cancels and moce it to completed orders.
    }
    
    
    /* this function is called by any user who checks the listed open orders and
       meets his needs (the value and the token in exchange) */
    /* this is payable because the user who calls this function will directly send the funds to the maker
       and will automatically receive the funds from the contract which are sent by maker.*/
    function take(bytes32 id) public payable{
        
        address tokensGive = CT.getAdd(listed_orders[id].tokenNeed);
        uint256 bal = CT.getBalance(msg.sender, tokensTake);
        // above to lines get the contract address of the token which maker need and 
        // then gets the balance of the msg.sender for that token
        
        require(bal >= listed_orders[id].value);
        // checks if the mas.sender(taker) have sufficient balance or not

        address tokensTake = CT.getAdd(listed_orders[id].tokenHave);
        // this gets the address of the token which maker have with him

        listed_orders[id].status = Status.locked; 
        // change the order status

        CT.transferProtoEx(msg.sender, tokensGive, listed_orders[id].maker, listed_orders[id].value);  
        // commence transaction from msg.sender to maker

        CT.transferProtoEx(address(this),tokensTake, msg.sender, listed_orders[id].value);  
        // commence transaction from contract to msg.sender

        listed_orders[id].status = Status.closed;            
        completed_orders[id] = listed_orders[id];
        delete listed_orders[id];
        // above lines change the status of the order and sends it to completed orders.

    }
}