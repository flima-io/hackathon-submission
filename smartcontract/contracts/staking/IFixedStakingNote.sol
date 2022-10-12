// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./IFixedStakingPool.sol";

abstract contract IFixedStakingNote is ERC721Enumerable {
    function mint(FixedStaking calldata _fixedStaking) external virtual;

    function burn(uint256 tokenId) external virtual;

    function getClaimable(uint256 _tokenId)
        external
        view
        virtual
        returns (uint256);

    function getStaking(uint256 _tokenId)
        external
        view
        virtual
        returns (uint256);

    function canWithdraw(uint256 _id) external view virtual returns (bool);

    function getUnlockDate(uint256 _id) external view virtual returns (uint256);
}
