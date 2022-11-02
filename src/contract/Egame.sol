// SPDX-License-Identifier: UNLICENSE

pragma solidity >=0.8.11 <0.9.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol"; // for security

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract ERC20 is IERC20 {

    string public constant NANME = "EGAME";
    string public constant SYMBOL = "EGM";
    uint8 public constant DECIMALS = 18;

    mapping(address => uint256) public balances;

    mapping(address => mapping (address => uint256)) public allowed;

    uint256 public totalSupply_ = 1000 ether;


    constructor() {
      balances[msg.sender] = totalSupply_;
    }

    function totalSupply() public override view returns (uint256) {
      return totalSupply_;
    }

    function balanceOf(address tokenOwner) public override view returns (uint256) {
      return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens) public override returns (bool) {
      require(numTokens <= balances[msg.sender], "Supply exceded");
      balances[msg.sender] = balances[msg.sender]-numTokens;
      balances[receiver] = balances[receiver]+numTokens;
      emit Transfer(msg.sender, receiver, numTokens);
      return true;
    }

    function approve(address delegate, uint256 numTokens) public override returns (bool) {
      allowed[msg.sender][delegate] = numTokens;
      emit Approval(msg.sender, delegate, numTokens);
      return true;
    }

    function allowance(address owner, address delegate) public override view returns (uint) {
      return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public override returns (bool) {
      require(numTokens <= balances[owner], "Supply exceded");
      require(numTokens <= allowed[owner][msg.sender], "allowance");

      balances[owner] = balances[owner]-numTokens;
      allowed[owner][msg.sender] = allowed[owner][msg.sender]-numTokens;
      balances[buyer] = balances[buyer]+numTokens;
      emit Transfer(owner, buyer, numTokens);
      return true;
    }
}





contract Egame is ERC20, ReentrancyGuard {

  IERC20 public token;

  event Bought(uint256 amount);
  event Sold(uint256 amount); // store the token contract

  struct MapValue {
    uint256 score;
    uint256 token;
    bytes32 pointer;
  }

  // mapping player unique
  mapping(address => MapValue) public mappingPlayer;


  constructor() {
    token = new ERC20();
  }


  function claimScore(uint256 _score) public nonReentrant  {
    require(_score > 0, "Must be > 0");

    // sum the score
    uint256 oldScore = mappingPlayer[msg.sender].score;
    uint256 newScore = oldScore + _score;

    // set the pointer if player has 0 score
    if ( oldScore == 0) {
      bytes32 _pointer = setPointer(msg.sender, 0);
      mappingPlayer[msg.sender].pointer = _pointer;
    }

    if ( (validating(msg.sender, oldScore)) == true) {
      // update pointer
      bytes32 newPointer = setPointer(msg.sender, newScore);
      mappingPlayer[msg.sender].pointer = newPointer;

      // update the score
      mappingPlayer[msg.sender].score = newScore;

      // direcly calculating the token taht can be claim
      calculateToken(msg.sender);
    }
  }

  function claimToken() external nonReentrant {
    uint256 _amount = getToken(msg.sender);
    uint256 dexBalance = token.balanceOf(address(this));
    require(token.balanceOf(address(this)) > _amount, "Supply exceeded");
    require(_amount <= dexBalance, "Not enough tokens in the reserve");


    // reset to 0
    mappingPlayer[msg.sender].token = 0;

    // transfering token
    token.transfer(msg.sender, _amount);
    emit Bought(_amount);

  }

  // ===== private function vor validating =====
  // calculate the token that player get direcly
  function calculateToken(address _player) private {
    uint256 _score = mappingPlayer[_player].score;
    uint256 _token = 0;

    // every 100 scores get buy 1 token
    if ( _score >= 1000) {
      while (_score >= 1000) {
        _token++;
        _score-=1000;
      }

      // update the token
      mappingPlayer[_player].token = _token;
    }

  }

  // verify function set pointer when inputing score
  //
  function getPointer(address _player) private view returns (bytes32) {
    return mappingPlayer[_player].pointer;
  }

  function setPointer(address _player, uint256 oldScore) private pure returns (bytes32) {
    bytes32 newPointer = keccak256(abi.encodePacked(_player, oldScore));
    return newPointer;
  }

  function validating(address _player, uint _oldScore) private view returns (bool) {
    bytes32 oldPointer = getPointer(_player);
    bytes32 newPointer = setPointer(_player, _oldScore);
    return (newPointer == oldPointer);
  }

  // for interface
  function getScore(address _player) public view returns (uint256) {
    return mappingPlayer[_player].score;
  }

  function getToken(address _player) public view returns (uint256) {
    return mappingPlayer[_player].token;
  }
  
}
