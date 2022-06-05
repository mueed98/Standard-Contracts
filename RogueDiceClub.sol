// // SPDX-License-Identifier: GPL-3.0
// pragma solidity 0.8.7;


// import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
// import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";


// contract RogueDiceClub is Initializable, ERC721Upgradeable, OwnableUpgradeable, UUPSUpgradeable {

//   event payment_Sent(bool payment_Sent);


//   using StringsUpgradeable for uint256;
//   using CountersUpgradeable for CountersUpgradeable.Counter;

//   CountersUpgradeable.Counter public nftCount;

//   string private baseURI;
//   string private baseExtension ;
//   string private notRevealedUri;

//   uint256 public maxSupply ;
//   uint256 public maxMintAmount ;
//   uint256 public maxNFTperWallet ;
//   uint256 public preMintPrice  ; // 0.15 eth
//   uint256 public mintPrice ; // 0.30 eth
//   uint256 public preSaleTime ; //unix time
//   uint256 public publicSaleTime ; //unix time

  
//   bool public flashSaleStatus;
//   uint256 public flashMintCost;
//   uint256 public flashSaleMaxMints;


//   bool public paused ;
//   bool public revealed ;

//   mapping(address => bool) public whitelistedAddresses;
//   mapping(address => uint256) public addressMintedBalance;

//   modifier onlyNotPaused {
//         require(paused == false, "Contract is paused");
//     _;
//   }

//    modifier onlyMintCompliance(uint256 _mintAmount, address _to) {
//     require(_mintAmount > 0, "need to mint at least 1 NFT");
//     require(_mintAmount <= maxMintAmount, "max mint amount per session exceeded");
//     require(nftCount.current() + _mintAmount <= maxSupply, "max NFT limit exceeded");
//     require(addressMintedBalance[_to] + _mintAmount <= maxNFTperWallet, "Max number of NFTs for this Wallet Exceded");
//     _;
//   }


//   function initialize(string memory _name, string memory _symbol, string memory _initBaseURI, string memory _initNotRevealedUri) initializer public {
//         __ERC721_init(_name, _symbol);
//         __Ownable_init();
//         __UUPSUpgradeable_init();


//         setBaseURI(_initBaseURI);
//         setNotRevealedURI(_initNotRevealedUri);

//         baseExtension = ".json";
//         maxSupply = 6000;
//         maxMintAmount = 5;
//         maxNFTperWallet = 15;
//         preMintPrice = 150000000000000000 ; // 0.15 eth
//         mintPrice = 300000000000000000 ; // 0.30 eth
//         preSaleTime = 1649871831; //unix time
//         publicSaleTime = 1649871831; //unix time
//         paused = false;
//         revealed = false;

//     }




//   function _baseURI() internal view virtual override returns (string memory) {
//     return baseURI;
//   }


// /**
//     * @dev to mint NFTs.
//     * @param _mintAmount, amount to mint.
//     * @param _to, address to mint. 
//      */
//   function mint(address _to, uint256 _mintAmount) public payable onlyNotPaused onlyMintCompliance(_mintAmount, _to) {

//     uint256 cost;

//     if(flashSaleStatus == true ){
//         flashSaleMaxMints -= _mintAmount;
//         require( flashSaleMaxMints >= 0, "Flash sale nft quota completed");
//         cost = flashMintCost;

//         if(flashSaleMaxMints == 0)
//             flashSaleStatus = false;
//     }
//     else if ( block.timestamp >= preSaleTime && block.timestamp < publicSaleTime){
//         require(whitelistedAddresses[msg.sender] == true, "PreSaleTime, You are not whitelisted");
//         cost = preMintPrice;
//     }
//     else if ( block.timestamp >= publicSaleTime){
//         cost = mintPrice;
//     }
//     else{
//         revert("Sale is not Active");
//     }

//     cost = cost * _mintAmount ;

//     require(msg.value >= cost , "Amount Sent less than Cost");

//     for (uint256 i = 0; i < _mintAmount; i++) {
//       safeMint(_to);
//     }

//   }

//   function giveAway(address _to, uint256 _mintAmount) public onlyNotPaused onlyOwner onlyMintCompliance(_mintAmount, _to){
//     for (uint256 i = 0; i < _mintAmount; i++) {
//       safeMint(_to);
//     }
//   }

  

//     function safeMint(address _to) internal virtual  {
//         addressMintedBalance[_to]++;
//         nftCount.increment();
//         _safeMint(_to, nftCount.current()); 
//     }
    
//     function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721Upgradeable)
//     onlyNotPaused {
//         super._beforeTokenTransfer(from, to, tokenId);
//     }


//   function tokenURI(uint256 tokenId) public view virtual override returns (string memory){
//     require( _exists(tokenId), "ERC721Metadata URI query for nonexistent token");

//     if(revealed == false) {
//         return notRevealedUri;
//     }

//     string memory currentBaseURI = _baseURI();
//     return string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension));
//   }

  
//   /*
//   Administrative Functions
//   */

//   function reveal() public onlyOwner {
//       revealed = true;
//   }


//   function setupFlashSale(bool _status, uint256 _flashMintCost, uint256 _flashSaleMaxMints) public onlyOwner {
//       flashSaleStatus = _status;
//       flashMintCost = _flashMintCost;
//       flashSaleMaxMints = _flashSaleMaxMints;

//   }

//   function setPreSaleTime(uint256 _time) public onlyOwner {
//     preSaleTime = _time;
//   }

//   function setPublicSaleTime(uint256 _time) public onlyOwner {
//     publicSaleTime = _time;
//   }

//   function setPreMintPrice(uint256 _price) public onlyOwner {
//     preMintPrice = _price;
//   }

//   function setPublicMintPrice(uint256 _price) public onlyOwner {
//     mintPrice = _price;
//   }

//   function setMaxNFTperWallet(uint256 _limit) public onlyOwner {
//     maxNFTperWallet = _limit;
//   }
  
//   function setMintPrice(uint256 _newmintPrice) public onlyOwner {
//     mintPrice = _newmintPrice;
//   }

//   function setMaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
//     maxMintAmount = _newmaxMintAmount;
//   }

//   function setBaseURI(string memory _newBaseURI) public onlyOwner {
//     baseURI = _newBaseURI;
//   }

//   function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
//     baseExtension = _newBaseExtension;
//   }
  
//   function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
//     notRevealedUri = _notRevealedURI;
//   }

//   function pause(bool _state) public onlyOwner {
//     paused = _state;
//   }
  
//   function whitelistUsers(address[] memory _users, bool _status) public onlyOwner {
//     for(uint256 i; i < _users.length ; i++ )
//         whitelistedAddresses[ _users[i] ] = _status;
//   }
 
//   function withdraw() public onlyOwner {
//         (bool sent,) = owner().call{value: address(this).balance }("");
//         require(sent == true, "Payment unsuccessful");
//         emit payment_Sent(sent);
//   }

//   /*
//   Administrative Functions end
//   */


//   /*
//   Proxy Functions
//   */

//   /**
//   * @dev Used by UUPS proxy.
//   */
//     function _authorizeUpgrade(address newImplementation) internal onlyOwner override {

//     }


//     function supportsInterface(bytes4 interfaceId)
//         public
//         view
//         override(ERC721Upgradeable)
//         returns (bool)
//     {
//         return super.supportsInterface(interfaceId);
//     }

//   /*
//   Proxy Functions end
//   */
// }