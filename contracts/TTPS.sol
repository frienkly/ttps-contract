// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "./ERC2981.sol";
import "./Interface/ITTPS.sol";

abstract contract TTPS is
  ERC2981,
  ERC721URIStorage,
  ERC721Enumerable,
  ERC721Burnable,
  ERC721Holder,
  AccessControl,
  ITTPS
{
  bytes32 public constant TTPSTOKEN_ROLE = keccak256("TTPSTOKEN_ROLE");
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant TTPSINFO_EDIT_ROLE = keccak256("TTPSINFO_EDIT_ROLE");

  address public feeAddress;

  mapping(uint256 => TTPSInfo) private _ttpsInfos;
  mapping(uint8 => uint96) public royaltyValue;

  constructor(address feeAddr) ERC721("Tangled", "TTPS") {
    feeAddress = feeAddr;

    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

    royaltyValue[0] = 20;
    royaltyValue[1] = 30;
    royaltyValue[2] = 50;
  }

  function getWatchInfo(uint256 tokenId) public view returns (TTPSInfo memory) {
    return _ttpsInfos[tokenId];
  }

  function setFeeAddress(address addr) external onlyRole(TTPSTOKEN_ROLE) {
    require(addr != address(0), "Fee address should not be ZERO address");
    address prev = feeAddress;
    feeAddress = addr;

    emit SetFeeAddress(prev, feeAddress);
  }

  function setWatchInfo(uint256 tokenId, TTPSInfo calldata info)
    external
    onlyRole(TTPSINFO_EDIT_ROLE)
  {
    _ttpsInfos[tokenId] = info;
  }

  function setRoyaltyValue(uint8 ttpsClass, uint96 val)
    external
    onlyRole(TTPSTOKEN_ROLE)
  {
    royaltyValue[ttpsClass] = val;
  }

  function makeWatch(
    address userAddr,
    string calldata tokenUri,
    mintInfo calldata info
  ) external onlyRole(MINTER_ROLE) {
    _ttpsInfos[info.tokenId] = TTPSInfo({
      isWearing: false,
      isMixing: false,
      class: info.class,
      exchangeFee: info.exchangeFee,
      exchangeTermSec: info.exchangeTermSec,
      pointLimit: info.pointLimit,
      remainedExchangeSec: 0,
      expectedExchangeTime: 0,
      nextMixTime: info.class < TTPSClass.ZENITH ? block.timestamp : 0
    });

    _setTokenRoyalty(info.tokenId, feeAddress, royaltyValue[uint8(info.class)]);

    _safeMint(userAddr, info.tokenId);
    _setTokenURI(info.tokenId, tokenUri);

    emit MakeWatch(userAddr, info.tokenId);
  }

  function getOwnTokens(address addr) public view returns (uint256[] memory) {
    uint256 count = balanceOf(addr);
    uint256[] memory tokenIds = new uint256[](count);

    for (uint256 i = 0; i < count; ++i) {
      tokenIds[i] = tokenOfOwnerByIndex(addr, i);
    }

    return tokenIds;
  }

  function exists(uint256 tokenId) external view returns (bool) {
    return super._exists(tokenId);
  }

  function burn(uint256 tokenId)
    public
    virtual
    override(ERC721Burnable, ITTPS)
  {
    super.burn(tokenId);
  }

  function _burn(uint256 tokenId)
    internal
    virtual
    override(ERC721URIStorage, ERC721)
  {
    delete _ttpsInfos[tokenId];
    super._burn(tokenId);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override(ERC721URIStorage, ERC721)
    returns (string memory)
  {
    return super.tokenURI(tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC2981, ERC721Enumerable, ERC721, IERC165, AccessControl)
    returns (bool)
  {
    return
      ERC2981.supportsInterface(interfaceId) ||
      super.supportsInterface(interfaceId);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override(ERC721Enumerable, ERC721) {
    require(
      !(_ttpsInfos[tokenId].isWearing || _ttpsInfos[tokenId].isMixing),
      "Cannot transfer wearing or mixing tangled watch"
    );

    super._beforeTokenTransfer(from, to, tokenId);
  }

  function destroy(address payable to)
    external
    payable
    onlyRole(TTPSTOKEN_ROLE)
  {
    require(to != address(0), "Cannot transfer to ZERO address");

    selfdestruct(to);
  }
}
