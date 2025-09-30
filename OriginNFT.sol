// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
contract OriginNFT is ERC721, Ownable {
    uint256 private _nextTokenId;
    string public baseTokenURI;
    constructor(
        string memory name,
        string memory symbol,
        string memory _baseTokenURI
    ) ERC721(name, symbol) Ownable(msg.sender) {
        baseTokenURI = _baseTokenURI;
    }
    function safeMint(address to) public {
        uint256 tokenId = _nextTokenId;
        _nextTokenId++;
        _safeMint(to, tokenId);
    }
    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }
}