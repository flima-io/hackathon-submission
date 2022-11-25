// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./FractionalToken.sol";
import "./SwapPool.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../filter/IFilterFactory.sol";
import "./lib/uniswap-core/IUniswapV2Factory.sol";
import "./SwapStruct.sol";
import "./ISwapPoolFactory.sol";
import "./ISwapRouter.sol";

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./lib/uniswap-periphery/IUniswapV2Router01.sol";
import "hardhat/console.sol";

contract SwapPoolFactory is Ownable, ISwapPoolFactory {
    uint256 constant fTokenDecimal = 10**18;
    using EnumerableSet for EnumerableSet.AddressSet;
    mapping(uint256 => mapping(address => EnumerableSet.AddressSet)) _poolAddresses;
    mapping(address => PoolDescription) _poolDescriptions;

    address public immutable _uniswapFactory;
    address public immutable _uniswapRouter;
    address public immutable _filterFactory;
    address public immutable _WETH;
    address public immutable _gameAddress;
    address public _router; // set later
    struct CreatePoolParams {
        address nft;
    }

    constructor(
        address uniswapFactory,
        address uniswapRouter,
        address filterFactory,
        address gameAddress,
        address WETH
    ) {
        _uniswapFactory = uniswapFactory;
        _uniswapRouter = uniswapRouter;
        _WETH = WETH;
        _filterFactory = filterFactory;
        _gameAddress = gameAddress;
    }

    function setRouter(address router) external onlyOwner {
        _router = router;
    }

    event PoolCreated(
        address creator,
        uint256 indexed gameId,
        address indexed nft,
        address pool,
        address uniswapPair,
        address fToken,
        address filter
    );

    function createPool(
        uint256 gameId,
        PoolParams calldata poolParams,
        FilterParams calldata filterParams,
        uint256[] calldata tokenIds
    ) external payable override returns (address) {
        //// gas 63228
        // [CHECKS]
        // TODO: check nft address
        // [EFFECTS]

        // create elastic subset contract
        IFilter filter = IFilter(
            IFilterFactory(_filterFactory).createFilter(
                filterParams._id,
                filterParams._gameId,
                poolParams.nft,
                _gameAddress,
                filterParams._bytecode,
                filterParams._signature
            )
        );
        //// gas 792597
        // create new fToken contract
        FractionalToken fToken = new FractionalToken("Flima fToken", "fToken");
        // call uniswap v2 factory to create DEX pool between ETH
        //// gas 1679855
        address pair = IUniswapV2Factory(_uniswapFactory).createPair(
            address(fToken),
            _WETH
        );
        //// gas 4925818
        SwapPool pool = new SwapPool(
            poolParams.nft,
            _router,
            address(fToken),
            address(filter)
        );

        //// gas 5605388
        fToken.setRouterAddress(address(_router));
        // transfer ownership to deployer address
        //// gas 5629622
        fToken.transferOwnership(owner());

        _poolAddresses[gameId][poolParams.nft].add(address(pool));
        _poolDescriptions[address(pool)] = PoolDescription(
            filterParams._gameId,
            poolParams.nft,
            address(pool),
            poolParams.description
        );
        //// gas 5794485
        ISwapRouter(_router).addInitialLiquidity{value: msg.value}(
            address(pool),
            tokenIds,
            block.timestamp,
            msg.sender
        );
        //// gas 6228624
        emit PoolCreated(
            msg.sender,
            gameId,
            poolParams.nft,
            address(pool),
            address(pair),
            address(fToken),
            address(filter)
        );
        return address(pool);
    }

    function listPool(
        uint256 gameId,
        address nft,
        uint256 offset,
        uint256 limit
    ) external view override returns (PoolDescription[] memory) {
        if (limit == 0) {
            limit = 10;
        }
        if (limit > 100) {
            limit = 100;
        }
        EnumerableSet.AddressSet storage addresses = _poolAddresses[gameId][
            nft
        ];
        if (addresses.length() < offset + limit) {
            limit = uint8(addresses.length() - offset);
        }

        PoolDescription[] memory result = new PoolDescription[](limit);
        for (uint256 i = 0; i < limit; i++) {
            address pool = addresses.at(i + offset);
            result[i] = _poolDescriptions[pool];
        }

        return result;
    }

    function getPoolDescription(address poolAddress)
        external
        view
        override
        returns (PoolDescription memory)
    {
        return _poolDescriptions[poolAddress];
    }
}
