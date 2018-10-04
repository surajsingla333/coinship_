pragma solidity ^0.4.25;
import "./CoshToken.sol";

contract ZetaProto {
    
    address maker;
    address owner;
    address taker;
    uint256 public value;
    uint256 public commission;
    uint256 public upperPrice;
    uint256 public lowerPrice;
    CoshToken public CT;
    mapping(address => mapping(address => uint256)) public balanceOf;
    address tokensTake;

    enum Status {open, closed, locked, canceled }

    struct Order {
        string currencyName;
        string currencyAddress;
        string toCosh;
        uint256 quantity;
        uint256 timestamp;
        Status status;
    }

    constructor (address addr) public {
        owner = msg.sender;
        CT = CoshToken(addr);
    }
    
    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function setCommission (uint256 _com, uint256 _lowerPrice, uint256 _upperPrice) isOwner {
        commission = _com;
        lowerPrice = _lowerPrice;
        upperPrice = _upperPrice;
    }
    
    function getCommission() public returns(uint256) {
        uint256 com;
        if(value <= lowerPrice) {
            com = commission;
        }
        else if (value >lowerPrice && value <= upperPrice) {
            com = (commission*90)/100;
        }
        else {
            com = (commission*80)/100;
        }
        return com;
    }
    
    mapping (address => Order) public listed_orders;
    mapping (address => Order) public completed_orders;
    mapping (address => bool) public confirmation;

    function makeOrder(string _currencyName, string _toCosh, string _currencyAddress, uint256 _quantity) public {
        require(CT.getTokens(_toCosh));
        maker = msg.sender;
        value = _quantity;
        getCommission();
        listed_orders[maker].currencyName = _currencyName;
        listed_orders[maker].currencyAddress = _currencyAddress;
        listed_orders[maker].toCosh = _toCosh;
        listed_orders[maker].quantity = _quantity;
        listed_orders[maker].timestamp = now;
        listed_orders[maker].status = Status.open;
    }
    
    function cancel() public{
        require(msg.sender == maker);
        listed_orders[maker].status = Status.canceled;
        completed_orders[maker] = listed_orders[maker];
        delete listed_orders[maker];
    }
    
    function take(string _name) public {
        tokensTake = CT.getAdd(_name);
        /* This will be called by the taker who wants to exchange his cosh currency to native currency*/
        require(CT.getTokens(_name) && balanceOf[msg.sender][tokensTake] >= listed_orders[maker].quantity && 
                keccak256(_name) == keccak256(listed_orders[maker].toCosh));
        // check if the taker has the sufficient balance and the required cosh token.
        taker = msg.sender;
        
        listed_orders[maker].status = Status.locked; // change status of the order
        
        balanceOf[msg.sender][tokensTake] -= listed_orders[maker].quantity;
        balanceOf[address(this)][tokensTake] += listed_orders[maker].quantity;
    }
        
    function confirmTransaction(bool res) public {
        /* This is called by both the parties when the maker sends the funds to the taker
            and taker receives the currency */
        require(msg.sender == maker || msg.sender == taker);
        confirmation[msg.sender] = res; // change the confirmation status according to the parameter
    }
    
    function transfer() public{

        // this function can be called by any party to commence the exchange of tokens
        /* checks if both the parties are sastified and the taker received the native currency*/
        if(confirmation[maker] == true && confirmation[taker] == true) {
            
            balanceOf[maker][tokensTake] += value-((commission*value)/100);// tokens are tranfered from contract to maker
            balanceOf[owner][tokensTake] += ((commission*value)/100); // tokens commission tranfered to owner.
            
            listed_orders[maker].status = Status.closed;
            completed_orders[maker] = listed_orders[maker];
            delete listed_orders[maker];
            return;
        }
        else {
            /* if there is any false claims by any of the party, Cosh Voting is done to find the culprit.*/
            //CoshVoting.numberOfVotes();
        }
    }
}
//"BTC", "CoshBTC", "asdfghj", 23