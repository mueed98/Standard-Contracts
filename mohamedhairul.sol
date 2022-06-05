// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts@4.6.0/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts@4.6.0/security/Pausable.sol";
import "@openzeppelin/contracts@4.6.0/access/Ownable.sol";
import "@openzeppelin/contracts@4.6.0/utils/Counters.sol";
import "@openzeppelin/contracts@4.6.0/utils/Strings.sol";
import "@openzeppelin/contracts@4.6.0/utils/Address.sol";
      

contract TheFrontlinersApeClubEdition is ERC721, Pausable, Ownable {
        
    event payment_Sent(address reciever, uint256 amount);

    using Strings for uint256;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    string baseExtension;
    string baseURI;

    constructor() ERC721("The Frontliners (Ape Club Edition)", "TF(ACE)") {
        
        baseURI =  "https://bafybeibu3tns5k27kstzvonwftj2mc442pchsn375tgc74rmg2w3s2hlgm.ipfs.nftstorage.link/" ;
        baseExtension = ".json";
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(address to, uint256 amount) public onlyOwner {
        for (uint256 i; i< amount ; i++ ){
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(to, tokenId);
        } 

    }

    function tokenURI(uint256 _tokenId) public view override returns(string memory) {
        return string(abi.encodePacked(baseURI, _tokenId.toString(), baseExtension));
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }


    function setBaseExtension(string memory _baseExtension) public onlyOwner {
        baseExtension = _baseExtension;
    }

    function withdraw() public onlyOwner {
        Address.sendValue(payable(msg.sender), address(this).balance );
        emit payment_Sent(msg.sender, address(this).balance);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
