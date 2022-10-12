// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./PetStructs.sol";
import "./IPet.sol";
// import "../../INFTProvider.sol";
import "../../../filter/IFilter.sol";
import "../../../helper/ArrayHelper.sol";

contract PetProvider /*is INFTProvider*/ {
    address public immutable nftAddress;

    constructor(address _nftAddress) {
        nftAddress = _nftAddress;
    }

    function fetchNFT(uint256 tokenId)
        external
        view
        // override
        returns (Pet memory)
    {
        require(tokenId >= 0, "E-b72540b1f");
        return IPet(nftAddress).getPet(tokenId);
    }

    function fetchUserNFTs(
        address userAddress,
        uint256 offset,
        uint8 limit
    ) external view /*override*/ returns (Pet[] memory) {
        require(nftAddress != address(0), "E-b7248ec0f");
        Pet[] memory pets = IPet(nftAddress).getUserPets(userAddress);
        uint256 newLimit = ArrayHelper.getLimit(pets.length, offset, limit);
        Pet[] memory petsData = new Pet[](newLimit);

        for (uint256 i = 0; i < newLimit; i++) {
            petsData[i] = pets[i + offset];
        }
        return petsData;
    }

    function fetchUserMatchedFilterNfts(
        address userAddress,
        uint256 offset,
        uint8 limit,
        address filterAddress
    ) external view /*override*/ returns (Pet[] memory) {
        require(userAddress != address(0), "E-b72b90c24");
        require(filterAddress != address(0), "E-b72b90253");

        Pet[] memory pets = IPet(nftAddress).getUserPets(userAddress);
        uint256 newLimit = ArrayHelper.getLimit(pets.length, offset, limit);
        Pet[] memory petsData = new Pet[](newLimit);
        uint256 _count = 0;
        IFilter filter = IFilter(filterAddress);

        for (uint256 i = 0; i < pets.length; i++) {
            if (_count < newLimit - 1) {
                Pet memory pet = pets[i + offset];
                if (filter.filter(pet.id)) {
                    petsData[_count] = pet;
                    _count = _count + 1;
                } else {
                    // The nft do not match the filter => do nothing
                }
            } else {
                // We got enough NFT => do nothing
            }
        }

        Pet[] memory matchedPets = new Pet[](_count);
        for (uint256 index = 0; index < _count; index ++) {
            matchedPets[index] = petsData[index];
        }

        return matchedPets;
    }
}
