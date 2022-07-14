const assert = require('assert');
require("@nomiclabs/hardhat-waffle");

const { expect } = require('chai');
const { expectEvent, expectRevert } = require('@openzeppelin/test-helpers');
const { contract } = require('hardhat');
const BN = require('bignumber.js');
const NFT = artifacts.require('TrackTheMythPass');


contract('TrackTheMythPass', function (accounts) {
  const [owner, marketplace, royaltyWallet, receiver, receiver2] = accounts;
  const baseURI = 'https://api.trackthemyth.io/data/media/';
  const baseExtension = '.json';

  before(async function () {
    this.NFT = await NFT.new(100,baseURI ,baseExtension ,owner, royaltyWallet, { from: owner });
  });

  it('should be able to mint tokens', async function () {
    await this.NFT.mint(owner, { from: owner });
  })

  it('should be able to burn tokens', async function () {
    await this.NFT.burn(0, { from: owner });
  })

  describe('-> TEST : should not be able to mint tokens more than the cap', async function () {
    it('mint till cap is reached and then revert when trying to mint more', async function () {
      const _NFT = await NFT.new(1,baseURI ,baseExtension ,owner, royaltyWallet, { from: owner });
      await _NFT.mint(owner, { from: owner });
      await expectRevert(_NFT.mint(owner, { from: owner }), 'ERC721Capped: cap exceeded');
    })

    it('mint till cap is reached and then burn and then remint should work', async function () {
      const _NFT = await NFT.new(1,baseURI ,baseExtension ,owner, royaltyWallet, { from: owner });
      await _NFT.mint(owner, { from: owner });
      await expectRevert(_NFT.mint(owner, { from: owner }), 'ERC721Capped: cap exceeded');
      await _NFT.burn(0, { from: owner });
      await _NFT.mint(owner, { from: owner });
    })
  })

  describe('-> TEST : batch mint', async function () {
    let _NFT, cap = 256;
    it('only admin role will be able to mint in batch', async function () {
      _NFT = await NFT.new(cap, baseURI, baseExtension, owner, royaltyWallet, { from: owner });
      const { receipt } = await _NFT.batchMint(owner, cap, { from: owner });
      console.log(`\t--> gas required to mint ${cap} tokens: ${receipt.gasUsed}`)
      const gasLimit = new BN(receipt.gasUsed)
      const gasPrice = web3.utils.toWei('21', 'gwei');
      const txCost = gasLimit.multipliedBy(gasPrice)
      console.log("\t--> At 21 gwei gasPrice this will cost: ", web3.utils.fromWei(txCost.toString()), ' ethers');
    })

    it('the supply should meet cap', async function () {
      expect(await _NFT.totalSupply()).to.be.bignumber.equal(await _NFT.cap())
    })
    it('cannot mint more than cap', async function () {
      await expectRevert(_NFT.batchMint(owner, 2, { from: owner }), 'ERC721Capped: cap exceeded');
    })
  })
});