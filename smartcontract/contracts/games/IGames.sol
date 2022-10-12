// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IGames {
    function registerNftProvider(
        uint256 gameId,
        address nftAddress,
        address providerAddress
    ) external;

    function findNFTProvider(uint256 gameId, address nftAddress)
        external
        view
        returns (address);

    function isSupportedGame(uint256 gameId) external view returns (bool);

    function addGame(uint256 gameId) external;

    function removeGame(uint256 gameId) external;

    function addERC20(uint256 gameId, address[] calldata tokenAddresses) external;

    function addERC721(uint256 gameId, address[] calldata tokenAddresses) external;

    function removeERC20(uint256 gameId, address[] calldata tokenAddresses) external;

    function removeERC721(uint256 gameId, address[] calldata tokenAddresses) external;

    function getERC20Whitelist(uint256 _gameId) external view returns (address[] memory);

    function getERC721Whitelist(uint256 _gameId) external view returns (address[] memory);

    function isValidERC721(uint256 _gameId, address _tokenAddress) external view returns (bool);

    function isValidERC20(uint256 _gameId, address _tokenAddress) external view returns (bool);
}
