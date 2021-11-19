// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RogueLand {
    
    enum ActionChoices { SitStill, GoLeft, GoRight, GoUp, GoDown, GoLeftUp, GoLeftDown, GoRightUp, GoRightDown }
	
    struct MovingPunk {
      uint punkId;
      uint punkNonce;
    }

    struct KillEvent {
      uint A;
      uint B;
      uint t;
      int x;
      int y;
    }

    struct TimeSpace {
      uint t;
      int x;
      int y;
    }

    struct Position {
      int x;
      int y;
    }

    struct StillPunk {
      uint oldNeighbor;
      uint newNeighbor;
      int x;
      int y;
      uint showtime;
      uint gold;
      uint enemy;
      uint hp;
      uint nonce; // 代表死亡时间
      uint evil; // 记录人头数
    }
    
    struct PunkInfo {      
      uint oldNeighbor;
      uint newNeighbor;
      int x;
      int y;
      bool isMoving;
      uint totalGold;
      uint hp;
      uint evil;
      uint seed;
      address player;
      string name;
    }

    struct GameInfo {
      uint evenPunk;
      uint oddPunk;
      uint pool;
      uint squidBalance;
      uint squidApproved;
      uint hepBalance;
      uint hepApproved;
      bool hasNFT;
      bool hasPunk;
    }

    uint public constant AC = 9; // 防御力
    uint public constant BAREHAND = 5; // 徒手攻击
    
    address public owner;
    address public cherryNFTAddress;
    address public hepAddress;
    address public squidAddress;
    uint public startBlock; // 记录初始区块数
    uint private _randNonce;
    uint public blockPerRound = 500;
    uint public rewardsPerRound = 5e15;
    bool public gameOver;
    uint public totalPunk; // 记录报名信息
    address[] public deadPunk; // 记录死亡信息

  
    // 储存玩家授权信息
    mapping (uint => address) public punkMaster;
    mapping (address => uint) public punkOf;
    mapping (address => string) public nickNameOf;
    mapping (address => bool) public isVIP;

    // 储存punk的时空信息
    mapping (uint => mapping (uint => Position)) public movingPunks;

    // 储存punk最后规划的信息
    mapping (uint => uint) public lastScheduleOf;

    // 储存随机种子，用于战斗
    mapping (uint => uint) private _randseedOfRound;
    mapping (uint => uint) private _randseedOfPunk;

    // 储存punk最后的位置信息
    mapping (uint => StillPunk) public stillPunks;

    // 储存punk最后的死亡信息
    mapping (address => KillEvent) public lastKilled;

    // 储存静止punk的空间信息
    mapping (int => mapping (int => uint)) public stillPunkOn;
  
    // 储存时空信息
    mapping (uint => mapping (int => mapping (int => MovingPunk))) public movingPunksOn;


    event ActionCommitted(uint indexed punkId, uint indexed time, ActionChoices action);
    event Attacked(uint indexed punkA, uint indexed punkB, uint damage);
    event Killed(uint indexed punkA, uint indexed punkB);
  
    constructor(address cherryNFTAddress_, address hepAddress_, address squidAddress_) {
        owner = msg.sender;
        cherryNFTAddress = cherryNFTAddress_;
        hepAddress = hepAddress_;
        squidAddress = squidAddress_;
        _randNonce = uint(keccak256(abi.encode(block.timestamp, msg.sender)));
        _randseedOfRound[0] = _randNonce;
    }

    // 增加下一回合信息
    function getEvents(int x1, int y1, int x2, int y2, uint t) public view returns (uint[] memory) {
        require(x2 >= x1 && y2 >= y1, "Invalid index");
        uint[] memory selectEvents = new uint[](uint((x2-x1+1)*(y2-y1+1)));
        uint i = 0;
        for (int x=x1; x<=x2; x++) {
          for (int y=y1; y<=y2; y++) {
            selectEvents[i] = getPunkOn(t, x, y);
            i ++;
          }
        }
        return selectEvents;
    }

    function getDeadPunk() public view returns (KillEvent[] memory) {
        KillEvent[] memory _deadPunks = new KillEvent[](deadPunk.length);
        for (uint i=0; i<deadPunk.length; i++) {
          _deadPunks[i] = lastKilled[deadPunk[i]];
        }
        return _deadPunks;
    }

    function _resetPunk(uint id) private {
      uint t = getCurrentTime();
      lastScheduleOf[id] = t;
      stillPunks[id].hp = 15; // 初始生命值为15
      stillPunks[id].nonce = t;
      stillPunks[id].evil = 0;

      int n = int(id%100) / 2 - 24; // punk将根据序号分为4组排布在外城边界上
      if (id % 4 == 0) {
        _addStillPunk(id, n, 25, t);
      }
      else if (id % 4 == 1) {
        _addStillPunk(id, -n, -25, t);
      }
      else if (id % 4 == 2) {
        _addStillPunk(id, 25, -n, t);
      }
      else if (id % 4 == 3) {
        _addStillPunk(id, -25, n, t);
      }
      
    }

    // 玩家设置昵称
    function setNickName(string memory name) public {
        nickNameOf[msg.sender] = name;
    }

    function setVIP(address[] calldata vips) public {
        require(msg.sender == owner, "Only admin can set VIPs.");
        uint length = vips.length;
        // batch set
        for (uint i=0; i<length; i++) {
            isVIP[vips[i]] = true;
        }
    }

    function freePunk() public view returns (uint, uint) {
        uint i;
        uint odd;
        uint even;
        for (i=2; i<=667; i=i+2) {
          if (punkMaster[i] == address(0)) {
            even = i;
            break;
          }
        }
        for (i=3; i<=667; i=i+2) {
          if (punkMaster[i] == address(0)) {
            odd = i;
            break;
          }
        }
        return (even, odd);
    }

    function gameInfo(address player) public view returns (GameInfo memory) {
        (uint even, uint odd) = freePunk();
        if (getCurrentTime() > 0) {
          even = 0;
          odd = deadPunk.length;
        }
        IERC20 squid = IERC20(squidAddress);
        uint pool = squid.balanceOf(address(this));
        uint squidBalance = squid.balanceOf(player);
        uint squidApproved = squid.allowance(player, address(this));
        IERC20 hep = IERC20(hepAddress);
        uint hepBalance = hep.balanceOf(player);
        uint hepApproved = hep.allowance(player, address(this));
        IERC721 cherryNFT = IERC721(cherryNFTAddress);
        uint nfts = cherryNFT.balanceOf(player);
        bool vip = isVIP[player];
        return GameInfo(even, odd, pool, squidBalance, squidApproved, hepBalance, hepApproved, nfts>0, vip);
    }
    
    // 玩家注册游戏
    function _register(uint id) private {
        require(!gameOver, 'game over');
        require(punkOf[msg.sender] == 0, "registered!");
        require(id <= 667, 'no position for now');
        punkMaster[id] = msg.sender;
        punkOf[msg.sender] = id;
        _randseedOfPunk[id] = uint(keccak256(abi.encode(block.timestamp, msg.sender, _randNonce)));
        _resetPunk(id);
        totalPunk ++;
    }

    function registerWithPunk() public {
        require(getCurrentTime() == 0, 'too late');
        require(isVIP[msg.sender], 'You do not have loser punk');
        (uint id, ) = freePunk();
        _register(id);
    }

    function registerWithNFT() public {
        require(getCurrentTime() == 0, 'too late');
        IERC721 cherryNFT = IERC721(cherryNFTAddress);
        require(cherryNFT.balanceOf(msg.sender) > 0, 'You do not have cherry NFT');
        ( , uint id) = freePunk();
        _register(id);
    }

    function registerWithSquid() public {
        IERC20 squid = IERC20(squidAddress);
        require(squid.transferFrom(msg.sender, address(this), 1e18), 'Failed to transfer the squid token');
        (uint even, uint odd) = freePunk();
        uint id = even < odd? even : odd;
        _register(id);
    }

    // 设置游戏开始与结束时间
    function startGame(uint startBlock_) public {
        require(msg.sender == owner, "Only admin can start the game.");
        startBlock = startBlock_;
    }


    // punkA击杀了punkB
    function _kill(uint A, uint B, uint t, int x, int y) private {
      // 阻止B后续的移动
      _removeStillPunk(B);
      // 失去连接
      lastKilled[punkMaster[B]] = KillEvent(A, B, t, x, y);
      deadPunk.push(punkMaster[B]);
      punkOf[punkMaster[B]] = 0;
      punkMaster[B] = address(0);
      // A获得了B的所有金币
      stillPunks[A].gold += (stillPunks[B].gold + pendingGold(B));
      stillPunks[B].gold = 0;
      stillPunks[A].enemy = 0;
      stillPunks[B].enemy = 0;
      // A变得更邪恶了
      stillPunks[A].evil ++;
      _reward(punkMaster[A], 2e17);
      
	    emit Killed(A, B);
    }
    
    // punkA向punkB进攻
    function _attack(uint A, uint B) private {
      // 命中检定1d20，徒手攻击1d5
      _randseedOfPunk[B] = uint(keccak256(abi.encode(A, _randseedOfPunk[B])));
      uint dice = _randseedOfPunk[B] % 100;
      // 骰点小于 10+被攻击者AC 时攻击命中
      if (dice/5+1 < 10+AC) {
        // 徒手攻击，伤害值1d5
        stillPunks[B].hp = (stillPunks[B].hp < (dice%5+1)? 0 : stillPunks[B].hp-(dice%5+1));
		    emit Attacked(A, B, dice%5+1);
      }
	    else {
		    emit Attacked(A, B, 0);
	    }
    }

    // punkA向punkB进攻
    function attack(uint A, uint B) public {
      require(punkOf[msg.sender] == A, "Get authorized first!");
      require(A > 0 && B > 0, "Punk not exit!");
      require(punkMaster[B] != address(0), "You attack a dead punk!");
      uint t = getCurrentTime();
      Position memory posA = getPostion(A, t);
      Position memory posB = getPostion(B, t);
	    require(stillPunks[B].showtime <= t, "punk B is moving");
      require(t > stillPunks[B].nonce, "punk B is just born!");
      //require(posA.x**2 < 625 && posA.y**2 < 625 && posB.x**2 < 625 && posB.y**2 < 625, "cannot attack punks outside the game area");
      require((posA.x-posB.x)**2 <=1  &&  (posA.y-posB.y)**2 <=1, "can only attack neighbors");

      if (stillPunks[A].enemy != B) {
        stillPunks[A].enemy = B;
      }

      _attack(A, B);
      if (stillPunks[B].hp == 0) {
        _kill(A, B, t, posB.x, posB.y);
      }
      else {
        // punkB自动反击
        _attack(B, A);
        if (stillPunks[A].hp == 0) {
          _kill(B, A, t, posA.x, posA.y);
        }
      }
    }

    // 只能在非战状态下时使用HEP
    function useHEP(uint id) public {
      IERC20 hep = IERC20(hepAddress);
      require(hep.transferFrom(msg.sender, address(this), 1), 'Failed to use hep');

      // 之后加入该机制
      //if (stillPunks[id].enemy != 0) {
      //  leaveBattle(id);
      //}

      stillPunks[id].hp += 10;
      if (stillPunks[id].hp > 15) {
        stillPunks[id].hp = 15;
      }
    }

    function _removeStillPunk(uint id) private {
        uint oldNeighbor = stillPunks[id].oldNeighbor;
        uint newNeighbor = stillPunks[id].newNeighbor;
        int x = stillPunks[id].x;
        int y = stillPunks[id].y;
        if (oldNeighbor > 0) {
          stillPunks[oldNeighbor].newNeighbor = newNeighbor;
        }
        else {
          stillPunkOn[x][y] = newNeighbor;
        }
        if (newNeighbor > 0) {
          stillPunks[newNeighbor].oldNeighbor = oldNeighbor;
        }
    }

    function _addStillPunk(uint id, int x, int y, uint t) private {
        require (getPunkOn(t, x, y) == 0 || x**2 == 625  ||  y**2 == 625, 'other punk already on it!');
        uint latestNeighbor = stillPunkOn[x][y];
        stillPunkOn[x][y] = id;
        stillPunks[id].oldNeighbor = 0;
        stillPunks[id].newNeighbor = latestNeighbor;
        stillPunks[id].x = x;
        stillPunks[id].y = y;
        stillPunks[id].showtime = t;
        if (latestNeighbor > 0) {
          stillPunks[latestNeighbor].oldNeighbor = id;
        }
    }

    function _addMovingPunk(uint id, uint t, int x, int y) private {
        movingPunksOn[t][x][y].punkId = id;
        movingPunksOn[t][x][y].punkNonce = stillPunks[id].nonce;
        movingPunks[id][t].x = x;
        movingPunks[id][t].y = y;
        // 自动进行挖矿操作
        uint gold = pendingGold(id);
        if (gold > 0) {
          stillPunks[id].gold += gold;
        }
    }



    // 操作punk
    function scheduleAction(uint id, ActionChoices action) public {
        require(punkOf[msg.sender] == id, "Get authorized first!");
        require(id > 0, "Punk not exit!");
        uint currentTime = getCurrentTime();
        if (lastScheduleOf[id] < currentTime) {
          lastScheduleOf[id] = currentTime;
        }
        uint t = lastScheduleOf[id];
        int x = stillPunks[id].x;
        int y = stillPunks[id].y;
        // remove this punk from still punks in (x, y) 
        _removeStillPunk(id);
        _addMovingPunk(id, t, x, y);
        if (action == ActionChoices.GoLeft) {
          _addStillPunk(id, x-1, y, t+1);
        }
        if (action == ActionChoices.GoRight) {
          _addStillPunk(id, x+1, y, t+1);
        }
        if (action == ActionChoices.GoUp) {
          _addStillPunk(id, x, y+1, t+1);
        }
        if (action == ActionChoices.GoDown) {
          _addStillPunk(id, x, y-1, t+1);
        }
        if (action == ActionChoices.GoLeftUp) {
          _addStillPunk(id, x-1, y+1, t+1);
        }
        if (action == ActionChoices.GoLeftDown) {
          _addStillPunk(id, x-1, y-1, t+1);
        }
        if (action == ActionChoices.GoRightUp) {
          _addStillPunk(id, x+1, y+1, t+1);
        }
        if (action == ActionChoices.GoRightDown) {
          _addStillPunk(id, x+1, y-1, t+1);
        }
        lastScheduleOf[id] ++;
        emit ActionCommitted(id, lastScheduleOf[id], action);
    }

    function getCurrentTime() public view returns (uint) {
      if (startBlock == 0 || startBlock > block.number) {
        return 0;
      }
      uint time = (block.number - startBlock) / blockPerRound + 1;
      return time;
    }

    function getPunkInfo(uint id) public view returns (PunkInfo memory) {
      uint t = getCurrentTime();
      Position memory pos = getPostion(id, t);
      address player = punkMaster[id];
      uint totalGold = stillPunks[id].gold + pendingGold(id);
      bool isMoving = (t == stillPunks[id].nonce) || (stillPunks[id].showtime > t);
      return PunkInfo(stillPunks[id].oldNeighbor, stillPunks[id].newNeighbor, pos.x, pos.y, isMoving, totalGold, stillPunks[id].hp, stillPunks[id].evil, _randseedOfPunk[id], player, nickNameOf[player]);
    }

    function getPunkOn(uint t, int x, int y) public view returns (uint) {
      if (stillPunkOn[x][y] != 0  && stillPunks[stillPunkOn[x][y]].showtime <= t) {
        return stillPunkOn[x][y];
      }
      else {
        uint id = movingPunksOn[t][x][y].punkId;
        if (movingPunksOn[t][x][y].punkNonce == stillPunks[id].nonce) {
          return id;
        }
      }
      return 0;
    }

    function getPostion(uint id, uint t) public view returns (Position memory) {
      if (lastScheduleOf[id] > t) {
        return Position(movingPunks[id][t].x, movingPunks[id][t].y);
      }
      else {
        return Position(stillPunks[id].x, stillPunks[id].y);
      }
    }

    function getCurrentStatus(uint id) public view returns (TimeSpace memory) {
      uint time = getCurrentTime();
      Position memory pos = getPostion(id, time);
      return TimeSpace(time, pos.x, pos.y);
    }

    function getScheduleInfo(uint id) public view returns (TimeSpace memory) {
      uint time = getCurrentTime();
      if (lastScheduleOf[id] > time) {
        time = lastScheduleOf[id];
      }
      return TimeSpace(time, stillPunks[id].x, stillPunks[id].y);
    }

    function getGoldsofAllPunk() public view returns (uint[667] memory) {
      uint[667] memory golds;
      for (uint i=0; i<667; i++) {
        golds[i] = stillPunks[i+1].gold + pendingGold(i+1);
      }
      return golds;
    }

    function getProductivity(int x, int y) public pure returns (uint) {
      if (x == 0 && y == 0) {
        return 100;
      }
      else if (x**2 <= 1  &&  y**2 <= 1) {
        return 25;
      }
      else if (x**2 <= 9  &&  y**2 <= 9) {
        return 10;
      }
      else if (x**2 <= 36  &&  y**2 <= 36) {
        return 5;
      }
      else if (x**2 <= 100  &&  y**2 <= 100) {
        return 3;
      }
      else if (x**2 <= 225  &&  y**2 <= 225) {
        return 2;
      }
      else if (x**2 <= 576  &&  y**2 <= 576) {
        return 1;
      }
      else {
        return 0;
      }
    }

    function pendingGold(uint id) public view returns (uint) {
      uint time = getCurrentTime();
      if (stillPunks[id].showtime < time) {
        uint productivity = getProductivity(stillPunks[id].x, stillPunks[id].y);
        return (time - stillPunks[id].showtime) * productivity * rewardsPerRound;
      }
      else {
        return 0;
      }
    }


    function _reward(address player, uint amount) private {
        require(!gameOver, 'game over');
        IERC20 squid = IERC20(squidAddress);
        uint balance = squid.balanceOf(address(this));
        if (balance <= amount) {
          squid.transfer(player, balance);
          gameOver = true;
        }
        else {
          squid.transfer(player, amount);
        }
    }

    // 领取奖励
    function claimRewards() public {
        uint id = punkOf[msg.sender];
        require(id > 0, "Punk not exit!");
        uint t = getCurrentTime();
        Position memory pos = getPostion(id, t);
        require(pos.x**2 == 625  ||  pos.y**2 == 625, 'go to border to claim your reward');
        _reward(msg.sender, stillPunks[id].gold);
        stillPunks[id].gold = 0;
        // 自杀
        _removeStillPunk(id);
        punkOf[punkMaster[id]] = 0;
        punkMaster[id] = address(0);
    }

}
