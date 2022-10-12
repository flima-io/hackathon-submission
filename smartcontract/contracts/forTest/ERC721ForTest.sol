// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

abstract contract MockNFT is ERC721Enumerable {
    uint256 public lastTokenId = 0;

    /**
     * Mint a new NFT with new tokenId to the given address. For testing.
     */
    function mintNew(address to) external returns (uint256) {
        uint256 id = ++lastTokenId;
        _mint(to, id);
        return id;
    }
}

contract AXIEMONSTER is MockNFT {
    constructor() ERC721("Axie Monster", "AXIEMONSTER") {}
}

contract DFKHERO is MockNFT {
    constructor() ERC721("Dfk Hero", "DFKHERO") {}
}

contract SAYC is MockNFT {
    constructor() ERC721("Satisfied Ape Yacht Club", "SAYC") {}
}

contract BDYC is MockNFT {
    constructor() ERC721("Bored Doge Yacht Club", "BDYC") {}
}
