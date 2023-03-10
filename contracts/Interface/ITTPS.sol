// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface ITTPS is IERC721Enumerable {
  enum TTPSClass {
    LUXURY,
    HIGHEND,
    ZENITH,
    MAX
  } // unint8

  struct mintInfo {
    uint256 tokenId;
    TTPSClass class;
    uint64 exchangeFee;
    uint128 exchangeTermSec;
    uint128 pointLimit;
  }

  struct TTPSInfo {
    bool isWearing;
    bool isMixing;
    TTPSClass class;
    uint64 exchangeFee;
    uint128 exchangeTermSec;
    uint128 pointLimit;
    uint128 remainedExchangeSec;
    uint256 expectedExchangeTime;
    uint256 nextMixTime;
  }

  event SetFeeAddress(address indexed prev, address indexed to);
  event MakeWatch(address indexed userAddress, uint256 indexed tokenId);

  function getWatchInfo(uint256 tokenId)
    external
    view
    returns (TTPSInfo memory);

  function setWatchInfo(uint256 tokenId, TTPSInfo calldata info) external;

  function makeWatch(
    address userAddr,
    string calldata tokenUri,
    mintInfo calldata info
  ) external;

  function exists(uint256 tokenId) external view returns (bool);

  function burn(uint256 tokenId) external;
}
