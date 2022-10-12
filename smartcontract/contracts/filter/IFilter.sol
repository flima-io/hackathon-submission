// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IFilter {
    /**
     * For given tokenId, ask nftProxy to get the data, and then verify if the NFT satisfy the filter condition.
     */
    function filter(uint256 _tokenId) external view returns (bool);
}
