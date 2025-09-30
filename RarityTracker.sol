// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./@reactive.network/contracts/interfaces/ICallback.sol";
contract RarityTracker is Ownable, ICallback {
    struct Trait {
        string trait_type;
        string value;
    }
    struct NFT {
        uint256 tokenId;
        Trait[] traits;
        uint256 rarityScore;
    }
    address public authorizedRscAddress;
    uint256 public totalNFTs;
    mapping(uint256 => NFT) public nfts;
    uint256[] public allTokenIds;
    mapping(string => mapping(string => uint256)) public traitCounts;
    event RarityUpdated(uint256 indexed tokenId, uint256 newRarityScore);
    event BatchRarityUpdated(uint256 count);
    constructor() Ownable(msg.sender) {}
    function handleCallback(bytes calldata data) external override {
        require(
            tx.origin == authorizedRscAddress,
            "Caller is not an authorized RSC"
        );
        (uint256 tokenId, Trait[] memory newTraits) = abi.decode(
            data,
            (uint256, Trait[])
        );
        _processNewNFT(tokenId, newTraits);
    }
    function _processNewNFT(uint256 tokenId, Trait[] memory newTraits) private {
        require(nfts[tokenId].tokenId == 0, "NFT already exists");
        totalNFTs++;
        allTokenIds.push(tokenId);
        nfts[tokenId].tokenId = tokenId;
        for (uint i = 0; i < newTraits.length; i++) {
            nfts[tokenId].traits.push(newTraits[i]);
            traitCounts[newTraits[i].trait_type][newTraits[i].value]++;
        }
        for (uint i = 0; i < allTokenIds.length; i++) {
            uint256 currentTokenId = allTokenIds[i];
            nfts[currentTokenId].rarityScore = _calculateRarityScore(
                currentTokenId
            );
            emit RarityUpdated(
                currentTokenId,
                nfts[currentTokenId].rarityScore
            );
        }
        emit BatchRarityUpdated(allTokenIds.length);
    }
    function _calculateRarityScore(
        uint256 tokenId
    ) internal view returns (uint256) {
        uint256 totalScore = 0;
        NFT storage nft = nfts[tokenId];
        uint256 precision = 1e6;
        for (uint i = 0; i < nft.traits.length; i++) {
            Trait memory trait = nft.traits[i];
            uint256 count = traitCounts[trait.trait_type][trait.value];
            if (count > 0) {
                totalScore += (precision * totalNFTs) / count;
            }
        }
        return totalScore;
    }
    function getNFTDetails(
        uint256 tokenId
    ) external view returns (NFT memory) {
        return nfts[tokenId];
    }
    function getAllNFTs() external view returns (NFT[] memory) {
        NFT[] memory allNfts = new NFT[](totalNFTs);
        for (uint i = 0; i < totalNFTs; i++) {
            allNfts[i] = nfts[allTokenIds[i]];
        }
        return allNfts;
    }
    function setAuthorizedRscAddress(address _rscAddress) public onlyOwner {
        authorizedRscAddress = _rscAddress;
    }
}