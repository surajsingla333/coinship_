pragma solidity ^0.4.25;
import "./CoshToken.sol";

contract EtaProto {
    
    address public maker;
    address public owner;
    CoshToken public CT;
    mapping(address => mapping(address => uint256)) public balanceOf;

    enum Status {open, closed, locked, canceled }

    struct Order {
        string tokenHave;
        string tokenNeed;
        uint256 quantity;
        uint256 value;
        uint256 timestamp;
        Status status;
    }

    constructor (address addr) public {
        owner = msg.sender;
        CT = CoshToken(addr);
    }

    mapping (address => Order) public listed_orders;
    mapping (address => Order) public completed_orders;

    function makeOrder(string _tokenHave, string _tokenNeed, uint256 _quantity) public payable {
        address tokensHave = CT.getAdd(_tokenHave);
        require(balanceOf[msg.sender][tokensHave] >= _quantity && CT.getTokens(_tokenHave) && CT.getTokens(_tokenNeed));
        
        maker = msg.sender;
        listed_orders[maker].tokenHave = _tokenHave;
        listed_orders[maker].tokenNeed = _tokenNeed;
        listed_orders[maker].quantity = _quantity;
        listed_orders[maker].value = _quantity;
        listed_orders[maker].timestamp = now ;
        listed_orders[maker].status = Status.open;
        
        address(this).transfer(_quantity);
    }
    
    function cancel() public{
        require(msg.sender == maker);
        maker.transfer(listed_orders[maker].value);
        listed_orders[maker].status = Status.canceled;
        completed_orders[maker] = listed_orders[maker];
        delete listed_orders[maker];
    }
    
    function take(string _tokenTake) public payable {
            
        /* this function is called by any user who checks the listed open orders and
           meets his needs (the value and the token in exchange) */
        /* this is payable because the user who calls this function will directly send the funds to the maker
           and will automatically receive the funds from the contract which are sent by maker.*/
        address tokensTake = CT.getAdd(_tokenTake);
        require(balanceOf[msg.sender][tokensTake] >= listed_orders[maker].value && 
        keccak256(listed_orders[maker].tokenNeed) == keccak256(_tokenTake)
        && CT.getTokens(_tokenTake)); // check requirements

        listed_orders[maker].status = Status.locked; // change the order status

        maker.transfer(listed_orders[maker].value);  // commence transaction from msg.sender to maker
        msg.sender.transfer(address(this).balance);  // commence transaction from contract to msg.sender

        listed_orders[maker].status = Status.closed;                 // change order status
        completed_orders[maker] = listed_orders[maker];
        delete listed_orders[maker];
    }
}