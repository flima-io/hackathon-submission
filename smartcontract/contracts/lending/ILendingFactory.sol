// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./LendingStructs.sol";

interface ILendingFactory {
    function repay(
        uint256 _gameId,
        uint256 _offerId,
        address currency,
        address borrower,
        address lender,
        uint256 repayAmount,
        uint256 fee
    ) external;
}
