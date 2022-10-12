// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../games/IGames.sol";

contract Games is IGames, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    enum GameStatus {
        inactive,
        active
    }

    struct Game {
        GameStatus status;
        EnumerableSet.AddressSet ERC721Whitelist;
        EnumerableSet.AddressSet ERC20Whitelist;
    }

    // gameid => NFT address => Provider address
    mapping(uint256 => mapping(address => address)) private providerAddressesByNFT;

    // Game[] games;
    mapping(uint256 => Game) games;

    event GameAdded(uint256 indexed gameId);
    event GameRemoved(uint256 indexed gameId);
    event ERC20Added(uint256 indexed gameId, address[] token);
    event ERC20Removed(uint256 indexed gameId, address[] token);
    event ERC721Added(uint256 indexed gameId, address[] token);
    event ERC721Removed(uint256 indexed gameId, address[] token);
    event NftProviderRegisted(uint256 indexed gameId, address indexed nft, address provider);

    modifier validGameId(uint256 gameId) {
        require(gameId > 0, "E-d9d77a5e9");
        _;
    }

    modifier onlySupportedGame(uint256 _gameId) {
        Game storage game = games[_gameId];
        require(game.status == GameStatus.active, "E-d9da0fe4d");
        _;
    }

    modifier validAddress(address _address) {
        require(_address != address(0), "E-d9d6d2345");
        _;
    }

    function registerNftProvider(
        uint256 gameId,
        address nftAddress,
        address providerAddress
    )
        external
        override
        onlyOwner
        onlySupportedGame(gameId)
        validAddress(nftAddress)
        validAddress(providerAddress)
    {
        providerAddressesByNFT[gameId][nftAddress] = providerAddress;
        emit NftProviderRegisted(gameId, nftAddress, providerAddress);
    }

    function findNFTProvider(uint256 gameId, address nftAddress)
        external
        view
        override
        onlySupportedGame(gameId)
        validAddress(nftAddress)
        returns (address)
    {
        return providerAddressesByNFT[gameId][nftAddress];
    }

    function isSupportedGame(uint256 _gameId)
        external
        view
        override
        returns (bool)
    {
        Game storage game = games[_gameId];
        return game.status == GameStatus.active;
    }

    function addGame(
        uint256 _gameId
    )
        external
        override
        onlyOwner
        validGameId(_gameId)
    {
        Game storage newGame = games[_gameId];
        newGame.status = GameStatus.active;

        emit GameAdded(_gameId);
    }

    function removeGame(uint256 _gameId)
        external
        override
        onlyOwner
    {
        delete games[_gameId];
        emit GameRemoved(_gameId);
    }

    function addERC20(
        uint256 _gameId,
        address[] calldata _tokenAddresses
    )
        external
        override
        onlyOwner
        onlySupportedGame(_gameId)
    {
        Game storage game = games[_gameId];
        address tokenAddress;
        for (uint256 i = 0; i < _tokenAddresses.length; i++) {
            tokenAddress = _tokenAddresses[i];
            game.ERC20Whitelist.add(tokenAddress);
        }
        emit ERC20Added(_gameId, _tokenAddresses);
    }

    function addERC721(
        uint256 _gameId,
        address[] calldata _tokenAddresses
    )
        external
        override
        onlyOwner
        onlySupportedGame(_gameId)
    {
        Game storage game = games[_gameId];
        address tokenAddress;
        for (uint256 i = 0; i < _tokenAddresses.length; i++) {
            tokenAddress = _tokenAddresses[i];
            game.ERC721Whitelist.add(tokenAddress);
        }
        emit ERC721Added(_gameId, _tokenAddresses);
    }

    function removeERC20(
        uint256 _gameId,
        address[] calldata _tokenAddresses
    )
        external
        override
        onlyOwner
    {
        Game storage game = games[_gameId];
        address tokenAddress;
        for (uint256 i = 0; i < _tokenAddresses.length; i++) {
            tokenAddress = _tokenAddresses[i];
            game.ERC20Whitelist.remove(tokenAddress);
        }
        emit ERC20Removed(_gameId, _tokenAddresses);
    }

    function removeERC721(
        uint256 _gameId,
        address[] calldata _tokenAddresses
    )
        external
        override
        onlyOwner
    {
        Game storage game = games[_gameId];
        address tokenAddress;
        for (uint256 i = 0; i < _tokenAddresses.length; i++) {
            tokenAddress = _tokenAddresses[i];
            game.ERC721Whitelist.remove(tokenAddress);
        }
        emit ERC721Removed(_gameId, _tokenAddresses);
    }

    function getERC20Whitelist(uint256 _gameId)
        external
        view
        override
        returns (address[] memory)
    {
        Game storage game = games[_gameId];
        EnumerableSet.AddressSet storage whitelist = game.ERC20Whitelist;
        return whitelist.values();
    }

    function getERC721Whitelist(uint256 _gameId)
        external
        view
        override
        returns (address[] memory)
    {
        Game storage game = games[_gameId];
        EnumerableSet.AddressSet storage whitelist = game.ERC721Whitelist;
        return whitelist.values();
    }

    function isValidERC721(uint256 _gameId, address _tokenAddress)
        external
        view
        override
        returns (bool)
    {
        Game storage game = games[_gameId];
        EnumerableSet.AddressSet storage whitelist = game.ERC721Whitelist;
        return whitelist.contains(_tokenAddress);
    }

    function isValidERC20(uint256 _gameId, address _tokenAddress)
        external
        view
        override
        returns (bool)
    {
        Game storage game = games[_gameId];
        EnumerableSet.AddressSet storage whitelist = game.ERC20Whitelist;
        return whitelist.contains(_tokenAddress);
    }
}