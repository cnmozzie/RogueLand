// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LoserLand.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Building {
  
  struct LandInfo {
    uint oldBuilding;
    uint newBuilding;
    uint builtTime;
    bool used;
    address owner;
  }
  
  address public owner;
  address public squidAddress;
  address public landAddress;
  address public gameAddress;
  bool public openSale;
  int outerBound = 625;

  mapping (address => bool) public isVIP;
  mapping (int => mapping (int => LandInfo)) public landInfo;

  constructor(address landAddress_, address squidAddress_) {
    owner = msg.sender;
    landAddress = landAddress_;
    squidAddress = squidAddress_;
  }

  function getLandInfo(int x1, int y1, int x2, int y2) public view returns (uint[] memory) {
    require(x2 >= x1 && y2 >= y1, "Invalid index");
    uint[] memory selectLands = new uint[](uint((x2-x1+1)*(y2-y1+1)));
    uint i = 0;
    for (int x=x1; x<=x2; x++) {
      for (int y=y1; y<=y2; y++) {
        LandInfo memory land = landInfo[x][y];
        selectLands[i] = land.builtTime > block.number? land.oldBuilding : land.newBuilding;
        i ++;
      }
    }
    return selectLands;
  }

  function landOf(int x, int y) public view returns (LandInfo memory) {
    LoserLand loserLand = LoserLand(landAddress);
    LandInfo memory land = landInfo[x][y];
    land.owner = loserLand.landOwner(x, y);
    return land;
  }

  function playerLand(address player) public view returns (int, int) {
    LoserLand land = LoserLand(landAddress);
    if (land.balanceOf(player) == 0) {
      return (0, 0);
    }
    else {
      uint landId = land.tokenOfOwnerByIndex(player, 0);
      return land.positionOf(landId);
    }
  }

  function isHouse(int x, int y) public view returns (bool) {
    LandInfo memory land = landInfo[x][y];
    uint kind = land.builtTime > block.number? land.oldBuilding : land.newBuilding;
    return kind == 1;
  }

  function getProductivity(int x, int y) public view returns (uint) {
    LandInfo memory land = landInfo[x][y];
    uint kind = land.builtTime > block.number? land.oldBuilding : land.newBuilding;
    if (kind == 0) {
      if (x**2 <= 9  &&  y**2 <= 9) {
        return 2;
      }
      else if (x**2 <= 100  &&  y**2 <= 100) {
        return 1;
      }
      else {
        return 0;
      }
    }
    else if (kind == 1) {
      return 0;
    }
    else {
      return getFee(kind-1);
    }
  }

  function setVIP(address[] calldata vips) public {
    require(msg.sender == owner, "Only admin can set VIPs.");
    uint length = vips.length;
    // batch set
    for (uint i=0; i<length; i++) {
      isVIP[vips[i]] = true;
    }
  }

  function setOpenSale(bool b) public {
    require(msg.sender == owner, "You are not admin");
    openSale = b;
  }

  function setOuterBound(int n) public {
    require(msg.sender == owner, "You are not admin");
    outerBound = n;
  }

  function setGameAddress(address addr) public {
    require(msg.sender == owner, "You are not admin");
    gameAddress = addr;
  }

  function _payFee(address player, uint amount) private {
    IERC20 squid = IERC20(squidAddress);
    require(squid.transferFrom(player, address(this), amount), 'Failed to transfer the squid token');
  }

  function payFee(address player, uint amount) public {
    require(msg.sender == gameAddress, "not allowed");
    _payFee(player, amount);
  }

  function award(address player, uint amount) public {
    require(msg.sender == gameAddress, "not allowed");
    IERC20 squid = IERC20(squidAddress);
    uint balance = squid.balanceOf(address(this));
    if (balance <= amount) {
      squid.transfer(player, balance);
    }
    else {
      squid.transfer(player, amount);
    }
  }

  function setUsed(int x, int y) public {
    require(msg.sender == gameAddress, "not allowed");
    landInfo[x][y].used = true;
  }

  function mint(int x, int y) public {
    require(openSale || isVIP[msg.sender], "cannot buy land for now");
    require(x**2 > 100  ||  y**2 > 100, "not open");
    require(x**2 < outerBound &&  y**2 < outerBound, "not open");
    _payFee(msg.sender, 1e18);
    LoserLand land = LoserLand(landAddress);
    land.awardLand(msg.sender, x, y);
    landInfo[x][y].newBuilding = 2;
    isVIP[msg.sender] = false;
  }

  function _build(int x, int y, uint kind) private {
    if (landInfo[x][y].builtTime <= block.number)
        landInfo[x][y].oldBuilding = landInfo[x][y].newBuilding;
    if (kind > 5) {
        landInfo[x][y].builtTime = block.number + getFee(kind)*1000;
    }
    else if (kind == 0) {
        landInfo[x][y].builtTime = block.number;
    }
    else {
        landInfo[x][y].builtTime = block.number + 10000;
    }
    landInfo[x][y].newBuilding = kind + 1;
  }

  function build(int x, int y, uint kind) public {
    LoserLand land = LoserLand(landAddress);
    require(land.landOwner(x, y) == msg.sender && kind <= 7, 'not allowed');
    _payFee(msg.sender, getFee(kind)*1e18);
    _build(x, y, kind);
  }

  function getFee(uint kind) public pure returns (uint) {
      if (kind <= 1) {
        return 1;
      }
      else if (kind <= 3) {
        return kind;
      }
      else if (kind == 4) {
        return 5;
      }
      else if (kind == 5) {
        return 10;
      }
      else if (kind == 6) {
        return 25;
      }
      else {
        return 100;
      }
    }
}
