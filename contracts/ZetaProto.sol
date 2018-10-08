// This contract carries out the zeta protocol to exchange native currency with cosh tokens
/* Zeta Protocol */

pragma solidity ^0.4.25;
import "./Tokens.sol";

contract ZetaProto {
    
    uint256 public i; // random variable to generate uuid of transaction
    address owner;    // who deploy the contract
    uint256 commission; // commission set by owner
    uint256 public upperComLimit;   // upper limit of the commission range
    uint256 public lowerComLimit;   // lower limit of the commission range
    Tokens public CT;   // Token contract instance

    // user defined datatype to chech order Status
    enum Status {open, closed, locked, canceled}

    // Order details
    struct Order {
        address maker;  // address of the user who made the request (have native currency and wants cosh tokens)
        string currencyName;    // native currency the maker has
        string makerAddress; // wallet address of the native currency from which maker will send the currency to taker
        uint256 quantity;   // amount of currency   
        uint256 timestamp;  // time of placing the Order    
        address taker;  // address of user who takes the request (have cosh tokens and want native currency, it will be 0x00.. until the status is locked)
        string takerAddress;    //  wallet address of taker (in which maker will transfer the currency, it will be 0x00.. until the status is locked)    
        Status status;  // check the status of the order
    }

    // deployes the contract
    constructor (address addr) public {
        owner = msg.sender; // sets the deployer as owner
        CT = Tokens(addr); // instance of token contract
    }
    
    // checks if owner
    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }
    
    // sets the commission and range of ccommission
    // only done by owner
    function setCommission (uint256 _com, uint256 _lowerPrice, uint256 _upperPrice) isOwner public{
        commission = _com;
        lowerComLimit = _lowerPrice;
        upperComLimit = _upperPrice;
    }
    
    // gets the commission rate of the particular order
    function getCommission(bytes32 id) public view returns(uint256) {
        uint256 value = listed_orders[id].quantity;
        uint256 com = commission;
        if(value <= lowerComLimit) {
            com = commission;
        }
        else if (value >lowerComLimit && value <= upperComLimit) {
            com = (commission*90)/100;
        }
        else {
            com = (commission*80)/100;
        }
        return com;
    }
    
    // maps the unique byte32 id to open and locked orders  
    mapping (bytes32 => Order) public listed_orders;
    
    // maps the unique byte32 id to canceled and closed orders  
    mapping (bytes32 => Order) public completed_orders;
    
    // confirm the transaction by the maker and taker
    mapping (address => bool) public confirmation;
    
    // checks if confirmation is done or not
    mapping (address => bool) public confirmed;

    // called by user who wants cosh tokens and has native currency
    function makeOrder(string _currencyName, string _currencyWalletAddress, uint256 _quantity) public returns(uint256 commissionthis, uint256 commissionValue, bool res){
        
        require(CT.getCurrency(_currencyName)); 
        // checks if the currency which user inputted is available for exchange or not
    
        bytes32 order_id = keccak256(i);
        // create a uuid for the order
        
        uint256 com = getCommission(order_id);
        // get the commission rate of this order
        
        listed_orders[order_id].maker = msg.sender; 
        listed_orders[order_id].currencyName = _currencyName;
        listed_orders[order_id].makerAddress = _currencyWalletAddress;
        listed_orders[order_id].quantity = _quantity;
        listed_orders[order_id].timestamp = now;
        listed_orders[order_id].status = Status.open;
        
        uint256 comVal = ((_quantity/100)*com);
        //  get the amount of commission of this order
        
        return (com, comVal, true); 
    }
    
    /* this is called by the maker to cancel the order*/
    function cancel(bytes32 id) public{
        
        require(msg.sender == listed_orders[id].maker && listed_orders[id].status != Status.locked);
        // checks if it is called by maker only and the status is not locked
        
        listed_orders[id].status = Status.canceled;
        completed_orders[id] = listed_orders[id];
        delete listed_orders[id];
        // above processe cancel the order and move them to completed orders
    }
    
    
    /* called by the user who has the required cosh token 
        and need the mentioned native currency. */
    function take(bytes32 id, string _takerWalletAddress) public {
        
        // string tokenHave = CT.getTokenForCurrency(listed_orders[id].currencyName);
        
        address tokensHave = CT.getAdd(CT.getTokenForCurrency(listed_orders[id].currencyName));
        // get the contract address of the token which is associated to the mentions native currency.
        
        require(CT.getBalance(msg.sender,tokensHave) >= listed_orders[id].quantity);
        // checks if user has sufficient balance.    

        CT.transferProto(msg.sender, tokensHave, listed_orders[id].quantity);
        // transfer the cosh tokens from taker's wallet to the contract address
        
        listed_orders[id].status = Status.locked; 
        // change status of the order
        
        listed_orders[id].taker = msg.sender;
        listed_orders[id].takerAddress = _takerWalletAddress;
        // above lines make the msg.sender as taker in the order list and sets the taker wallet address

    }
        
    event Tran(
        bool,
        bool,
        bool,
        bool,
        bool
    );
    
    /*this function is called by both, maker and taker to confirm 
        that the maker has sent the native currency to taker. */
    function confirmTransaction(bool res, bytes32 id) public returns(bool) {
        
        require(msg.sender == listed_orders[id].maker || msg.sender == listed_orders[id].taker);
        // checks if the msg.sender are maker or taker only
        
        confirmation[msg.sender] = res; 
        // change the confirmation status according to the parameter
        
        confirmed[msg.sender] = true;
        // this confirms that both have confirmed by their sides
        
        if(confirmed[listed_orders[id].maker] && confirmed[listed_orders[id].taker])
           bool suc =  transact(id);
           
        emit Tran(confirmed[listed_orders[id].maker], confirmed[listed_orders[id].taker], confirmation[listed_orders[id].maker], confirmation[listed_orders[id].taker], suc);
        
        return suc;   
    }
    
    /* this function is automatically called when both (maker and taker) 
        confirms the transaction*/
    function transact(bytes32 id) private returns(bool){

        if(confirmation[listed_orders[id].maker] && confirmation[listed_orders[id].taker] ) {
        /* checks if both the parties are sastified and the taker received the native currency*/
            
            // string storage tokenHave = CT.getTokenForCurrency(listed_orders[id].currencyName);
            /* This will be called by the taker who wants to exchange his cosh currency to native currency*/
            address tokensHave = CT.getAdd(CT.getTokenForCurrency(listed_orders[id].currencyName));
            
            uint256 com = getCommission(id);
            uint256 value = listed_orders[id].quantity;
            uint256 commissionValue = ((value/100)*com);
            
            CT.transferProtoEx(address(this), tokensHave, listed_orders[id].maker, value-commissionValue); 
            // tokens are tranfered from contract to maker
            
            CT.transferProtoEx(address(this), tokensHave, owner, commissionValue); 
            // tokens commission tranfered to owner.
            
            listed_orders[id].status = Status.closed;
            completed_orders[id] = listed_orders[id];
            delete listed_orders[id];
            delete confirmed[listed_orders[id].maker];
            delete confirmed[listed_orders[id].taker];
            // above lines cnages the order status and send it to completed order
            
            return true;
        }
        else {
            /* if there is any false claims by any of the party, Cosh Voting is done to find the culprit.*/
            //CoshVoting.numberOfVotes();
            return false;
        }
    }
}
//"BTC", "CoshBTC", "asdfghj", 23