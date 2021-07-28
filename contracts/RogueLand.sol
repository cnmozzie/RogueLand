// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RogueLand {
  struct Player {
    uint x;
    uint y;
    uint rewards;
    uint nextAction;
  }
  
  struct Action {
    address player;
    uint runs;
    uint actionType;
    uint playerNextAction;
    uint nextActionToExecute;
  }
  
  struct Gold {
    uint quantity;
    uint totalMiner;
    uint x;
    uint y;
  }
  
  // 储存玩家信息
  mapping (address => Player) public player;
  
  // 储存玩家的操作链
  mapping (address => Action) public currentActionOf;
  
  // 根据id存储所有操作
  mapping (uint => Action) public action;
  
  // 存储金矿信息
  Gold[6] gold;
}
