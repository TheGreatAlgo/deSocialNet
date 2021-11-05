// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";



contract deSocialNet is KeeperCompatibleInterface, Ownable {

    address kovanKeeperRegistryAddress = 0x4Cb093f226983713164A62138C3F718A5b595F73;

    modifier onlyKeeper() {
        require(msg.sender == kovanKeeperRegistryAddress);
        _;
    }

    uint256 public lastCheckIn = block.timestamp;
    uint256 public checkInTimeInterval = 864000; //default to six months
    address public nextOwner;

    struct Comment
    {
      address commenter;
      string message;
      uint256 timestamp;
    }

    struct Post
    {
      uint256 numberOfLikes;
      uint256 timestamp;
      string message;
      string url;
      uint256 totalComments; // list of userPosts. probably can remove
      mapping(uint256 => Comment) commentStructs; // mapping of postkey to post
    }

    struct userProfile
    {
        bool exists;
        address userAddress; // Might not need
        string profileImageUrl;
        string userProfileBio;
        string userNickname;
        uint256 followerCount;
        uint256 joinDate;
        uint256 featuredPost;
        uint256 userPosts; // list of userPosts. probably can remove
        mapping(uint256 => Post) postStructs; // mapping of postkey to post
    }

    mapping(address => userProfile) userProfileStructs; // mapping useraddress to user profile
    address[] userProfileList; // list of user profiles
    event sendMessageEvent(address senderAddress, address recipientAddress, uint256 time, string message);
    event newPost(address senderAddress, uint256 postID);

    function sendMessage(address recipientAddress, string memory message) public {
        require(userProfileStructs[msg.sender].exists == true, "Create an Account to Post"); // Check to see if they have an account
        emit sendMessageEvent(msg.sender, recipientAddress,block.timestamp, message);
    }

    function newProfile(string memory newProfileBio, string memory nickName) public
        // onlyOwner
        returns(bool success)
    {
        require(userProfileStructs[msg.sender].exists == false, "Account Already Created"); // Check to see if they have an account
        userProfileStructs[msg.sender].userProfileBio = newProfileBio;
        userProfileStructs[msg.sender].userNickname = nickName;
        userProfileStructs[msg.sender].followerCount = 0;
        userProfileStructs[msg.sender].exists = true;
        userProfileStructs[msg.sender].joinDate = block.timestamp;
        userProfileStructs[msg.sender].featuredPost = 0;
        userProfileStructs[msg.sender].userProfileBio = '';
        userProfileList.push(msg.sender);
        return true;
    }

    function getUserProfile(address userAddress) public view
        returns(string memory profileBio, uint256 totalPosts,uint256 joinDate,uint256 followerCount, string memory userNickname, uint256 featuredPost, string memory profileImageUrl)
    {
        return(userProfileStructs[userAddress].userProfileBio,
        userProfileStructs[userAddress].userPosts,
        userProfileStructs[userAddress].joinDate,
        userProfileStructs[userAddress].followerCount,
        userProfileStructs[userAddress].userNickname,
        userProfileStructs[userAddress].featuredPost,
        userProfileStructs[userAddress].profileImageUrl);
    }

     function addPost(string memory messageText, string memory url) public returns(bool success)
     {
         require(userProfileStructs[msg.sender].exists == true, "Create an Account to Post"); // Check to see if they have an account
         uint256 postID = (userProfileStructs[msg.sender].userPosts); // ID is just an increment. No need to be random since it is associated to each unique account
         userProfileStructs[msg.sender].userPosts += 1;
         userProfileStructs[msg.sender].postStructs[postID].message = messageText;
         userProfileStructs[msg.sender].postStructs[postID].timestamp = block.timestamp;
         userProfileStructs[msg.sender].postStructs[postID].numberOfLikes = 0;
         userProfileStructs[msg.sender].postStructs[postID].url = url;
         emit newPost(msg.sender,postID); // emit a post to be used on the explore page
         return true;
     }

    function addComment(address postOwner, uint256 postID, string memory commentText) public returns(bool success)
     {
         require(userProfileStructs[msg.sender].exists == true, "Create an Account to Comment"); // Check to see if they have an account
         require(userProfileStructs[postOwner].postStructs[postID].timestamp != 0, "No Post Exists"); //Check to see if comment exists. Timestamps default to 0
         uint256 commentID = userProfileStructs[postOwner].postStructs[postID].totalComments; // ID is just an increment. No need to be random since it is associated to each unique account
         userProfileStructs[postOwner].postStructs[postID].totalComments += 1;
         userProfileStructs[postOwner].postStructs[postID].commentStructs[commentID].commenter = msg.sender;
         userProfileStructs[postOwner].postStructs[postID].commentStructs[commentID].message = commentText;
         userProfileStructs[postOwner].postStructs[postID].commentStructs[commentID].timestamp = block.timestamp;
         return true;
     }
    function getComment(address postOwner, uint256 postID, uint256 commentID) public view
         returns(address commenter, string memory message, uint256 timestamp, string memory userNickname, string memory profileImageUrl)
     {
         return(
         userProfileStructs[postOwner].postStructs[postID].commentStructs[commentID].commenter,
         userProfileStructs[postOwner].postStructs[postID].commentStructs[commentID].message,
         userProfileStructs[postOwner].postStructs[postID].commentStructs[commentID].timestamp,
         userProfileStructs[userProfileStructs[postOwner].postStructs[postID].commentStructs[commentID].commenter].userNickname,
         userProfileStructs[userProfileStructs[postOwner].postStructs[postID].commentStructs[commentID].commenter].profileImageUrl
         );
     }


     // Please Hire me

    function changeUserBio(string memory bioText) public returns(bool success)
     {
         require(userProfileStructs[msg.sender].exists == true, "Create an Account First"); // Check to see if they have an account
         userProfileStructs[msg.sender].userProfileBio = bioText ;
         return true;
     }
     function changeUserProfilePicture(string memory url) public returns(bool success)
     {
         require(userProfileStructs[msg.sender].exists == true, "Create an Account First"); // Check to see if they have an account
         userProfileStructs[msg.sender].profileImageUrl = url ;
         return true;
     }
    function changeUserNickname(string memory newNickName) public returns(bool success)
     {
         require(userProfileStructs[msg.sender].exists == true, "Create an Account First"); // Check to see if they have an account
         userProfileStructs[msg.sender].userNickname = newNickName ;
         return true;
     }
    function changeFeaturedPost(uint256 postNumber) public returns(bool success)
     {
         require(userProfileStructs[msg.sender].exists == true, "Create an Account First"); // Check to see if they have an account
         userProfileStructs[msg.sender].featuredPost = postNumber;
         return true;
     }
    function getUserPost(address userAddress, uint256 postKey) external view
        returns(string memory message, uint256 numberOfLikes, uint256 timestamp, string memory url, string memory userNickname, uint256 totalComments)
    {
        return(
            userProfileStructs[userAddress].postStructs[postKey].message,
            userProfileStructs[userAddress].postStructs[postKey].numberOfLikes,
            userProfileStructs[userAddress].postStructs[postKey].timestamp,
            userProfileStructs[userAddress].postStructs[postKey].url,
            userProfileStructs[userAddress].userNickname,
            userProfileStructs[userAddress].postStructs[postKey].totalComments); // stack is too deep if I try to call profileImageUrl as well
    }

    function getAllUserPosts(address userAddress) public view
        returns(uint256 userPosts)
    {
        return(userProfileStructs[userAddress].userPosts);
    }

    function getTotalUsers() public view
        returns(uint totalUsers)
    {
        return userProfileList.length;
    }
    function likePost(address userAddress, uint256 postKey) public returns(bool success)
    {
        require(userProfileStructs[msg.sender].exists == true, "Create an Account First"); // Check to see if they have an account
        userProfileStructs[userAddress].postStructs[postKey].numberOfLikes += 1;
        return true;
    }
    function followUser(address userAddress) public returns(bool success)
    {
        require(userProfileStructs[msg.sender].exists == true, "Create an Account First"); // Check to see if they have an account
        userProfileStructs[userAddress].followerCount += 1;
        return true;
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    // Hire me so I don’t grow to be your competitor ;)

    function changeInheritance(address newInheritor) public onlyOwner {
        nextOwner = newInheritor;
    }
    function ownerCheckIn() public onlyOwner {
        lastCheckIn = block.timestamp;
    }
    function changeCheckInTime(uint256 newCheckInTimeInterval) public onlyOwner {
        checkInTimeInterval = newCheckInTimeInterval; // let owner change check in case he know he will be away for a while.
    }

    function passDownInheritance() internal {
        transferOwnership( nextOwner);
    }

    function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory /* performData */) {
        return (block.timestamp > (lastCheckIn + checkInTimeInterval), bytes("")); // make sure to check in at least once every 6 months
    }

    function performUpkeep(bytes calldata /* performData */) onlyKeeper external override {
        passDownInheritance();
    }

    function withdraw(uint amount) public onlyOwner returns(bool) {
        require(amount <= address(this).balance);
        payable(msg.sender).transfer(amount); //if the owner send to sender
        return true;
    }

    function withdrawErc20(IERC20 token) public onlyOwner{
      require(token.transfer(msg.sender, token.balanceOf(address(this))), "Transfer failed");
    }

    receive() external payable {
        // nothing to do but accept money
    }
}
