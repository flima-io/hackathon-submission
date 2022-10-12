// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IFilter.sol";

abstract contract Proxy is IFilter {
    // @dev given a token id,
    /**
     * @dev A proxy function that calls
     * @param _tokenId hoge
     */
    function call(uint256 _tokenId, address _contract) external {}
}
