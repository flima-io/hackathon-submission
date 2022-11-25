// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./SwapStruct.sol";

/**
 *
 */
interface ISwapRouter {
    /**
     * @dev buy NFT from a pool
     *
     * - CHECKS
     *   - enough
     * - EFFECTS
     * - INTERACTIONS
     */
    function buyNFT(
        address poolAddress,
        uint256[] calldata tokenIds,
        uint256 deadline
    ) external payable;

    function sellNFT(
        address poolAddress,
        uint256 amountEthMin,
        uint256[] calldata tokenIds,
        uint256 deadline
    ) external;

    function buyFractionalNFT(
        address poolAddress,
        uint256 fTokenAmount,
        uint256 deadline,
        bool isExactETH
    ) external payable;

    function sellFractionalNFT(
        address poolAddress,
        uint256 fTokenAmount,
        uint256 ethAmount,
        uint256 deadline,
        bool isExactETH
    ) external;

    function addInitialLiquidity(
        address poolAddress,
        uint256[] calldata tokenIds,
        uint256 deadline,
        address originalSender
    ) external payable;

    function addLiquidity(
        address poolAddress,
        uint256[] calldata tokenIds,
        uint256 deadline
    ) external payable;

    function removeLiquidity(
        address poolAddress,
        uint256 liquidity,
        uint256 amountETHMin,
        uint256[] calldata tokenIds,
        uint256 deadline,
        HandleFraction handleType
    ) external;

    /**
     * Get estimated ETH amount to buy 1 NFT
     * pair = router.getUniswapPairAddress();
     * [ reserve1, reserve2, timestamp ] = IUniswapV2Pair(pair).getReserves();
     * router.getAmountIn()
     */
    function getUniswapPairAddress(address poolAddress)
        external
        view
        returns (address);

    function getBuyingPrice(address poolAddress, uint256 amount)
        external
        view
        returns (uint256);

    function getSellingPrice(address poolAddress, uint256 amount)
        external
        view
        returns (uint256);

    function getBuyingAmount(address poolAddress, uint256 ethAmount)
        external
        view
        returns (uint256);

    function getSellingAmount(address poolAddress, uint256 ethAmount)
        external
        view
        returns (uint256);

    function quoteLiquidityEth(address poolAddress, uint256 fTokenAmount)
        external
        view
        returns (uint256);

    function quoteLiquidityFToken(address poolAddress, uint256 ethAmount)
        external
        view
        returns (uint256);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    /**
     *
     */
    function getPool(address poolAddress)
        external
        view
        returns (PoolInfo memory);
}
