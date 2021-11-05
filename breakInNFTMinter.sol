// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract NFTMint is ERC721, VRFConsumerBase, Ownable, ERC721URIStorage{

    bytes32 internal keyHash;
    uint256 internal fee;

    uint256 public randomResult;

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
    ERC721("BreakInNFTs","BIN" )
    {
        keyHash = 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4;
        fee = 0.1 * 10 ** 18; // 0.1 LINK (Varies by network)
    }
    struct NFTCharacter {
        string name;
        uint256 health;
        uint256 agility;
        uint256 strength;
        uint256 sneak;
        uint256 charm;
    }
    struct mintableNFTCharacter {
        uint256 health;
        uint256 agility;
        uint256 strength;
        uint256 sneak;
        uint256 charm;
    }
    mintableNFTCharacter[] public mintableCharacters = [
        NFTCharacter( // initialize with Virginia
        100,
        750,
        250,
        750,
        400
        ),
        NFTCharacter( // initialize with Florida
        100,
        500,
        400,
        500,
        600
        ),
        NFTCharacter( // initialize with Alaska
        100,
        250,
        750,
        250,
        500
        )

        ];

    mapping(bytes32 => NFTCharacter) NFTCharacterStruct; // mapping useraddress to user profile
    mapping(bytes32 => address) requestToSender; // mapping useraddress to user profile
    NFTCharacter[] public characters;

    function mintAlaska(string memory name) public returns (bytes32) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        bytes32 requestID = requestRandomness(keyHash, fee);
        requestToSender[requestID] = msg.sender;
        NFTCharacterStruct[requestID].name = name;
        NFTCharacterStruct[requestID].health = 100;
        NFTCharacterStruct[requestID].agility = 250; // max will be 500
        NFTCharacterStruct[requestID].strength = 750; // max will be 1000
        NFTCharacterStruct[requestID].sneak = 250; // max will be 500
        NFTCharacterStruct[requestID].charm = 500; // max will be 50
        return requestID;
    }
    function mintAnyCharacter(string memory name, uint256 characterID) public returns (bytes32) { // allows owner of contract to create new characters as the game progresses
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        require(characterID < mintableCharacters.length, "No Character With That ID");
        bytes32 requestID = requestRandomness(keyHash, fee);
        requestToSender[requestID] = msg.sender;
        NFTCharacterStruct[requestID].name = name;
        NFTCharacterStruct[requestID].health = mintableCharacters[characterID].health;
        NFTCharacterStruct[requestID].agility = mintableCharacters[characterID].agility;
        NFTCharacterStruct[requestID].strength = mintableCharacters[characterID].strength;
        NFTCharacterStruct[requestID].sneak = mintableCharacters[characterID].sneak;
        NFTCharacterStruct[requestID].charm = mintableCharacters[characterID].charm;
        return requestID;
    }
    /**
     * Requests randomness
     */

    function mintVirginia() public returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, fee);
    }
    function mintFlorida() public returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, fee);
    }


    function getRandomNumber() public returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, fee);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        uint256 newID = characters.length;
        uint256 agility = NFTCharacterStruct[requestId].agility + (randomness % 250); // max will be 500
        uint256 strength = NFTCharacterStruct[requestId].strength + ((randomness % 123456) % 250); // max will be 1000
        uint256 sneak = NFTCharacterStruct[requestId].sneak + ((randomness % 654321) % 250); // max will be 500
        uint256 charm = NFTCharacterStruct[requestId].charm + ((randomness % 33576) % 250); // max will be 50
        characters.push(
            NFTCharacter(
                NFTCharacterStruct[requestId].name,
                NFTCharacterStruct[requestId].health,
                agility,
                strength,
                sneak,
                charm
                )
            );

        _safeMint(requestToSender[requestId], newID);
        _setTokenURI(newID, _tokenURI);

    }
    function setTokenURI(uint256 tokenId, string memory _tokenURI) public {
        require(_isApprovedOrOwner(_msgSender(),tokenId), "ERC721: transfer caller is not owner nor approved");
        _setTokenURI(tokenId, _tokenURI);
    }

}
