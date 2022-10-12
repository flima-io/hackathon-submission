// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

struct CreateFilterProps {
    uint256 gameId;
    address nftAddress;
	address gameAddress;
	bytes filterBytecode;
    bytes signature;
}
