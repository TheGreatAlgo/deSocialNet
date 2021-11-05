// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;



import "@openzeppelin/contracts/utils/Counters.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

contract BreakINGame is VRFConsumerBase, Ownable, KeeperCompatibleInterface{

    bytes32 internal keyHash;
    uint256 internal fee;

    uint256 public randomResult;

    address kovanKeeperRegistryAddress = 0x4Cb093f226983713164A62138C3F718A5b595F73;

    modifier onlyKeeper() {
        require(msg.sender == kovanKeeperRegistryAddress);
        _;
    }

    uint256 public lastCheckIn = block.timestamp;
    uint256 public checkInTimeInterval = 864000; //default to six months
    address public nextOwner;

    IERC721 breakInNFT = IERC721(0xA32a2ee9074116cD65f6Bad5853DbDfb5c105F62);   //adress of breakInNFTs
    IERC20 deSocialNetToken = IERC20(0x25fE2b4d03dF8144D12F09Be547732e57752C29C);   //adress of desocialNet token


    /**
     * Constructor inherits VRFConsumerBase
     *
     * Network: Kovan
     * Chainlink VRF Coordinator address: 0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9
     * LINK token address:                0xa36085F69e2889c224210F603D836748e7dC0088
     * Key Hash: 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4
     */
    constructor()
        VRFConsumerBase(
            0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9, // VRF Coordinator
            0xa36085F69e2889c224210F603D836748e7dC0088  // LINK Token
        )
    {
        keyHash = 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4;
        fee = 0.1 * 10 ** 18; // 0.1 LINK (Varies by network)
    }
    struct scenarios{
        string name;
        uint256 riskBaseDifficulty;
        uint256 payoutAmountBase;
    }
    struct NFTCharacter {
        string name;
        uint256 born;
        uint256 health;
        uint256 agility;
        uint256 strength;
        uint256 sneak;
        uint256 charm;
        uint256 characterID;
    }
    struct depostedCharacter {
        uint256 NFTID;
        bool isDeposited;
        bool arrested;
        uint256 freetoPlayAgain;
    }
    struct depostedItem {
        uint256 NFTID;
        bool isDeposited;
    }
    struct gamePlay {
        address player;
        uint256 scenario;
        uint256 breakInStyle;
        uint256 difficultyLevel;
        uint256 health;
        uint256 agility;
        uint256 strength;
        uint256 sneak;
        uint256 charm;

    }
    event gameCode(address player, uint256 code);
    scenarios[] public differentGameScenarios;
    mapping(uint256 => scenarios) gameScenarios; // Players deposit their NFT into this contract to Play
    mapping(bytes32 => gamePlay) currentGamePlays; // Players deposit their NFT into this contract to Play
    mapping(address => depostedCharacter) NFTCharacterDepositLedger; // Players deposit their NFT into this contract to Play
    mapping(address => depostedItem) NFTItemDepositLedger; // Players deposit their NFT into this contract to Play
    mapping(address => uint256) jewelDepositLedger; // Players must deposit their loot to playe

    function addScenario(string memory name, uint256 riskBaseDifficulty, uint256 payoutAmountBase) public onlyOwner{
     differentGameScenarios.push(
        scenarios(
            name,
            riskBaseDifficulty,
            payoutAmountBase
            )
        );
    }

    function modifyScenario(uint256 scenarioNumber, string memory name, uint256 riskBaseDifficulty, uint256 payoutAmountBase) public onlyOwner{
     differentGameScenarios[scenarioNumber].riskBaseDifficulty = riskBaseDifficulty; // scenarios can be removed by effectily raising the riskbase difficult level so high no one would bother playing it and making payoutAmountBase 0
     differentGameScenarios[scenarioNumber].payoutAmountBase = payoutAmountBase;
     differentGameScenarios[scenarioNumber].name = name;
    }

    function depositNFT(uint256 NFTID) public { // users Must Deposit a character to play
        require(NFTCharacterDepositLedger[msg.sender].isDeposited != true,"Character Already Deposited");
        breakInNFT.transferFrom(msg.sender, address(this),NFTID); // will need to implement safer transfer
        NFTCharacterDepositLedger[msg.sender].NFTID = NFTID;
        NFTCharacterDepositLedger[msg.sender].isDeposited = true; //
    }
    function withdrawNFT() public { // users Must Deposit a character to play
        require(NFTCharacterDepositLedger[msg.sender].isDeposited == true,"No Character Deposited");
        require(NFTCharacterDepositLedger[msg.sender].arrested == false,"Character in Prison");
        breakInNFT.transferFrom(address(this), msg.sender,NFTCharacterDepositLedger[msg.sender].NFTID); // will need to implement safer transfer
        NFTCharacterDepositLedger[msg.sender].isDeposited = false; //
    }
    function depositNFTItem(uint256 NFTID) public { // users Must Deposit a character to play
        require(NFTItemDepositLedger[msg.sender].isDeposited != true,"Item Already Deposited");
        breakInNFT.transferFrom(msg.sender, address(this),NFTID); // will need to implement safer transfer
        NFTItemDepositLedger[msg.sender].NFTID = NFTID;
        NFTItemDepositLedger[msg.sender].isDeposited = true; //
    }
    function withdrawNFTItem() public { // users Must Deposit a character to play
        require(NFTItemDepositLedger[msg.sender].isDeposited == true,"No Item Deposited");
        breakInNFT.transferFrom(address(this), msg.sender,NFTItemDepositLedger[msg.sender].NFTID); // will need to implement safer transfer
        NFTItemDepositLedger[msg.sender].isDeposited = false; //
    }
    function depositMoney(uint256 amountToDeposit) public { // users Must Deposit a character to play
        require(NFTCharacterDepositLedger[msg.sender].arrested == false,"Character in Prison");
        deSocialNetToken.transferFrom(msg.sender, address(this),amountToDeposit); // will need to implement safer transfer
        jewelDepositLedger[msg.sender] += amountToDeposit;
    }
    function withdrawMoney(uint256 amountToWithdraw) public { // users Must Deposit a character to play
        require(jewelDepositLedger[msg.sender] > amountToWithdraw, "Trying to withdraw to much money" );
        deSocialNetToken.transferFrom(address(this), msg.sender,amountToWithdraw); // will need to implement safer transfer
        jewelDepositLedger[msg.sender] -= amountToWithdraw;
    }

    function playGame(uint256 difficultyLevel,uint256 breakInStyle,uint256 scenario) public returns (bytes32) { // allows owner of contract to create new characters as the game progresses
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        require(NFTCharacterDepositLedger[msg.sender].isDeposited == true,"No Character Deposited");
        require(NFTCharacterDepositLedger[msg.sender].arrested == false,"Character in Prison");
        require(scenario < differentGameScenarios.length, "No Game Scenario");
        bytes32 requestID = requestRandomness(keyHash, fee);
        currentGamePlays[requestID].player = msg.sender;
        currentGamePlays[requestID].scenario = 0;
        currentGamePlays[requestID].breakInStyle = breakInStyle;
        currentGamePlays[requestID].difficultyLevel = difficultyLevel;
        currentGamePlays[requestID].scenario = scenario;
        // get current attributes of player
        // if item checked in they can use the item
        return requestID;
    }

    /**
     * Requests randomness
     */
    function getRandomNumber() internal returns (bytes32 requestId) { // internal to prevent blank characters being mintend by someone calling this function publicly
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, fee);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        if ((randomness % 5000) == 1 ){
            // 1 in 5000 chance character dies
            breakInNFT.transferFrom(address(this), address(0),NFTCharacterDepositLedger[currentGamePlays[requestId].player].NFTID); // transfer NFT to address 0
            NFTCharacterDepositLedger[msg.sender].isDeposited = false; //
            emit gameCode(currentGamePlays[requestId].player,0);
            return;

        }

        if (((randomness % 143456) % 100) == 1 ){
            // 1 in 100 chance character is injured
            uint256 healthDecrease = ((randomness % 123456) % 99); // player can lose up to 99 health every 1 in 100
            if ((currentGamePlays[requestId].health+healthDecrease) > 100){ // players don't have to heal if they get injured before but if they get injured again and its greater than 100, they die
                breakInNFT.transferFrom(address(this), address(0),NFTCharacterDepositLedger[currentGamePlays[requestId].player].NFTID); // transfer NFT to address 0
                NFTCharacterDepositLedger[msg.sender].isDeposited = false; //
                emit gameCode(currentGamePlays[requestId].player,0);
            }
            // decrease health
            emit gameCode(currentGamePlays[requestId].player,1);
            return;
        }
        if (((randomness % 23015) % 20) == 1 ){
            // 1 in 20 chance character is almost getting arrested
            uint256 agilityRequiredtoEscape = ((randomness % 54321) % 1000); // player still has chance to escape
            if (currentGamePlays[requestId].agility > agilityRequiredtoEscape){
                emit gameCode(currentGamePlays[requestId].player,3);
                return; // escaped but no money given
            }
            else{
                NFTCharacterDepositLedger[msg.sender].arrested = true;
                 NFTCharacterDepositLedger[msg.sender].freetoPlayAgain = block.timestamp + 1728000; //player arrested for 2 days.
                emit gameCode(currentGamePlays[requestId].player,2);
                return; //  playerArrested
            }

        }
        if (currentGamePlays[requestId].breakInStyle == 0){ //player is sneaking in
            uint256 sneakInExperienceRequired = ((randomness % 235674) % 1000) + currentGamePlays[requestId].difficultyLevel+gameScenarios[currentGamePlays[requestId].scenario].riskBaseDifficulty; // difficulty will be somewhere between 0 to 10000 pluse the difficulty level which will be about 100 to 950
            if (currentGamePlays[requestId].sneak > sneakInExperienceRequired) {
                uint256 totalWon = currentGamePlays[requestId].difficultyLevel*gameScenarios[currentGamePlays[requestId].scenario].payoutAmountBase;
                jewelDepositLedger[currentGamePlays[requestId].player] += totalWon;
                emit gameCode(currentGamePlays[requestId].player,totalWon);
                return;
            }
        }
       if (currentGamePlays[requestId].breakInStyle == 1){ // player is breaking in with charm
           uint256 charmInExperienceRequired = ((randomness % 453678) % 1000) + currentGamePlays[requestId].difficultyLevel+gameScenarios[currentGamePlays[requestId].scenario].riskBaseDifficulty;
           if (currentGamePlays[requestId].charm > charmInExperienceRequired) {
            uint256 totalWon = currentGamePlays[requestId].difficultyLevel*gameScenarios[currentGamePlays[requestId].scenario].payoutAmountBase;
            jewelDepositLedger[currentGamePlays[requestId].player] += totalWon;
            emit gameCode(currentGamePlays[requestId].player,totalWon);
            return;
            }
       }
      if (currentGamePlays[requestId].breakInStyle == 2){ // player is breaking in with strength
          uint256 strengthInExperienceRequired = ((randomness % 786435) % 1000) + currentGamePlays[requestId].difficultyLevel+gameScenarios[currentGamePlays[requestId].scenario].riskBaseDifficulty; // strength is used for daylight robbery
          if (currentGamePlays[requestId].strength > strengthInExperienceRequired) {
            uint256 totalWon = currentGamePlays[requestId].difficultyLevel*gameScenarios[currentGamePlays[requestId].scenario].payoutAmountBase;
            jewelDepositLedger[currentGamePlays[requestId].player] += totalWon;
            emit gameCode(currentGamePlays[requestId].player,totalWon);
            return;
        }
      }

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
