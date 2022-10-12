// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library ChainHelper {
  function chainId() internal view returns (uint256) {
    uint256 _chainId;
    assembly {
      _chainId := chainid()
    }
    return _chainId;
  }
}
