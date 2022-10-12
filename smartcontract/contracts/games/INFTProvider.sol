// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface INFTProvider {
    /**
     * @dev Get NFT by tokenId.
     *
     * @param tokenId The id of the NFT
     */
    function fetchNFT(uint256 tokenId) external view returns (bytes memory);

    /**
     * @dev Get all NFT which are owned by the user.
     *
     * @param userAddress The address of user
     * @param offset The offset for start getting in paging
     * @param limit Maximun number of items to be returned
     */
    function fetchUserNFTs(
        address userAddress,
        uint256 offset,
        uint8 limit
    ) external view returns (bytes[] memory);

    /**
     * @dev Get all NFT which are owned by the user and matched to the filter.
     *
     * @param userAddress The address of user
     * @param offset The offset for start getting in paging
     * @param limit Maximun number of items to be returned
     * @param filterAddress Address of the filter contract which NFT must be matched
     */
    function fetchUserMatchedFilterNfts(
        address userAddress,
        uint256 offset,
        uint8 limit,
        address filterAddress
    ) external view returns (bytes[] memory);
}
