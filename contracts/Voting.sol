pragma solidity ^0.4.11;

import "./SetNameLib.sol";


contract Voting {
    using SetNameLib for SetNameLib.Data;

    event ValidName(bytes32 name, uint candidateIndex, bool _value);
    event ValidBuy(uint tokenToBuy, address sender, uint totalBalance);
    event ValidInput(uint _tokens, uint pricePerToken, bytes32[] _candidateList);
    event ValidInputEnd(uint _tokens, uint pricePerToken, bytes32[] _candidateList, uint _candidateNamesFlag);


    struct voter {
    address voterAddress; // The address of the voter
    uint tokensBought;    // The total no. of tokens this voter owns
    uint[] tokensUsedPerCandidate; // Array to keep track of votes per candidate.
    }





    /* mapping field below is equivalent to an associative array or hash.
    The key of the mapping is candidate name stored as type bytes32 and value is
    an unsigned integer to store the vote count
    */
    mapping (bytes32 => uint) public votesReceived;
    mapping (address => voter) public voterInfo;

    SetNameLib.Data private candidateNames;
    bytes32[] public candidateList;

    uint public totalTokens; // Total no. of tokens available for this election
    uint public balanceTokens; // Total no. of tokens still available for purchase
    uint public tokenPrice; // Price per token

    /* This is the constructor which will be called once when you
    deploy the contract to the blockchain. When we deploy the contract,
    we will pass an array of candidates who will be contesting in the election
    */
    function Voting(uint _tokens, uint pricePerToken, bytes32[] _candidateList) public {
        ValidInput(_tokens, pricePerToken, _candidateList);

        for (uint i = 0; i < _candidateList.length; i++){
            candidateNames.insert(_candidateList[i], true);
        }
        candidateList = _candidateList;
        totalTokens = _tokens;
        balanceTokens = _tokens;
        tokenPrice = pricePerToken;

        ValidInputEnd(totalTokens, tokenPrice, candidateList, candidateNames.size);

    }

    // This function returns the total votes a candidate has received so far
    function totalVotesFor(bytes32 candidate) public constant returns (uint) {
        assert(validCandidateName(candidate));
        return votesReceived[candidate];
    }

    // This function increments the vote count for the specified candidate. This
    // is equivalent to casting a vote
    function voteForCandidate(bytes32 candidateName, uint votesInTokens) public {
        bool is_valid = validCandidateName(candidateName);
        uint candidateIndex = candidateNames.get_index(candidateName);

        ValidName(candidateName, candidateIndex, is_valid);
        assert(is_valid);

        // msg.sender gives us the address of the account/voter who is trying to call this function
        if (voterInfo[msg.sender].tokensUsedPerCandidate.length == 0) {
            for(uint i = 0; i < candidateList.length; i++) {
                voterInfo[msg.sender].tokensUsedPerCandidate.push(0);
            }
        }
        // Make sure this voter has enough tokens to cast the vote
        uint availableTokens = voterInfo[msg.sender].tokensBought - totalTokensUsed(voterInfo[msg.sender].tokensUsedPerCandidate);
        assert(availableTokens >= votesInTokens);
        //vote
        votesReceived[candidateName] += votesInTokens;
        // Store how many tokens were used for this candidate
        voterInfo[msg.sender].tokensUsedPerCandidate[candidateIndex-1] += votesInTokens;
    }

    // Return the sum of all the tokens used by this voter.
    function totalTokensUsed(uint[] tokensUsedPerCandidate) private returns (uint) {
        uint totalUsedTokens = 0;
        for(uint i = 0; i < tokensUsedPerCandidate.length; i++) {
            totalUsedTokens += tokensUsedPerCandidate[i];
        }
        return totalUsedTokens;
    }

    function validCandidateName(bytes32 candidateName) public returns (bool) {
        return candidateNames.contains(candidateName);
    }


    /*
    This function is used to purchase the tokens. Note the keyword  'payable' below.
    By just adding that one keyword to a function, your contract can now accept Ether
    from anyone who calls this function. Accepting money can not get any easier than this!
    */
    function buy() public payable returns (uint) {
        uint tokensToBuy = msg.value / tokenPrice;
        ValidBuy(tokensToBuy, msg.sender, balanceTokens-tokensToBuy);

        assert(tokensToBuy < balanceTokens);

        voterInfo[msg.sender].voterAddress = msg.sender;
        voterInfo[msg.sender].tokensBought += tokensToBuy;
        balanceTokens -= tokensToBuy;
        return tokensToBuy;
    }



    function tokensSold() public constant returns (uint) {
        return totalTokens - balanceTokens;
    }

    function voterDetails(address user) public constant returns (uint, uint[]) {
        return (voterInfo[user].tokensBought, voterInfo[user].tokensUsedPerCandidate);
    }

    /* All the ether sent by voters who purchased the tokens is in this
     contract's account. This method will be used to transfer out all those ethers
     in to another account. *** The way this function is written currently, anyone can call
     this method and transfer the balance in to their account. In reality, you should add
     check to make sure only the owner of this contract can cash out.
     */

    function allCandidates() public constant returns (bytes32[]) {
        return candidateList;
    }

    function transferTo(address account) public {
        account.transfer(this.balance);
    }
}
