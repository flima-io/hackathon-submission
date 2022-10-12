// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./LandStructs.sol";

interface ILand {
    function getLand(uint256 _landId) external view returns (LandMeta memory);

    function getAllLands() external view returns (LandMeta[] memory);

    function getLandsByRegion(uint32 _region)
        external
        view
        returns (LandMeta[] memory);

    function getAccountLands(address _account)
        external
        view
        returns (LandMeta[] memory);
}
