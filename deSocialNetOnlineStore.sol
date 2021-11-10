// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";


contract onlineStore is KeeperCompatibleInterface, Ownable {

    address kovanKeeperRegistryAddress = 0x4Cb093f226983713164A62138C3F718A5b595F73;
    IERC20 deSocialNetToken = IERC20(0xAe0f650F39B943F738a790519C3556bf6f8C92F1);   //adress of desocialNet token

    modifier onlyKeeper() {
        require(msg.sender == kovanKeeperRegistryAddress);
        _;
    }


    uint256 public lastCheckIn = block.timestamp;
    uint256 public checkInTimeInterval = 864000; //default to six months
    address public nextOwner;

    uint256 public massivePurchaseTokenPrice =0.001*10**18; // 1 Million tokens is 1 Ether
    uint256 public largePurchaseTokenPrice = 0.00015*10**18; // 100,000 tokens is 0.15 Ether
    uint256 public mediumPurchaseTokenPrice = 0.00004*10**18; // 20,0000 tokens is 0.04 Ether
    uint256 public smallPurchaseTokenPrice = 0.000025*10**18; // 10,0000 tokens is 0.025 Ether



    function buyMassiveTokens() public payable{ // how many tokens they want to purchase
        require(deSocialNetToken.balanceOf(address(this)) >= 1000000*10**10,"Not Enought Tokens in Contract"); // require this contract to have at least 1,000,000 tokens before executing
        require(msg.value >= massivePurchaseTokenPrice,"Send the right amount of eth"); // there is a bug when calling the contract through moralis that the msg.value did not equal required even though msg.value was correct.
         deSocialNetToken.transfer(msg.sender, 1000000*10**18); // send a million tokens.
    }

    function buyLargeTokens() public payable{ // how many tokens they want to purchase
        require(deSocialNetToken.balanceOf(address(this)) >= 100000*10**10,"Not Enought Tokens in Contract"); // require this contract to have at least 1,000,000 tokens before executing
        require(msg.value >= largePurchaseTokenPrice,"Send the right amount of eth"); // require this contract to have at least 1,000,000 tokens before executing
        deSocialNetToken.transfer(msg.sender, 100000*10**18); // send 100,0000 tokens.
    }
    function buyMediumTokens() public payable{ // how many tokens they want to purchase
        require(deSocialNetToken.balanceOf(address(this)) >= 20000*10**10,"Not Enought Tokens in Contract"); // require this contract to have at least 1,000,000 tokens before executing
        require(msg.value >= mediumPurchaseTokenPrice,"Send the right amount of eth"); // require this contract to have at least 1,000,000 tokens before executing
        deSocialNetToken.transfer(msg.sender, 20000*10**18); // send 20,0000 tokens.
    }
    function buySmallTokens() public payable{ // how many tokens they want to purchase
        require(deSocialNetToken.balanceOf(address(this)) >= 10000*10**10,"Not Enought Tokens in Contract"); // require this contract to have at least 1,000,000 tokens before executing
        require(msg.value >= smallPurchaseTokenPrice,"Send the right amount of eth"); // require this contract to have at least 1,000,000 tokens before executing
        deSocialNetToken.transfer(msg.sender, 10000*10**18); // send 10,0000 tokens.

    }


    function withdrawErc20(IERC20 token) public onlyOwner{ //withdraw all ERC-20 that get accidently sent since this is an only ether store.
      require(token.transfer(msg.sender, token.balanceOf(address(this))), "Transfer failed");
    }


    function withdraw(uint amount) public onlyOwner returns(bool) {
        require(amount <= address(this).balance);
        payable(msg.sender).transfer(amount); //if the owner send to sender
        return true;
    }

    function setMassiveStorePrice(uint256 newPrice) public onlyOwner {
        require (newPrice <= massivePurchaseTokenPrice*2, "too high price"); // just in case you fat finger a number and accidently set a number too high or too low
        require (newPrice >= massivePurchaseTokenPrice/2, "too low price");
        massivePurchaseTokenPrice = newPrice;
    }
    function setLargeStorePrice(uint256 newPrice) public onlyOwner {
        require (newPrice <= largePurchaseTokenPrice*2, "too high price"); // just in case you fat finger a number and accidently set a number too high or too low
        require (newPrice >= largePurchaseTokenPrice/2, "too low price");
        largePurchaseTokenPrice = newPrice;
    }
    function setMediumStorePrice(uint256 newPrice) public onlyOwner {
        require (newPrice <= mediumPurchaseTokenPrice*2, "too high price"); // just in case you fat finger a number and accidently set a number too high or too low
        require (newPrice >= mediumPurchaseTokenPrice/2, "too low price");
        mediumPurchaseTokenPrice = newPrice;
    }
    function setsmallStorePrice(uint256 newPrice) public onlyOwner {
        require (newPrice <= smallPurchaseTokenPrice*2, "too high price"); // just in case you fat finger a number and accidently set a number too high or too low
        require (newPrice >= smallPurchaseTokenPrice/2, "too low price");
        smallPurchaseTokenPrice = newPrice;
    }

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

    function checkUpkeep(bytes calldata /* checkData */) external override returns (bool upkeepNeeded, bytes memory /* performData */) {
    //upkeepNeeded = (block.timestamp > (lastCheck + 5184000));
    // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
    return (block.timestamp > (lastCheckIn + checkInTimeInterval), bytes("")); // make sure to check in at least once every 6 months
    }

    function performUpkeep(bytes calldata /* performData */) external onlyKeeper override {
       passDownInheritance();
    }




}
