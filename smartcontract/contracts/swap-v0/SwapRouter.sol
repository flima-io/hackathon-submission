// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./FractionalToken.sol";
import "./SwapStruct.sol";
import "./SwapPool.sol";
import "./SwapPoolFactory.sol";
import "./ISwapRouter.sol";

import "./lib/uniswap-periphery/IUniswapV2Router01.sol";
import "./lib/uniswap-periphery/IWETH.sol";
import "./lib/uniswap-periphery/UniswapV2Library.sol";
import "./lib/uniswap/TransferHelper.sol";
import "../helper/MathHelper.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";

contract SwapRouter is ISwapRouter {
    uint256 constant fTokenDecimal = 10**18;

    address public immutable _factory;
    address public immutable _uniswapRouter;
    address public immutable _WETH;

    event BuyNFT(
        address indexed poolAddress,
        address indexed nft,
        address indexed buyer,
        uint256[] tokenIds
    );
    event SellNFT(
        address indexed poolAddress,
        address indexed nft,
        address indexed seller,
        uint256[] tokenIds
    );
    event BuyFractionalNFT();
    event SellFractionalNFT();

    constructor(
        address factory,
        address WETH,
        address uniswapRouter
    ) {
        _factory = factory;
        _WETH = WETH;
        _uniswapRouter = uniswapRouter;
    }

    // uniswap router will payback excessive ETH
    receive() external payable {}

    fallback() external payable {}

    // no state
    function buyNFT(
        address poolAddress,
        uint256[] calldata tokenIds,
        uint256 deadline
    ) external payable override isValidPoolAddress(poolAddress) {
        // [CHECKS]
        SwapPool pool = SwapPool(poolAddress);
        // [EFFECTS]
        // none
        // [INTERACTIONS]
        // inside this function, msg.value is validated
        uint256 fTokenAmount = tokenIds.length * fTokenDecimal;
        uint256 originalBalance = address(this).balance;
        IUniswapV2Router01(_uniswapRouter).swapETHForExactTokens{
            value: msg.value
        }(fTokenAmount, _getBuyPath(poolAddress), msg.sender, deadline);
        uint256 dust = msg.value - (originalBalance - address(this).balance);
        if (dust > 0) {
            TransferHelper.safeTransferETH(msg.sender, dust);
        }
        //        _swap(amounts, [_WETH], pool._fToken);

        // send NFT from pool to the buyer
        pool.withdrawTokens(tokenIds, msg.sender);
        // burn fToken
        FractionalToken(pool._fToken()).burn(msg.sender, fTokenAmount);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            IERC721(pool._nft()).safeTransferFrom(
                address(pool),
                msg.sender,
                tokenIds[i]
            );
        }
    }

    function sellNFT(
        address poolAddress,
        uint256 amountEthMin,
        uint256[] calldata tokenIds,
        uint256 deadline
    ) external override isValidPoolAddress(poolAddress) {
        // [CHECKS]
        SwapPool pool = SwapPool(poolAddress);
        IFilter filter = pool.getFilter();
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(filter.filter(tokenIds[i]), "E-d0e972bc6");
        }

        // [EFFECTS]
        // none

        // [INTERACTIONS]

        address[] memory path = _getSellPath(poolAddress);
        uint256 fTokenAmount = tokenIds.length * fTokenDecimal;
        // mint token to users wallet
        FractionalToken(pool._fToken()).mint(address(this), fTokenAmount);
        // then exchange token to ETH
        IUniswapV2Router01 uniswapRouter = IUniswapV2Router01(_uniswapRouter);
        uniswapRouter.swapExactTokensForETH(
            fTokenAmount,
            amountEthMin,
            path,
            msg.sender,
            deadline
        );

        pool.depositTokens(tokenIds, msg.sender);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            IERC721(pool._nft()).safeTransferFrom(
                msg.sender,
                address(pool),
                tokenIds[i]
            );
        }
    }

    // @dev exchange 1.0 fToken to any NFT item in the pool
    function swapFractionToItem(address poolAddress, uint256 tokenId) external {
        // [CHECKS]
        SwapPool pool = SwapPool(poolAddress);
        // [EFFECTS]
        // none
        // [INTERACTIONS]
        // inside this function, msg.value is validated
        uint256 fTokenAmount = 1 * fTokenDecimal;

        // send NFT from pool to the buyer
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;
        pool.withdrawTokens(tokenIds, msg.sender);

        // burn fToken
        FractionalToken(pool._fToken()).burn(msg.sender, fTokenAmount);
        IERC721(pool._nft()).safeTransferFrom(
            address(pool),
            msg.sender,
            tokenId
        );
    }

    function buyFractionalNFT(
        address poolAddress,
        uint256 fTokenAmount,
        uint256 deadline,
        bool isExactETH
    ) external payable override isValidPoolAddress(poolAddress) {
        // [CHECKS]
        // [EFFECTS]
        // none
        // [INTERACTIONS]
        // use uniswap pool to exchange ETH to fToken
        address[] memory path = _getBuyPath(poolAddress);
        // inside this function, msg.value is validated
        IUniswapV2Router01 uniswapRouter = IUniswapV2Router01(_uniswapRouter);
        if (isExactETH) {
            uniswapRouter.swapExactETHForTokens{value: msg.value}(
                fTokenAmount,
                path,
                msg.sender,
                deadline
            );
        } else {
            uniswapRouter.swapETHForExactTokens{value: msg.value}(
                fTokenAmount,
                path,
                msg.sender,
                deadline
            );
        }
    }

    function sellFractionalNFT(
        address poolAddress,
        uint256 fTokenAmount,
        uint256 ethAmount,
        uint256 deadline,
        bool isExactETH
    ) external override isValidPoolAddress(poolAddress) {
        _sellFractionalNFT(
            poolAddress,
            fTokenAmount,
            ethAmount,
            deadline,
            isExactETH
        );
    }

    function _sellFractionalNFT(
        address poolAddress,
        uint256 fTokenAmount,
        uint256 ethAmount,
        uint256 deadline,
        bool isExactETH
    ) private {
        // [CHECKS]
        // pool is a valid address
        // [EFFECTS]
        // none
        // [INTERACTIONS]
        // then exchange token to ETH

        // [temporary solution]. uniswap tries to withdraw token from msg.sender which is router contract address
        // so we have to transfer from user to router first. In the official version we have to modify uniswap
        // this solution does not work when isExactETH = true
        SwapPool pool = SwapPool(poolAddress);
        TransferHelper.safeTransferFrom(
            pool._fToken(),
            msg.sender,
            address(this),
            fTokenAmount
        );

        address[] memory path = _getSellPath(poolAddress);
        IUniswapV2Router01 uniswapRouter = IUniswapV2Router01(_uniswapRouter);
        if (isExactETH) {
            uniswapRouter.swapTokensForExactETH(
                ethAmount, // exact eth amount
                fTokenAmount, // fToken max
                path,
                msg.sender,
                deadline
            );
        } else {
            uniswapRouter.swapExactTokensForETH(
                fTokenAmount, // exact fToken amount
                ethAmount, // ethMin
                path,
                msg.sender,
                deadline
            );
        }
    }

    function _getBuyPath(address poolAddress)
        private
        view
        returns (address[] memory)
    {
        SwapPool pool = SwapPool(poolAddress);
        address[] memory path = new address[](2);
        path[0] = _WETH;
        path[1] = pool._fToken();
        return path;
    }

    function _getSellPath(address poolAddress)
        private
        view
        returns (address[] memory)
    {
        SwapPool pool = SwapPool(poolAddress);
        address[] memory path = new address[](2);
        path[0] = pool._fToken();
        path[1] = _WETH;
        return path;
    }

    modifier isValidPoolAddress(address poolAddress) {
        _;
    }

    modifier onlyFactory() {
        require(msg.sender == _factory, "E-d0e92256e");
        _;
    }

    function addInitialLiquidity(
        address poolAddress,
        uint256[] calldata tokenIds,
        uint256 deadline,
        address originalSender
    ) external payable override onlyFactory {
        // [CHECKS]
        //
        // [EFFECTS]
        // [INTERACTIONS]
        //
        SwapPool pool = SwapPool(poolAddress);
        uint256 fTokenAmount = tokenIds.length * fTokenDecimal;
        if (fTokenAmount > 0) {
            FractionalToken(pool._fToken()).mint(address(this), fTokenAmount);
        }
        pool.depositTokens(tokenIds, msg.sender);

        // INTERACTIONS
        for (uint256 i = 0; i < tokenIds.length; i++) {
            IERC721(pool._nft()).safeTransferFrom(
                originalSender,
                address(pool),
                tokenIds[i]
            );
        }
        FractionalToken(pool._fToken()).approve(_uniswapRouter, 2**255);

        address uniswapFactory = IUniswapV2Router01(_uniswapRouter).factory();
        address pair = IUniswapV2Factory(uniswapFactory).getPair(
            pool._fToken(),
            _WETH
        );
        FractionalToken(pair).approve(_uniswapRouter, 2**255);

        uint256 originalBalance = address(this).balance; // this must be called before addLiquidityETH
        if (msg.value > 0 && fTokenAmount > 0) {
            IUniswapV2Router01(_uniswapRouter).addLiquidityETH{
                value: msg.value
            }(
                pool._fToken(),
                fTokenAmount,
                fTokenAmount,
                msg.value,
                originalSender,
                deadline
            );
        }

        uint256 dust = msg.value - (originalBalance - address(this).balance);
        if (dust > 0) {
            TransferHelper.safeTransferETH(msg.sender, dust);
        }
    }

    function addLiquidity(
        address poolAddress,
        uint256[] calldata tokenIds,
        uint256 deadline
    ) external payable override {
        // [CHECKS]
        //
        // [EFFECTS]
        // [INTERACTIONS]
        //
        SwapPool pool = SwapPool(poolAddress);
        uint256 fTokenAmount = tokenIds.length * fTokenDecimal;
        FractionalToken(pool._fToken()).mint(address(this), fTokenAmount);
        pool.depositTokens(tokenIds, msg.sender);

        // INTERACTIONS
        for (uint256 i = 0; i < tokenIds.length; i++) {
            IERC721(pool._nft()).safeTransferFrom(
                msg.sender,
                address(pool),
                tokenIds[i]
            );
        }
        uint256 originalBalance = address(this).balance; // this must be called before addLiquidityETH
        IUniswapV2Router01(_uniswapRouter).addLiquidityETH{value: msg.value}(
            pool._fToken(),
            fTokenAmount,
            fTokenAmount,
            0,
            msg.sender,
            deadline
        );
        uint256 dust = msg.value - (originalBalance - address(this).balance);
        if (dust > 0) {
            TransferHelper.safeTransferETH(msg.sender, dust);
        }
    }

    function removeLiquidity(
        address poolAddress,
        uint256 liquidity,
        uint256 amountETHMin,
        uint256[] calldata tokenIds,
        uint256 deadline,
        HandleFraction handleType
    ) external override {
        // [CHECKS]
        // [EFFECTS]
        // burn fToken
        SwapPool pool = SwapPool(poolAddress);

        uint256 fTokenAmount = tokenIds.length * fTokenDecimal;
        address uniswapFactory = IUniswapV2Router01(_uniswapRouter).factory();
        address pair = IUniswapV2Factory(uniswapFactory).getPair(
            pool._fToken(),
            _WETH
        );
        TransferHelper.safeTransferFrom(
            pair,
            msg.sender,
            address(this),
            liquidity
        );
        // first we give fToken and ETH to user
        (uint256 amountA, uint256 amountB) = IUniswapV2Router01(_uniswapRouter)
            .removeLiquidityETH(
                pool._fToken(),
                liquidity,
                fTokenAmount,
                amountETHMin,
                msg.sender,
                deadline
            );
        require(amountA > fTokenAmount, "E-d0e7cc903");
        // then we exchange some amount of fToken to selected NFT
        pool.withdrawTokens(tokenIds, msg.sender);

        // INTERACTIONS
        for (uint256 i = 0; i < tokenIds.length; i++) {
            IERC721(pool._nft()).safeTransferFrom(
                address(pool),
                msg.sender,
                tokenIds[i]
            );
        }
        if (handleType == HandleFraction.NFT) {
            //
            require(false, "E-d0e7ccfcb");
        } else if (handleType == HandleFraction.FTOKEN) {
            // do nothing
        } else {
            //
            _sellFractionalNFT(
                poolAddress,
                amountA - fTokenAmount,
                0, // we don't know how much ETH we receive
                deadline,
                false
            );
        }
    }

    function getUniswapPairAddress(address poolAddress)
        external
        view
        override
        returns (address)
    {
        SwapPool pool = SwapPool(poolAddress);
        address uniswapFactory = IUniswapV2Router01(_uniswapRouter).factory();
        return IUniswapV2Factory(uniswapFactory).getPair(pool._fToken(), _WETH);
    }

    function getBuyingPrice(address poolAddress, uint256 amount)
        external
        view
        override
        returns (uint256)
    {
        SwapPool pool = SwapPool(poolAddress);
        (uint256 fTokenReserve, uint256 wethReserve) = UniswapV2Library
            .getReserves(
                SwapPoolFactory(_factory)._uniswapFactory(),
                pool._fToken(),
                _WETH
            );

        return UniswapV2Library.getAmountIn(amount, wethReserve, fTokenReserve);
    }

    function getSellingPrice(address poolAddress, uint256 amount)
        external
        view
        override
        returns (uint256)
    {
        SwapPool pool = SwapPool(poolAddress);

        (uint256 fTokenReserve, uint256 wethReserve) = UniswapV2Library
            .getReserves(
                SwapPoolFactory(_factory)._uniswapFactory(),
                pool._fToken(),
                _WETH
            );
        return
            UniswapV2Library.getAmountOut(amount, fTokenReserve, wethReserve);
    }

    function getBuyingAmount(address poolAddress, uint256 ethAmount)
        external
        view
        override
        returns (uint256)
    {
        SwapPool pool = SwapPool(poolAddress);
        (uint256 fTokenReserve, uint256 wethReserve) = UniswapV2Library
            .getReserves(
                SwapPoolFactory(_factory)._uniswapFactory(),
                pool._fToken(),
                _WETH
            );

        return
            UniswapV2Library.getAmountOut(
                ethAmount,
                wethReserve,
                fTokenReserve
            );
    }

    function getSellingAmount(address poolAddress, uint256 ethAmount)
        external
        view
        override
        returns (uint256)
    {
        SwapPool pool = SwapPool(poolAddress);

        (uint256 fTokenReserve, uint256 wethReserve) = UniswapV2Library
            .getReserves(
                SwapPoolFactory(_factory)._uniswapFactory(),
                pool._fToken(),
                _WETH
            );
        return
            UniswapV2Library.getAmountIn(ethAmount, fTokenReserve, wethReserve);
    }

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure override returns (uint256 amountOut) {
        return UniswapV2Library.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure override returns (uint256 amountIn) {
        return UniswapV2Library.getAmountOut(amountOut, reserveIn, reserveOut);
    }

    /**
     *
     */
    function getPool(address poolAddress)
        external
        view
        override
        returns (PoolInfo memory)
    {
        SwapPool pool = SwapPool(poolAddress);
        (uint256 fTokenReserve, uint256 wethReserve) = UniswapV2Library
            .getReserves(
                SwapPoolFactory(_factory)._uniswapFactory(),
                pool._fToken(),
                _WETH
            );
        PoolDescription memory desc = SwapPoolFactory(_factory)
            .getPoolDescription(poolAddress);
        return
            PoolInfo(
                desc.gameId,
                desc.nft,
                desc.description,
                address(pool),
                pool._nft(),
                pool._filter(),
                _WETH,
                pool._fToken(),
                fTokenReserve,
                pool.numberOfItems(),
                wethReserve,
                fTokenReserve > (11 * fTokenDecimal) / 10
                    ? UniswapV2Library.getAmountIn(
                        1 * fTokenDecimal,
                        wethReserve,
                        fTokenReserve
                    )
                    : 0,
                fTokenReserve > (11 * fTokenDecimal) / 10
                    ? UniswapV2Library.getAmountOut(
                        1 * fTokenDecimal,
                        fTokenReserve,
                        wethReserve
                    )
                    : 0
            );
    }

    function quoteLiquidityEth(address poolAddress, uint256 fTokenAmount)
        external
        view
        override
        returns (uint256)
    {
        SwapPool pool = SwapPool(poolAddress);
        (uint256 fTokenReserve, uint256 wethReserve) = UniswapV2Library
            .getReserves(
                SwapPoolFactory(_factory)._uniswapFactory(),
                pool._fToken(),
                _WETH
            );
        return UniswapV2Library.quote(fTokenAmount, fTokenReserve, wethReserve);
    }

    function quoteLiquidityFToken(address poolAddress, uint256 ethAmount)
        external
        view
        override
        returns (uint256)
    {
        SwapPool pool = SwapPool(poolAddress);
        (uint256 fTokenReserve, uint256 wethReserve) = UniswapV2Library
            .getReserves(
                SwapPoolFactory(_factory)._uniswapFactory(),
                pool._fToken(),
                _WETH
            );
        return UniswapV2Library.quote(ethAmount, wethReserve, fTokenReserve);
    }

    function liquidityBalanceOf(address poolAddress, address userAddress)
        external
        view
        returns (LiquidityBalance memory)
    {
        SwapPool pool = SwapPool(poolAddress);
        address uniswapFactory = IUniswapV2Router01(_uniswapRouter).factory();
        IUniswapV2Pair pair = IUniswapV2Pair(
            IUniswapV2Factory(uniswapFactory).getPair(pool._fToken(), _WETH)
        );
        uint256 totalSupply = pair.totalSupply();
        uint256 myBalance = pair.balanceOf(userAddress);
        (uint256 reserveA, uint256 reserveB) = UniswapV2Library.getReserves(
            SwapPoolFactory(_factory)._uniswapFactory(),
            pool._fToken(),
            _WETH
        );
        assert(totalSupply < 2**128);
        assert(myBalance < totalSupply); // assumption of mulScale
        uint256 fToken = MathHelper.percentage(
            reserveA,
            myBalance,
            uint128(totalSupply)
        );
        uint256 token = MathHelper.percentage(
            reserveB,
            myBalance,
            uint128(totalSupply)
        );
        return
            LiquidityBalance(
                poolAddress,
                userAddress,
                address(pair),
                fToken,
                token,
                myBalance
            );
    }
}
