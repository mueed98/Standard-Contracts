// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract ManuCampaSale is Ownable, Pausable, ReentrancyGuard {
    using MerkleProof for bytes32[];
    using Address for address payable;

    bytes32 public merkleRoot;
    uint256 public openingTime = block.timestamp + 40 minutes;
    uint256 public constant maxMint = 7;

    address public tokenWallet;
    IERC1155 public manuCampaNFT;
    address payable public paymentSplitter;

    mapping(address => uint256) public alreadyMinted;
    mapping(uint256 => uint256) public sold;

    uint256[] private rates;
    uint256[] private preSaleRates;

    constructor(
        address _owner,
        address _tokenWallet,
        IERC1155 _manuCampaNFT,
        address payable _paymentSplitter,
        uint256[] memory _preSaleRates,
        uint256[] memory _rates
    ) {
        manuCampaNFT = _manuCampaNFT;
        preSaleRates = _preSaleRates;
        rates = _rates;
        paymentSplitter = _paymentSplitter;
        tokenWallet = _tokenWallet;
        _transferOwnership(_owner);
    }

    function buy(
        uint256 NFTType,
        bytes32[] memory proof,
        bytes32 leaf
    ) external payable nonReentrant whenNotPaused {
        _preValidatePurchase(NFTType, proof, leaf);

        paymentSplitter.sendValue(msg.value);

        sold[NFTType] += 1;
        alreadyMinted[msg.sender] += 1;
        manuCampaNFT.safeTransferFrom(
            tokenWallet,
            msg.sender,
            NFTType,
            1,
            "0x0"
        );
    }

    function _preValidatePurchase(
        uint256 NFTType,
        bytes32[] memory proof,
        bytes32 leaf
    ) internal {
        if (applyMerkle()) {
            require(isWhitelisted(proof, leaf), "Not whitelisted For presale");
        }

        require(alreadyMinted[msg.sender] < maxMint, "Max buy limit reached");
        require(msg.value == getNFTPrice(NFTType), "Amount is not correct");

        if (
            !isPreSaleEnded() &&
            (NFTType == 0 || NFTType == 1) &&
            sold[NFTType] == 2
        ) {
            revert("You can buy this NFT after pre sale is over");
        }
    }

    //Administrative Functions//
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setMerkleRoot(bytes32 _root) public onlyOwner {
        merkleRoot = _root;
    }

    function setOpeningTime(uint256 timestamp) public onlyOwner {
        openingTime = timestamp;
    }

    //Administrative Functions End//

    //Read Functions//

    function getRates() external view returns (uint256[] memory) {
        return rates;
    }

    function getPreSaleRates() external view returns (uint256[] memory) {
        return preSaleRates;
    }

    function isWhitelisted(bytes32[] memory proof, bytes32 leaf)
        public
        returns (bool)
    {
        return true ;//block.number % 2 == 0 ? true : false;
    }

    function applyMerkle() public view returns (bool) {
        return isPreSaleEnded() ? false : true;
    }

    function isPreSaleEnded() public view returns (bool) {
        return block.timestamp > openingTime + 24 hours;
    }

    function getNFTPrice(uint256 NFTType) public view returns (uint256) {
        return isPreSaleEnded() ? rates[NFTType] : preSaleRates[NFTType];
    }
    //Read Functions End//
}
