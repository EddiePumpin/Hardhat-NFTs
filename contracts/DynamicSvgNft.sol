// SPDX-Lincense-Identifier: MIT;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import "base64-sol/base64.sol";

pragma solidity ^0.8.20;

error ERC721Metadata__URI_QueryFor_NonExistentToken();

contract DynamicSvgNft is ERC721 {
  // Contract Architecture
  // Mint function: To mint the NFTs
  // Store our SVG info somewhere
  // Some logic to say "Show X Image" or "Show Y Image"

  uint256 private s_tokenCounter;
  string private i_lowImageURI;
  string private i_highImageURI;
  string private constant base64EncodedSvgPrefix = "data:image/svg+xml;base64,";
  AggregatorV3Interface internal immutable i_priceFeed;
  mapping(uint256 => int256) public s_tokenIdToHighValue;

  event CreatedNFT(uint256 indexed tokenId, int256 highValue);

  constructor(
    address priceFeedAddress,
    string memory lowSvg,
    string memory highSvg
  ) ERC721("MethNFT", "MNFT") {
    s_tokenCounter = 0;
    i_lowImageURI = svgToImageURI(lowSvg);
    i_highImageURI = svgToImageURI(highSvg);
    i_priceFeed = AggregatorV3Interface(priceFeedAddress);
  }

  // This function will "convert" any svg to an URI/URL
  function svgToImageURI(
    string memory svg
  ) public pure returns (string memory) {
    // View this function has picture to link function
    string memory svgBase64Encoded = Base64.encode(
      bytes(string(abi.encodePacked(svg)))
    ); // The base64 encoder comes with an encoder
    return string(abi.encodePacked(base64EncodedSvgPrefix, svgBase64Encoded)); // string(abi.encodePacked(base64EncodedSvgPrefix, svgBase64Encoded)) -> This is how to combine string together.abi
    // base64EncodedSvgPrefix and svgBase64Encoded are encoded into ABI and finally typecast to string
  }

  function mintNft(int256 highValue) public {
    s_tokenIdToHighValue[s_tokenCounter] = highValue; // When they mint an NFT they choose the highValue they want
    s_tokenCounter += s_tokenCounter;
    _safeMint(msg.sender, s_tokenCounter); // It is of best practice to update our tokenCounter before we mint
    emit CreatedNFT(s_tokenCounter, highValue);
  }

  function _baseURI() internal pure override returns (string memory) {
    return "data:application/json;base64";
  }

  // data:image/svg+xml;base64 -> Prefix for SVG
  // data:application/json;base64 => Prefix for Base64 JSON

  // The tokenURI should return base64 encoded version of the JSON
  function tokenURI(
    uint256 tokenId
  ) public view override returns (string memory) {
    // From ERC721
    if (!_exists(tokenId)) {
      revert ERC721Metadata__URI_QueryFor_NonExistentToken(); // checks whether the token exists using _exists(tokenId) before returning the URI of the token.
      //string memory imageURI  = "hi!";
      // This will concatenate everything together then typecast into byte then converted into base64

      (, int256 price, , , ) = i_priceFeed.latestRoundData();
      string memory imageURI = i_lowImageURI;
      if (price >= s_tokenIdToHighValue[tokenId]) {
        imageURI = i_highImageURI;
      }

      // return string(
      //   abi.encodePacked(
      //   _baseURI(), // Concatenate _baseURI with it
      // Base64.encode(bytes(abi.encodePacked('{"name":"', name(), '", "description":"An NFT that changes based on the Chainlink Feed", ',
      // "atributes": [{"trait_type": "coolness", "value": 100}], "image":"',
      // imageURI, /** The imageURI from SVG */
      // '"}');
      // )
      // )
      // )
      // );

      return
        string(
          abi.encodePacked(
            _baseURI(),
            Base64.encode(
              bytes(
                abi.encodePacked(
                  '{"name":"',
                  name(), // You can add whatever name here
                  '", "description":"An NFT that changes based on the Chainlink Feed", ',
                  '"attributes": [{"trait_type": "coolness", "value": 100}], "image":"',
                  imageURI,
                  '"}'
                )
              )
            )
          )
        );
    }
  }
}
