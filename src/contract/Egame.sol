// SPDX-License-Identifier: UNLICENSE

pragma solidity >=0.8.11 <0.9.0;

import "@thirdweb-dev/contracts/token/TokenERC20.sol"; // for my ERC20 token
import "@openzeppelin/contracts/security/ReentrancyGuard.sol"; // for security

contract Egame is ReentrancyGuard {

  TokenERC20 public immutable tokenContract; // store the token contract

  struct MapValue {
    uint256 score;
    uint256 token;
    bytes32 pointer;
  }

  // mapping player unique
  mapping(address => MapValue) public mappingPlayer;


  constructor(TokenERC20 addressTokenContract) {
    tokenContract = addressTokenContract;
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
    require(tokenContract.balanceOf(address(this)) > _amount, "Supply exceeded");

    // reset to 0
    mappingPlayer[msg.sender].token = 0;

    // transfering token
    tokenContract.transfer(msg.sender, _amount);

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

  function getPointer(address _player) private view returns (bytes32) {
    return mappingPlayer[_player].pointer;
  }

  // verify function set pointer when inputing score
  //
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
