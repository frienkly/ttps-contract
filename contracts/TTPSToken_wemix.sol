// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./TTPS.sol";
import "./Interface/ClassedTokenInterface.sol";

contract TTPSToken is TTPS, ClassedTokenInterface {
  address public rewarder;

  mapping(uint256 => uint256) public mintingDate;

  event SetRewarder(address indexed prev, address indexed to);

  constructor(address feeAddr, address rewarderAddress) TTPS(feeAddr) {
    rewarder = rewarderAddress;
  }

  function contractURI() public pure returns (string memory) {
    return "https://tangled.im/watch-metadata/wemix";
  }

  function setMintingDate(uint256 tokenId, uint256 time)
    external
    onlyRole(TTPSTOKEN_ROLE)
  {
    mintingDate[tokenId] = time;
  }

  function setMultiMintingDate(uint256[] calldata tokenIds, uint256 time)
    external
    onlyRole(TTPSTOKEN_ROLE)
  {
    for (uint256 i = 0; i < tokenIds.length; ++i) {
      mintingDate[tokenIds[i]] = time;
    }
  }

  function setRewarderAddress(address addr) external onlyRole(TTPSTOKEN_ROLE) {
    require(addr != address(0), "Rewarder address shold not be ZERO adress");
    address prev = rewarder;
    rewarder = addr;

    emit SetRewarder(prev, addr);
  }

  function tokenIdToMintingDate(uint256 tokenId)
    external
    view
    returns (uint256)
  {
    return mintingDate[tokenId];
  }

  function tokenIdToClass(uint256 tokenId)
    external
    view
    returns (string memory)
  {
    TTPSClass class = getWatchInfo(tokenId).class;
    if (class == TTPSClass.LUXURY) return "LUXURY";
    else if (class == TTPSClass.HIGHEND) return "HIGHEND";
    else if (class == TTPSClass.ZENITH) return "ZENITH";
    else return "";
  }

  function ownerOf(uint256 tokenId)
    public
    view
    override(ListedTokenInterface, ERC721)
    returns (address)
  {
    return super.ownerOf(tokenId);
  }

  function burn(uint256 tokenId) public override(TTPS, ListedTokenInterface) {
    // TODO: implement later
    require(
      msg.sender == rewarder || _isApprovedOrOwner(_msgSender(), tokenId),
      "ERC721: caller is not token owner nor approved"
    );
    super._burn(tokenId);
  }
}
