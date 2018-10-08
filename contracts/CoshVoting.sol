/*   

    @author: Suraj singla */
pragma solidity ^0.4.25;

contract CoshVote {

    address owner;
    uint numberOfVotes; // keeps check on vote count
    mapping (address => bool) voted; // keeps check on who has voted
    mapping (address => uint) weight; // keeps the weight count associated to an address
    mapping (address => bool) voteType; // keeps check of the type of vote.

    constructor() {
        owner = msg.sender;
    }
    modifier isOwner{
        msg.sender == owner;
        _;
    }
    function Vote(bool res) {
        // check if address has already voted or not
        require(voted[msg.sender] == false);
        
        if(res == true){
            // then will add the number of weights to the variable numberOfVotes;
            // and change voted to true
            // and also change vote type to true
            numberOfVotes += weight[msg.sender];
            voted[msg.sender] = true;
            voteType[msg.sender] = true;
        }
        else {
            // this will subtract the number of weights to the variable numberOfVotes;
            // and change voted to = true
            // and will leave vote type to false
            numberOfVotes -= weight[msg.sender];
            voted[msg.sender] = true;
            voteType[msg.sender] = false;
        }
    }
            
        function checkVote() isOwner returns (bool result){
            if(numberOfVotes > 0)
                return true;
            else
                return false;
        }
            
        // check if the the overall vote total is positive(>0) or negative(<0)
        // if positive then it will return true else false

        }
