// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./LendingStructs.sol";

interface ILending {
    function repay(address originator) external;

    function getOffer() external view returns (BorrowOffer memory);

    function getSelectedLendOffer() external view returns (LendOffer memory);

    function calculateInterest() external view returns (uint256);
}
