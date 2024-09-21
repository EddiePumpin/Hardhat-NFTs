//SPDX-Lincense-Identifier: MIT;
pragma solidity ^0.8.20;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
// ERC721URIStorage is extending ERC721, so the constructor will remain unchange
import "@openzeppelin/contracts/access/Ownable.sol";

error RamdomIpfsNft__RangeOutOfBounds();
error RandomIpfsNft__NotEnoughETH();
error RandomIpfsNft__TransferFailed();

contract RandomIpfsNft is VRFConsumerBaseV2Plus, ERC721URIStorage, Ownable {
  // Type Declaration
  enum Breed {
    PUG,
    SHIBA_INU,
    ST_BENARD
  }

  // Chainlink VRF Variables

  VRFCoordinatorV2Interface private immutable i_vrfCoordinator; // By using VRFCoordinatorV2Interface as a data type, the contract can interact with the Chainlink VRF Coordinator through the functions declared in the interface without having access to the full contract code.
  uint64 private immutable i_subscriptionId;
  bytes32 private immutable i_gasLane;
  uint32 private immutable i_callbackGasLimit;
  uint16 private constant REQUEST_CONFIRMATIONS = 3;
  uint32 private constant NUM_WORDS = 1;

  // Chainlink VRF Variables
  mapping(address => uint256) public s_requestIdToSender;

  // NFT variables
  uint256 public s_tokenCounter; //  initializing s_tokenCounter is not strictly necessary if you're comfortable with it starting at its default value, which is 0. Solidity initializes state variables to their default values if they are not explicitly initialized.
  uint256 internal constant MAX_CHANCE_VALUE = 100;
  string[] internal s_dogTokenUris;
  uint256 internal immutable i_mintFee;

  // Events
  event NftRequested(uint256 indexed requestId, address requester);
  event NftMinted(Breed dogBreed, address minter);

  // When we mint an NFT, we will trigger a Chainlink VRF call to get us a random number
  // Using that number we will get a random NFT
  // Random NFT we will use is either a PUG(Super rare), SHIBA INU(sort of rare), St. Benard(common)

  // Users have to pay to mint an NFT
  // The owner of the contract can withdraw the ETH

  constructor(
    //uint256 subscriptionId
    address vrfCoordinatorV2,
    uint64 subscriptionId,
    bytes32 gasLane,
    uint32 callbackGasLimit,
    string[3] memory dogTokenUris,
    uint256 mintFee
  ) VRFConsumerBaseV2Plus(vrfCoordinatorV2) ERC721("MethNFT", "MNFT") {
    i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
    i_subscriptionId = subscriptionId;
    i_gasLane = gasLane;
    s_dogTokenUris = dogTokenUris;
    i_mintFee = mintFee;
  }

  function requestNft() public payable returns (uint256 requestId) {
    // This function will kick off the VRF AND whoever call this function will mint an NFT.
    // A mapping between requestId and this function
    if (msg.value < i_mintFee) { 
      revert RandomIpfsNft__NotEnoughETH();
    }
    // The mintFee payer makes a request to the chainlink node for a random number
    requestId = i_vrfCoordinator.requestRequestWords(VRFV2PlusClient.RandomWordsRequest({
      i_gasLane,
      i_subscriptionId,
      REQUEST_CONFIRMATIONS,
      i_callbackGasLimit,
      NUM_WORDS
    })
    );
    s_requestIdToSender[requestId] = msg.sender; // the requestId is set to msg.sender when the requestNft() is called.
    emit NftRequested(requestId, msg.sender);
  }

  function fulfillRandomWords(
    uint256 requestId,
    uint256[] memory randomWords
  ) internal override {
    // By default, the chainlink node will call fulfill random words and the owner of the NFT will be the chainlink node.
    address nftOwner = s_requestIdToSender[requestId]; // Now, whoever call the requestNft() will be the NFT owner.
    uint256 newTokenId = s_tokenCounter;
    // What does the token look like?
    uint256 moddedRng = randomWords[0] % MAX_CHANCE_VALUE; // moddedRng will be any value between 0 and 99. It is like an index
    // If we get. 0 to 10 is PUG, 11 to 30 is SHIBA, 30 to 100 is St. Benard
    // 7 -> PUG
    // 88 -> St. Benard
    // 45 -> St. Benard
    // 12 -> Shiba Inu
    Breed dogBreed = getBreedFromModdedRng(moddedRng);
    s_tokenCounter += s_tokenCounter; // s_tokenCounter = s_tokenCounter + 1
    _safeMint(nftOwner, newTokenId);
    _setTokenURI(
      newTokenId,
      /* that breed's tokenURI */ s_dogTokenUris[uint256(dogBreed)]
    );
    emit NftMinted(dogBreed, nftOwner);
  }

  function withdraw() public onlyOwner {
    uint256 amount = address(this).balance;
    (bool success, ) = payable(msg.sender).call{value: amount}("");
    if (!success) {
      revert RandomIpfsNft__TransferFailed();
    }
  }

// Once the random number is gotten, the contract uses the chanceArray is used to figure out which NFT is going to be used for the minting.

  function getBreedFromModdedRng(
    uint256 moddedRng
  ) public pure returns (Breed) {
    //This is to get random number just as in Raffle smart contract
    uint256 cumulativeSum = 0;
    uint256[3] memory chanceArray = getChanceArray();
    // modelling = 25
    // i = 0, for second iteration it will be 1
    // cumulativeSum = 0, for second iteration it will be 10.
    for (uint256 i = 0; i < chanceArray.length; i++) {
      // i = 0 will not be true, then it will jump to second line "cumulativeSum += chanceArray[i];"
      if (
        moddedRng >= cumulativeSum && moddedRng < cumulativeSum + chanceArray[i]
      ) {
        // For the first time, changeArray[i] is 10
        return Breed(i);
      }
      cumulativeSum += chanceArray[i];
    }
    revert RamdomIpfsNft__RangeOutOfBounds();
  }

  function getChanceArray() public returns (uint256[3] memory) {
    // The chanceArray() will represent different chances of different dogs.
    return [10, 30, MAX_CHANCE_VALUE]; // Index 0 has a 10% chance of happening, index 1 has a 20%[30 -10] chance of happening while index 2 has 60% chance of happening[10 + 30 - 100]
  } // [3] means size 3

  //function tokenURI(uint256) public view override returns (string memory) {}

  function getMintFee() public view returns (uint256) {
    return i_mintFee;
  }

  function getDogTokenUris(uint256 index) public view returns (string memory) {
    return s_dogTokenUris[index];
  }

  function getTokenCounter() public view returns (uint256) {
    return s_tokenCounter;
  }
}
