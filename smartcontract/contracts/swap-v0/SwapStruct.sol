// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

struct PoolInfo {
    uint256 gameId;
    address nft;
    string description;
    address poolAddress;
    address nftAddress;
    address filterAddress;
    address tokenAddress;
    address fTokenAddress;
    uint256 reserveFToken;
    uint256 reserveNFT;
    uint256 reserveToken;
    uint256 currentBuyingPrice;
    uint256 currentSellingPrice;
}

enum HandleFraction {
    NFT,
    ETH,
    FTOKEN
}

struct FilterParams {
    uint256 _id;
    uint256 _gameId;
    bytes _bytecode;
    bytes _signature;
}

struct PoolParams {
    address nft;
    string description;
}

struct PoolDescription {
    uint256 gameId;
    address nft;
    address pool;
    string description;
}

struct LiquidityBalance {
    address poolAddress;
    address userAddress;
    address pairAddress;
    uint256 fToken;
    uint256 token;
    uint256 lpToken;
}
