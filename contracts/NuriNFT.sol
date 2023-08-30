// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract NuriNFT is ERC721  {
    uint private _tokenId = 1;
    uint8 private _maxTokens = 10;

    constructor() ERC721("NuriNFT","N") {

    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://QmRdtiaNwbyWpjaQybDTWARArqxdcoAQBsx4cKyRaYSept/";
    }

    function getURI() external pure returns (string memory) {
        return _baseURI();
    }

    function mint(address to) external {
        require(_tokenId <= _maxTokens, "No more tokens left");
        _safeMint(to, _tokenId);
        _tokenId += 1;
    }

    function onERC721Received(address, address, uint256, bytes4) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}