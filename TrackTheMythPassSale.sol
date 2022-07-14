// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./TrackTheMythPass.sol";
//import "hardhat/console.sol";

contract TrackTheMythPassSale is Ownable, Pausable, ReentrancyGuard {
    struct PHASE {
        uint8 index;
        uint8 maxAllowedMint;
        uint256 rate;
        uint256 startsAt;
        bytes32 merkleRoot;
    }

    TrackTheMythPass public token;
    mapping(uint8 => PHASE) public phases;
    mapping(address => mapping(uint256 => uint256)) public totalMinted;

    constructor(TrackTheMythPass _token, bytes32[] memory merkleRoots) {
        phases[0] = PHASE(0,1, 0 ether, block.timestamp, merkleRoots[0]);
        // phases[1] = PHASE(1,2,0.065 ether,phases[0].startsAt + 48 hours,merkleRoots[1]);
        // phases[2] = PHASE(2,5, 0.095 ether, phases[1].startsAt + 48 hours, 0);
        phases[1] = PHASE(1,2, 1 ether,phases[0].startsAt + 10 seconds, merkleRoots[1]);
        phases[2] = PHASE(2,5, 2 ether, phases[1].startsAt + 10 seconds, 0);
        token = _token;
    }

    function currentPhase() public view returns (uint8) {
        if (block.timestamp >= phases[2].startsAt) return 2;
        else if (block.timestamp >= phases[1].startsAt) return 1;
        else return 0;
    }

    function mint() public payable whenNotPaused {
        PHASE memory _currentPhase = phases[currentPhase()];
        if (_currentPhase.index == 2) 
            _mint(msg.sender, _currentPhase);
        else 
            revert("Only callable in 3rd phase");
    }

    function mint(bytes32[] memory proof) public payable whenNotPaused {
        
        PHASE memory _currentPhase = phases[currentPhase()];
        require(isWhitelisted(_currentPhase.index, proof), "Not whitelisted For this phase");
        _mint(msg.sender, _currentPhase);
    }

    //====================Administrative Functions====================//

    function withdraw() public onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setMerkleRoot(uint8 _phase, bytes32 _root) external onlyOwner {
        phases[_phase].merkleRoot = _root;
    }

    //====================Administrative Functions End====================//

    //====================Read Functions====================//

    function isWhitelisted(uint8 phase, bytes32[] memory proof) public view returns (bool){
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(proof, phases[phase].merkleRoot, leaf);
    }

    //====================Read Functions End====================//

    //====================Internal Functions====================//

    function _mint(address receiver, PHASE memory _currentPhase)public payable whenNotPaused{
        require(msg.value == _currentPhase.rate, "invalid value");

        require(totalMinted[receiver][_currentPhase.index] < _currentPhase.maxAllowedMint, 'Wallet mint quota of this phase reached');

        totalMinted[receiver][_currentPhase.index]++;

        // replace this with safe mint
        token.mint(receiver);
    }

    //====================Internal Functions End====================//
}
