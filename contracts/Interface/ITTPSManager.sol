// SPDX-License-Identifier: MIT

import "./ITTPS.sol";

pragma solidity ^0.8.0;

interface ITTPSManager {
  event RequestMakeWatch(address indexed userAddress, uint256 indexed tokenId);
  event PutOnWatch(address indexed userAddress, uint256 indexed tokenId);
  event TakeOffWatch(address indexed userAddress, uint256 indexed tokenId);
  event ExchangeWithWatch(address indexed userAddress, uint256 indexed tokenId);

  function getWearingWatch(address addr) external view returns (uint256);

  function requestMakeWatch(
    address userAddr,
    string calldata tokenUri,
    ITTPS.mintInfo calldata info
  ) external;

  function putOnWatch(uint256 tokenId) external;

  function takeOffWatch() external;

  function exchangeWithWatch(address userAddr, uint256 tokenId) external;

  function isPossibleToMint(uint256 targetClass) external view returns (bool);

  function preMix(uint256 tokenId1, uint256 tokenId2) external;

  function postMix(
    uint256 tokenId1,
    uint256 tokenId2,
    uint256 mixTermSec,
    bool succeed
  ) external;

  function resetMixTerm(uint256 tokenId) external;
}
