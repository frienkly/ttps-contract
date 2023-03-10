// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ListedTokenInterface.sol";

interface ClassedTokenInterface is ListedTokenInterface {
  function tokenIdToClass(uint256 tokenId)
    external
    view
    returns (string memory);
}
