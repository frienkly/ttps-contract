// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ListedTokenInterface {
  function ownerOf(uint256 tokenId) external view returns (address);

  function tokenIdToMintingDate(uint256 tokenId)
    external
    view
    returns (uint256);

  function burn(uint256 tokenId) external;
}
