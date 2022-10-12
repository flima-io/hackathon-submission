// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./LandStructs.sol";
import "./ILand.sol";
// import "../../INFTProvider.sol";
import "../../../filter/IFilter.sol";
import "../../../helper/ArrayHelper.sol";

contract LandProvider/* is INFTProvider*/ {
    address public immutable nftAddress;

    constructor(address _nftAddress) {
        nftAddress = _nftAddress;
    }

    function fetchNFT(uint256 tokenId)
        external
        view
        // override
        returns (LandMeta memory)
    {
        require(tokenId >= 0, "E-d94540b1f");

        return ILand(nftAddress).getLand(tokenId);
    }

    function fetchUserNFTs(
        address userAddress,
        uint256 offset,
        uint8 limit
    ) external view /*override*/ returns (LandMeta[] memory) {
        require(userAddress != address(0), "E-d9448ec24");

        LandMeta[] memory lands = ILand(nftAddress).getAccountLands(
            userAddress
        );
        uint256 newLimit = ArrayHelper.getLimit(lands.length, offset, limit);
        LandMeta[] memory landsData = new LandMeta[](newLimit);

        for (uint256 i = 0; i < newLimit; i++) {
            landsData[i] = lands[i + offset];
        }
        return landsData;
    }

    function fetchUserMatchedFilterNfts(
        address userAddress,
        uint256 offset,
        uint8 limit,
        address filterAddress
    ) external view /*override*/ returns (LandMeta[] memory) {
        require(userAddress != address(0), "E-d94b90c24");
        require(filterAddress != address(0), "E-d94b90253");

        LandMeta[] memory lands = ILand(nftAddress).getAccountLands(
            userAddress
        );
        uint256 newLimit = ArrayHelper.getLimit(lands.length, offset, limit);
        LandMeta[] memory landsData = new LandMeta[](newLimit);
        uint256 _count = 0;
        IFilter filter = IFilter(filterAddress);

        for (uint256 i = 0; i < lands.length; i++) {
            if (_count < newLimit - 1) {
                LandMeta memory land = lands[i + offset];
                if (filter.filter(land.landId)) {
                    landsData[_count] = land;
                    _count = _count + 1;
                } else {
                    // The nft do not match the filter => do nothing
                }
            } else {
                // We got enough NFT => do nothing
            }
        }

        LandMeta[] memory matchedLands = new LandMeta[](_count);
        for (uint256 index = 0; index < _count; index ++) {
            matchedLands[index] = landsData[index];
        }

        return matchedLands;
    }
}
