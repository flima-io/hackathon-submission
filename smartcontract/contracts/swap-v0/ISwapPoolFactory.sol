// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./SwapStruct.sol";

import "./FractionalToken.sol";
import "./SwapPool.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../filter/IFilterFactory.sol";
import "./lib/uniswap-core/IUniswapV2Factory.sol";

interface ISwapPoolFactory {
    /**
     * @dev create a new pool
     * - CHECKS
     *   - nft address is in the game
     * - EFFECTS
     *   - no effects (no state)
     * - INTERACTIONS
     *   - create filter contract
     *   - create uniswap v2 pool
     *   - create SwapPool
     */
    function createPool(
        uint256 gameId,
        PoolParams calldata poolParams,
        FilterParams calldata filterParams,
        uint256[] calldata tokenIds
    ) external payable returns (address);

    function listPool(
        uint256 gameId,
        address nft,
        uint256 offset,
        uint256 limit
    ) external view returns (PoolDescription[] memory);

    function getPoolDescription(address poolAddress)
        external
        view
        returns (PoolDescription memory);
}
