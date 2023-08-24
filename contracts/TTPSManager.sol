// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./Interface/ITTPS.sol";
import "./Interface/ITTPSManager.sol";

// Contract for managing TTPS Token
contract TTPSManager is AccessControl, ITTPSManager {
  bytes32 public constant TTPS_MANAGER_ROLE = keccak256("TTPS_MANAGER_ROLE");
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant CHANGE_WATCH_INFO_ROLE =
    keccak256("CHANGE_WATCH_INFO_ROLE");

  address public immutable ttps;

  mapping(uint256 => uint256) public maxAmountsOfClass;
  mapping(uint256 => uint256) public currentAmountsOfClass;
  mapping(address => uint256) private _wearingWatch;

  constructor(address ttpsAddress, uint256[3] memory amounts) {
    ttps = ttpsAddress;
    for (uint256 i = 0; i < amounts.length; ++i)
      maxAmountsOfClass[i] = amounts[i];

    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
  }

  modifier isTokenOwner(address userAddr, uint256 tokenId) {
    require(
      ITTPS(ttps).ownerOf(tokenId) == userAddr,
      "This token is not owned by user"
    );
    _;
  }

  function getWearingWatch(address addr) external view returns (uint256) {
    return _wearingWatch[addr];
  }

  function setMaxAmountOfClass(uint256[3] memory amounts)
    external
    onlyRole(TTPS_MANAGER_ROLE)
  {
    for (uint256 i = 0; i < amounts.length; ++i)
      maxAmountsOfClass[i] = amounts[i];
  }

  // request minting new TTPS Token
  function requestMakeWatch(
    address userAddr,
    string calldata tokenUri,
    ITTPS.mintInfo calldata info
  ) external onlyRole(MINTER_ROLE) {
    require(info.class < ITTPS.TTPSClass.MAX, "Invalid class info");

    uint256 targetClass = uint256(info.class);
    require(isPossibleToMint(targetClass), "Cannot produce watch anymore");

    ++currentAmountsOfClass[targetClass];
    ITTPS(ttps).makeWatch(userAddr, tokenUri, info);

    emit RequestMakeWatch(userAddr, info.tokenId);
  }

  function putOnWatch(uint256 tokenId)
    external
    isTokenOwner(_msgSender(), tokenId)
  {
    address userAddress = _msgSender();
    uint256 prev = _wearingWatch[userAddress];
    if (prev == tokenId) return;

    ITTPS TTPS = ITTPS(ttps);
    ITTPS.TTPSInfo memory info = TTPS.getWatchInfo(tokenId);
    info.isWearing = true;
    info.expectedExchangeTime = block.timestamp + info.remainedExchangeSec;
    _wearingWatch[userAddress] = tokenId;

    if (prev != 0) {
      ITTPS.TTPSInfo memory prevInfo = _calcRemainedExchangeSec(prev);
      TTPS.setWatchInfo(prev, prevInfo);
    }
    TTPS.setWatchInfo(tokenId, info);

    emit PutOnWatch(userAddress, tokenId);
  }

  function takeOffWatch() external {
    address userAddress = _msgSender();
    uint256 currentWatch = _wearingWatch[userAddress];
    require(currentWatch != 0, "Not wearing tangled watch");

    ITTPS.TTPSInfo memory info = _calcRemainedExchangeSec(currentWatch);
    _wearingWatch[userAddress] = 0;

    ITTPS(ttps).setWatchInfo(currentWatch, info);

    emit TakeOffWatch(userAddress, currentWatch);
  }

  function _calcRemainedExchangeSec(uint256 tokenId)
    private
    view
    returns (ITTPS.TTPSInfo memory)
  {
    ITTPS.TTPSInfo memory info = ITTPS(ttps).getWatchInfo(tokenId);

    info.isWearing = false;
    if (block.timestamp >= info.expectedExchangeTime)
      info.remainedExchangeSec = 0;
    else
      info.remainedExchangeSec = uint128(
        info.expectedExchangeTime - block.timestamp
      );

    return info;
  }

  // exchange Time to TIPO, should be requested by wearing watch
  function exchangeWithWatch(address userAddr, uint256 tokenId)
    external
    isTokenOwner(userAddr, tokenId)
    onlyRole(CHANGE_WATCH_INFO_ROLE)
  {
    uint256 currentWatch = _wearingWatch[userAddr];
    require(currentWatch != 0, "Not wearing tangled watch");
    require(
      currentWatch == tokenId,
      "Exchange should be executed by wearing watch"
    );

    ITTPS.TTPSInfo memory info = ITTPS(ttps).getWatchInfo(
      currentWatch
    );
    require(
      block.timestamp >= info.expectedExchangeTime,
      "Not possible to exchange yet"
    );

    info.remainedExchangeSec = info.exchangeTermSec;
    info.expectedExchangeTime = block.timestamp + info.remainedExchangeSec;
    ITTPS(ttps).setWatchInfo(currentWatch, info);

    emit ExchangeWithWatch(userAddr, currentWatch);
  }

  function isPossibleToMint(uint256 targetClass) public view returns (bool) {
    return currentAmountsOfClass[targetClass] < maxAmountsOfClass[targetClass];
  }

  function preMix(uint256 tokenId1, uint256 tokenId2)
    external
    onlyRole(CHANGE_WATCH_INFO_ROLE)
  {
    require(tokenId1 != tokenId2, "Have to mix 2 different watches");

    ITTPS TTPS = ITTPS(ttps);
    ITTPS.TTPSInfo memory info1 = TTPS.getWatchInfo(tokenId1);
    info1.isMixing = true;

    ITTPS.TTPSInfo memory info2 = TTPS.getWatchInfo(tokenId2);
    info2.isMixing = true;

    TTPS.setWatchInfo(tokenId1, info1);
    TTPS.setWatchInfo(tokenId2, info2);
  }

  function postMix(
    uint256 tokenId1,
    uint256 tokenId2,
    uint256 mixTermSec,
    bool succeed
  ) external onlyRole(CHANGE_WATCH_INFO_ROLE) {
    require(tokenId1 != tokenId2, "Have to mix 2 different watches");

    ITTPS TTPS = ITTPS(ttps);
    if (succeed) {
      TTPS.burn(tokenId1);
      TTPS.burn(tokenId2);
    } else {
      ITTPS.TTPSInfo memory info1 = TTPS.getWatchInfo(tokenId1);
      info1.nextMixTime = block.timestamp + mixTermSec;
      info1.isMixing = false;

      ITTPS.TTPSInfo memory info2 = TTPS.getWatchInfo(tokenId2);
      info2.nextMixTime = block.timestamp + mixTermSec;
      info2.isMixing = false;

      TTPS.setWatchInfo(tokenId1, info1);
      TTPS.setWatchInfo(tokenId2, info2);
    }
  }

  function resetMixTerm(uint256 tokenId)
    external
    onlyRole(CHANGE_WATCH_INFO_ROLE)
  {
    ITTPS.TTPSInfo memory info = ITTPS(ttps).getWatchInfo(tokenId);
    require(
      info.nextMixTime > block.timestamp,
      "This watch is already possible to be mix"
    );

    info.nextMixTime = block.timestamp;
    ITTPS(ttps).setWatchInfo(tokenId, info);
  }

  function destroy(address payable to)
    external
    payable
    onlyRole(TTPS_MANAGER_ROLE)
  {
    require(to != address(0), "Cannot transfer to ZERO address");

    selfdestruct(to);
  }
}
