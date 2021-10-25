// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
//import "https://github.com/sushiswap/sushiswap/blob/canary/contracts/uniswapv2/UniswapV2Router02.sol";

interface ISushiswapV2Router02 {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
        function WETH() external pure returns (address);

}

contract SocialMedia is VRFConsumerBase, KeeperCompatibleInterface, Ownable {


    ISushiswapV2Router02 sushi = ISushiswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);


    bytes32 internal keyHash;
    uint256 internal fee;

    uint256 public randomResult;

    //address WETHKovan = 0x2583407163B7F3F52f42d427F8634a7A652DC311;
    address LINKKovan = 0xa36085F69e2889c224210F603D836748e7dC0088;

    constructor()
        VRFConsumerBase(
            0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9, // VRF Coordinator
            0xa36085F69e2889c224210F603D836748e7dC0088  // LINK Token
        )
    {
        keyHash = 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4;
        fee = 0.1 * 10 ** 18; // 0.1 LINK (Varies by network)
    }


    struct Post
    {
      uint256 numberOfLikes;
      uint256 timestamp;
      string message;
      string url;
    }

    struct postRequest
    {
    address userAddress;
    uint256 timestamp;
    string message;
    string url;
    }

    struct userProfile
    {
        bool exists;
        address userAddress; // Might not need
        string userProfileBio;
        string userNickname;
        uint256 followerCount;
        uint256[] userPosts; // list of answer keys so we can look them up
        mapping(uint256 => Post) postStructs; // random access by question key and answer key
        // add more non-key fields as needed
    }

    mapping(address => userProfile) userProfileStructs; // random access by question key
    address[] userProfileList; // list of user profiles
    mapping(bytes32 => postRequest) postRequestStruct; //Used for the Async Call

    function newProfile(string memory text, string memory nickName )
    public
        // onlyOwner
        returns(bool success)
    {
        require(userProfileStructs[msg.sender].exists == false, "Account Already Created"); // Check to see if they have an account
        userProfileStructs[msg.sender].userProfileBio = text;
        userProfileStructs[msg.sender].userNickname = nickName;
        userProfileStructs[msg.sender].followerCount = 0;
        userProfileStructs[msg.sender].exists = true;
        userProfileList.push(msg.sender);
        return true;
    }

    function getUserProfile(address userAddress)
        public
        view
        returns(string memory profileBio, uint totalPosts)
    {
        return(userProfileStructs[userAddress].userProfileBio, userProfileStructs[userAddress].userPosts.length);
    }

    // function addPost(string memory messageText, uint256 randomResult1)
    //     public
    //     // onlyOwner
    //     returns(bool success)
    // {
    //     // call chainlink VRF for postKey
    //     // Check that they exist
    //     userProfileStructs[msg.sender].userPosts.push(randomResult1);
    //     userProfileStructs[msg.sender].postStructs[randomResult1].message = messageText;
    //     userProfileStructs[msg.sender].postStructs[randomResult1].timestamp = block.timestamp;
    //     userProfileStructs[msg.sender].postStructs[randomResult1].numberOfLikes = 0;
    //     // answer vote will init to 0 without our help
    //     return true;
    // }

    function getUserPost(address userAddress, uint256 postKey)
        public
        view
        returns(string memory message, uint256 numberOfLikes, uint256 timestamp, string memory url )
    {
        return(
            userProfileStructs[userAddress].postStructs[postKey].message,
            userProfileStructs[userAddress].postStructs[postKey].numberOfLikes,
            userProfileStructs[userAddress].postStructs[postKey].timestamp,
            userProfileStructs[userAddress].postStructs[postKey].url);
    }

        function getAllUserPosts(address userAddress)
        public
        view
        returns(uint256[] memory userPosts)
    {
        return( userProfileStructs[userAddress].userPosts);
    }

    function getTotalUsers()
        public
        view
        returns(uint totalUsers)
    {
        return userProfileList.length;
    }
    function likePost(address userAddress, uint256 postKey)
        public
        returns(bool success)
    {
        userProfileStructs[userAddress].postStructs[postKey].numberOfLikes += 1;
        return true;
    }
        function followUser(address userAddress)
        public
        returns(bool success)
    {
        userProfileStructs[userAddress].followerCount += 1;
        return true;
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
    function getLinkBalance() public view returns (uint) {
        return LINK.balanceOf(address(this));
    }

   // function donate(address _receiver) public payable {

   // _receiver.call.value(msg.value).gas(20317)();
//    }


    function getRandomNumberAndPost(string memory messageText, string memory url) public returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        bytes32 tempRequestId = requestRandomness(keyHash, fee);
        postRequestStruct[tempRequestId].userAddress = msg.sender; //temporarily stores the data using mapping since this will be an async call
        postRequestStruct[tempRequestId].message = messageText; //temporarily stores the data using mapping since this will be an async call
        postRequestStruct[tempRequestId].message = messageText; //temporarily stores the data using mapping since this will be an async call
        postRequestStruct[tempRequestId].url= url; //temporarily stores the data using mapping since this will be an async call
        return tempRequestId;
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        userProfileStructs[postRequestStruct[requestId].userAddress].userPosts.push(randomness); //uses the stored data based on the requestID
        userProfileStructs[postRequestStruct[requestId].userAddress].postStructs[randomness].message = postRequestStruct[requestId].message; //uses the stored data based on the requestID
        userProfileStructs[postRequestStruct[requestId].userAddress].postStructs[randomness].timestamp = postRequestStruct[requestId].timestamp; //uses the stored data based on the requestID
        userProfileStructs[postRequestStruct[requestId].userAddress].postStructs[randomness].numberOfLikes = 0; //uses the stored data based on the requestID
        userProfileStructs[postRequestStruct[requestId].userAddress].postStructs[randomness].url = postRequestStruct[requestId].url; //uses the stored data based on the requestID
    }

    function checkUpkeep(bytes calldata /* checkData */) external override returns (bool upkeepNeeded, bytes memory /* performData */) {
        upkeepNeeded = LINK.balanceOf(address(this)) < fee*100; // makesure enough link is there
        // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
        return (upkeepNeeded, bytes(""));
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        swapEthforLink();
        // We don't use the performData in this example. The performData is generated by the Keeper's call to your checkUpkeep function
    }

    function swapEthforLink() public payable {
        uint256 amount = (address(this).balance / 100) * 90 ;
        address[] memory path = new address[](2);
        path[0] = sushi.WETH();
        path[1] = LINKKovan;
        uint256 amountOutMin = 1.0 * 10 ** 18; // minimum 1 link
        sushi.swapExactTokensForTokens(amount,amountOutMin, path, address(this), (block.timestamp+120)); //require at least 10 link tokens, send to this address, timelimit is 120 seconds.
    }

    function withdraw(uint256 _amount) public payable onlyOwner {
    payable(msg.sender).transfer(_amount);
    }

    function withdrawErc20(IERC20 token) public payable onlyOwner{
      require(token.transfer(msg.sender, token.balanceOf(address(this))), "Transfer failed");
    }

    fallback() external payable {
        // nothing to do
    }


    // function transfer(address to, uint value)
    // returns(bool success)
    // {
    //   if(balances[msg.sender] < value) throw;
    //   balances[msg.sender] -= value;
    //   fee = value*0.1;
    //   newValue = value*0.9;
    //   to.transfer(newValue);
    //   this.owner.transfer(fee); //Collect fee to pay Chainlink Oracles
    //   LogTransfer(msg.sender, to, value);
    //   return true;
    // }
    //
    // function donate(address userAddress, bytes32 postKey)
    //     public
    //     constant
    //     returns(bool success)
    // {
    //     userProfileStructs[userAddress].postStructs[postKey].numberOfLikes += 1;
    //     return true;
    // }

}
