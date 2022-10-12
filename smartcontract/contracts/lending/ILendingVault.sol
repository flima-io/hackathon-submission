// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./LendingStructs.sol";

interface ILendingVault {
    function setFactoryAddress(address _factoryAddress) external;

    function addNewLending(address lendingContractAddress, address borrower)
        external;

    function depositCollateralNFT(
        address originator,
        address _collateral,
        uint256 _tokenId
    ) external;

    function cancel(
        address originator,
        address _collateral,
        uint256 _tokenId
    ) external;

    function depositLoan(
        address lender,
        address _currency,
        uint256 _amount
    ) external;

    function withdrawLoan(
        address lender,
        address _currency,
        uint256 _amount
    ) external;

    function startLoan(
        address borrower,
        address lender,
        address currency,
        uint256 amount
    ) external;

    function repay(
        address originator,
        address currency,
        address lender,
        uint256 repayAmount,
        uint256 fee,
        address collateral,
        uint256 tokenId
    ) external;

    function liquidate(
        address _lender,
        address _collateral,
        uint256 _tokenId
    ) external;
}
