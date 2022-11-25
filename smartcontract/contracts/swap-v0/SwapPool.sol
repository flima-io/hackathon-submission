// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ISwapPool.sol";
import "../filter/IFilter.sol";
import "./lib/uniswap-core/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "hardhat/console.sol";

contract SwapPool is ISwapPool, IERC721Receiver {
    // tokenId => boolean
    // mapping(uint256 => bool) _tokens;
    using EnumerableSet for EnumerableSet.UintSet;
    EnumerableSet.UintSet _tokens;
    address public immutable _nft;
    address public immutable _router;
    address public immutable _fToken;
    address public immutable _filter;
    uint256 public numberOfItems = 0;

    event DepositToken(uint256[] tokenIds);
    event WithdrawToken(uint256[] tokenIds);

    constructor(
        address nft,
        address router,
        address fToken,
        address filter
    ) {
        _nft = nft;
        _router = router;
        _fToken = fToken;
        _filter = filter;
        IERC721(nft).setApprovalForAll(router, true);
    }

    function depositTokens(uint256[] calldata tokenIds, address from)
        external
        override
        onlyRouter
    {
        // CHECKS
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(!_tokens.contains(tokenIds[i]), "E-1b609ccfc");
        }

        // EFFECTS
        _addTokenIds(tokenIds);

        // // INTERACTIONS
        emit DepositToken(tokenIds);
    }

    function withdrawTokens(uint256[] calldata tokenIds, address to)
        external
        override
        onlyRouter
    {
        // CHECKS
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(_tokens.contains(tokenIds[i]), "E-1b6b713e3");
        }
        // EFFECTS
        _removeTokenIds(tokenIds);

        emit WithdrawToken(tokenIds);
    }

    function hasTokenId(uint256 tokenId) external view override returns (bool) {
        return _tokens.contains(tokenId);
    }

    function _addTokenIds(uint256[] calldata tokenIds) internal onlyRouter {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _tokens.add(tokenIds[i]);
        }
        numberOfItems += tokenIds.length;
    }

    function _removeTokenIds(uint256[] calldata tokenIds) internal onlyRouter {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _tokens.remove(tokenIds[i]);
        }
        numberOfItems -= tokenIds.length;
    }

    function getTokenIds(uint256 offset, uint256 limit)
        external
        view
        override
        returns (uint256[] memory)
    {
        if (limit == 0) {
            limit = 10;
        }
        if (limit > 100) {
            limit = 100;
        }
        if (_tokens.length() < offset + limit) {
            limit = uint8(_tokens.length() - offset);
        }

        uint256[] memory result = new uint256[](limit);
        for (uint256 i = 0; i < limit; i++) {
            result[i] = _tokens.at(i + offset);
        }
        return result;
    }

    modifier onlyRouter() {
        require(msg.sender == _router, "E-1b60b01ca");
        _;
    }

    function getFilter() external view override returns (IFilter) {
        return IFilter(_filter);
    }

    /**
     * Necessary to hold NFT. See IERC721Receiver.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
