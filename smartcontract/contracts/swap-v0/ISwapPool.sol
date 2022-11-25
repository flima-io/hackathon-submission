// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../filter/IFilter.sol";

/**
 * A pool contract that holds all NFT assets in the pool. This is called by SwapRouter contract and not called directly by users.
 */
interface ISwapPool {
    /**
     * @dev deposit NFT items from the specified address.
     * - CHECKS
     *   - tokenIds does not exist in the pool
     * - EFFECTS
     *   - add token ids to the mapping
     * - INTERACTIONS
     *   - transfer tokens from user
     */
    function depositTokens(uint256[] calldata tokenIds, address from) external;

    /**
     * @dev withdraw NFT item to the specified address.
     * - CHECKS
     *   - tokenIds all exists in the pool
     * - EFFECTS
     *   - remove token ids from the mapping
     * - INTERACTIONS
     *   - transfer tokens to user
     */
    function withdrawTokens(uint256[] calldata tokenIds, address to) external;

    /**
     * @dev check if pool has token of given id
     */
    function hasTokenId(uint256 tokenId) external view returns (bool);

    /**
     * @dev get filter contract. called internally from router
     */
    function getFilter() external view returns (IFilter);

    function getTokenIds(uint256 offset, uint256 limit)
        external
        view
        returns (uint256[] memory);
}
