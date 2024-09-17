//SPDX-Lincense-Identifier: MIT;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

pragma solidity ^0.8.7;

contract BasicNft is ERC721 {
  //state variables
  string public constant TOKEN_URI =
    "ipfs://bafybeig37ioir76s7mg5oobetncojcm3c3hxasyd4rvid4jqhy4gkaheg4/?filename=0-PUG.json";
  uint256 private s_tokenCounter;

  constructor() ERC721("MethNFT", "MNFT") {
    s_tokenCounter = 0;
  }

  function mintNft() public returns (uint256) {
    // _safeMint() is from openzeppelin
    _safeMint(msg.sender, s_tokenCounter); // This mean "Mint the tokens to whoever calls the mint function". The second parameter is tokenId(It is unique)
    s_tokenCounter = s_tokenCounter + 1; //This increments the token counter each time a new NFT is minted, ensuring each NFT gets a unique token ID.
    return s_tokenCounter;
  }

  // TokenURI(Universal Resource Identifier) is an important function that is going to tell us how the token is going to look like
  // This function provides the metadata for a specific token. Metadata typically includes a description, image, or other relevant information about the NFT, and it’s retrieved via a URI (Uniform Resource Identifier), such as a URL.
  function tokenURI(
    uint256 /* tokenId */ // Since we didn't use it. Instead, the same TOKEN_URI is being returned for all NFTs, meaning they will all point to the same metadata.
  ) public view override returns (string memory) {
    return TOKEN_URI; // a string that likely points to the location of the metadata
  }

  function getTokenCounter() public view returns (uint256) {
    return s_tokenCounter;
  }
}
