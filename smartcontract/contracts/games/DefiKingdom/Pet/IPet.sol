// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./PetStructs.sol";

interface IPet {
    function getPet(uint256 _id) external view returns (Pet memory);

    function getUserPets(address _address) external view returns (Pet[] memory);
}
