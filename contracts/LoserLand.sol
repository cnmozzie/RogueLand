// contracts/GameItem.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract LoserLand is ERC721Enumerable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    struct Position {
      int x;
      int y;
    }

    string baseTokenURI = "https://www.losernft.org/loserland/";

    address public owner;

    // 返回土地拥有者
    mapping (int => mapping (int => uint)) public landOf;
    mapping (uint => Position) public positionOf;
    mapping (address => bool) public isAdmin;

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) { owner = msg.sender; }

    function awardLand(address player, int x, int y) public returns (uint256)
    {
        require(isAdmin[msg.sender], "You are not admin");
        require(landOwner(x, y) == address(0), "already mint");
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(player, newItemId);
        positionOf[newItemId] = Position(x, y);
        landOf[x][y] = newItemId;
        return newItemId;
    }

    function setAdmin(address candidate, bool b) public {
        require(msg.sender == owner, "You are not admin");
        isAdmin[candidate] = b;
    }

    function landOwner(int x, int y) public view returns (address) {
        uint id = landOf[x][y];
        if (id == 0) {
            return address(0);
        }
        else {
            return ownerOf(id);
        }
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(baseTokenURI, Strings.toString(_tokenId), ".json"));
    }
}