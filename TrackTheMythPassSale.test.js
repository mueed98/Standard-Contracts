const { MerkleTree } = require("merkletreejs");
const { expectRevert } = require("@openzeppelin/test-helpers");
const ether = require("@openzeppelin/test-helpers/src/ether");
const { ethers } = require("hardhat");

const tokenContract = artifacts.require("TrackTheMythPass");
const saleContract = artifacts.require("TrackTheMythPassSale");

const keccak256 = web3.utils.keccak256;

async function delay(seconds) {
	const ms = seconds * 1000;
	return new Promise((resolve) => setTimeout(resolve, ms));
}

contract("TTM Sale Test Setup", async function (accounts) {
	const [
		owner,
		royaltyWallet,
		buyer,
		payee0,
		payee1,
		payee2,
		payee3,
		payee4,
		payee5,
		payee6,
	] = accounts;
	const baseURI = "https://api.trackthemyth.io/data/media/";
	const baseExtension = ".json";
	const cap = 20;

	// Setting up Phase 0
	const whitelistedUsers_phase0 = [owner, royaltyWallet, payee0];
	const leafNodes_phase0 = whitelistedUsers_phase0.map((addr) =>
		keccak256(addr)
	);
	const merkleTree_phase0 = new MerkleTree(leafNodes_phase0, keccak256, {
		sortPairs: true,
	});
	const merkleRoot_phase0 = "0x" + merkleTree_phase0.getRoot().toString("hex");

	// Setting up Phase 1
	const whitelistedUsers_phase1 = [owner, royaltyWallet, payee1];
	const leafNodes_phase1 = whitelistedUsers_phase1.map((addr) =>
		keccak256(addr)
	);
	const merkleTree_phase1 = new MerkleTree(leafNodes_phase1, keccak256, {
		sortPairs: true,
	});
	const merkleRoot_phase1 = "0x" + merkleTree_phase1.getRoot().toString("hex");

	let deploymentTime;

	before(async function () {
		console.log("--> merkleRoot_phase0 ", merkleRoot_phase0);
		console.log("--> merkleRoot_phase1 ", merkleRoot_phase1);

		// Deploying Contracts
		this.tokenContract = await tokenContract.new(
			cap,
			baseURI,
			baseExtension,
			owner,
			royaltyWallet,
			{ from: owner }
		);
		this.saleContract = await saleContract.new(this.tokenContract.address, [
			merkleRoot_phase0,
			merkleRoot_phase1,
		]);

		deploymentTime = Math.round(Date.now() / 1000);
		console.log("--> deploymentTime : ", deploymentTime);
		console.log("--> this.saleContract.address ", this.saleContract.address);
		console.log('--> owner : ', owner)
		console.log('--> payee0 : ', payee0)	
		console.log('--> payee1 : ', payee1)	
		
		//await this.tokenContract.setApprovalForAll(this.saleContract.address, true);
	});

	it('Granting Minter role to SaleContract', async function () {
	  await this.tokenContract.grantRole(await this.tokenContract.MINTER_ROLE() ,this.saleContract.address, { from: owner });
	  expect(await this.tokenContract.hasRole(await this.tokenContract.MINTER_ROLE(), this.saleContract.address )).to.equal(true);
	});

	it('payee0 is whitelisted in phase 0 and payee1 is whitelisted in phase 1', async function () {
	  expect(await this.saleContract.isWhitelisted(0,merkleTree_phase0.getHexProof(keccak256(payee0)), { from: payee0 })).to.equal(true);
	  expect(await this.saleContract.isWhitelisted(1,merkleTree_phase1.getHexProof(keccak256(payee1)), { from: payee1 })).to.equal(true);
	});

	it('payee0 is not-whitelisted in phase 1 and payee1 is not-whitelisted in phase 0', async function () {
	  expect(await this.saleContract.isWhitelisted(0,merkleTree_phase0.getHexProof(keccak256(payee1)), { from: payee1 })).to.equal(false);
	  expect(await this.saleContract.isWhitelisted(1,merkleTree_phase1.getHexProof(keccak256(payee0)), { from: payee0 })).to.equal(false);
	});

	describe("-> TEST : Phase 0", async function () {
		it('Current Phase should be 0', async function () {
		  expect(await this.saleContract.currentPhase()).to.be.bignumber.equal('0');
		});

		it('Mint( ) not callable in phase 0', async function () {
		  expect(await this.saleContract.currentPhase()).to.be.bignumber.equal('0');
		  await expectRevert(this.saleContract.mint(), 'Only callable in 3rd phase');
		});

		it('Should revert when payee1 tries to mint in phase 0', async function () {
		  expect(await this.saleContract.currentPhase()).to.be.bignumber.equal('0');
		  await expectRevert(this.saleContract.methods['mint(bytes32[])'](merkleTree_phase0.getHexProof(keccak256(payee1)), { value: 0, from: payee1 }), 'Not whitelisted For this phase');
		});

		it("Mint works when payee0 tries to mint with 0 eth", async function () {
			expect(await this.saleContract.currentPhase()).to.be.bignumber.equal("0");
			await this.saleContract.methods['mint(bytes32[])'](merkleTree_phase0.getHexProof(keccak256(payee0)), { value : 0 ,from: payee0 })
		});

		it("Should revert when payee0 tries to mint again", async function () {
			expect(await this.saleContract.currentPhase()).to.be.bignumber.equal("0");
			await expectRevert(this.saleContract.methods['mint(bytes32[])'](merkleTree_phase0.getHexProof(keccak256(payee0)), { value : 0 ,from: payee0 }), 'Wallet mint quota of this phase reached');
		});

	});

	describe("-> TEST : Phase 1", async function () {
		it('Current Phase should be 1', async function () {
			await ethers.provider.send("evm_mine", [deploymentTime + 10]);
		  	expect(await this.saleContract.currentPhase()).to.be.bignumber.equal('1');
		});

		it('Mint( ) not callable in phase 1', async function () {
		  expect(await this.saleContract.currentPhase()).to.be.bignumber.equal('1');
		  await expectRevert(this.saleContract.mint(), 'Only callable in 3rd phase');
		});

		it('Should revert when payee0 tries to mint in phase 1', async function () {
		  expect(await this.saleContract.currentPhase()).to.be.bignumber.equal('1');
		  await expectRevert(this.saleContract.methods['mint(bytes32[])'](merkleTree_phase1.getHexProof(keccak256(payee0)), { value: 0, from: payee0 }), 'Not whitelisted For this phase');
		});

		it("Should revert when payee1 tries to mint with 0 eth", async function () {
			expect(await this.saleContract.currentPhase()).to.be.bignumber.equal("1");
			await expectRevert(this.saleContract.methods['mint(bytes32[])'](merkleTree_phase1.getHexProof(keccak256(payee1)), { value : 0 ,from: payee1 }) , 'invalid value');
		});

		it("Works when payee1 tries to mint with 1 eth", async function () {
			expect(await this.saleContract.currentPhase()).to.be.bignumber.equal("1");
			const value_1_eth = ethers.utils.parseEther('1').toString();
			await this.saleContract.methods['mint(bytes32[])'](merkleTree_phase1.getHexProof(keccak256(payee1)), { value : value_1_eth ,from: payee1 });
		});

		it("Works when payee1 tries to mint one more times", async function () {
			expect(await this.saleContract.currentPhase()).to.be.bignumber.equal("1");
			const value_1_eth = ethers.utils.parseEther('1').toString();
			await this.saleContract.methods['mint(bytes32[])'](merkleTree_phase1.getHexProof(keccak256(payee1)), { value : value_1_eth ,from: payee1 });
		});

		it("Should revert when payee1 tries to mint 3rd time", async function () {
			expect(await this.saleContract.currentPhase()).to.be.bignumber.equal("1");
			const value_1_eth = ethers.utils.parseEther('1').toString();
			await expectRevert(this.saleContract.methods['mint(bytes32[])'](merkleTree_phase1.getHexProof(keccak256(payee1)), { value : value_1_eth ,from: payee1 }), 'Wallet mint quota of this phase reached');
		});


	});

	describe("-> TEST : Phase 2", async function () {
		it('Current Phase should be 2', async function () {
			await ethers.provider.send("evm_mine", [deploymentTime + 20]);
		  	expect(await this.saleContract.currentPhase()).to.be.bignumber.equal('2');
		});

		it('MerkleProof Mint function should revert in phase 2', async function () {
		  await expectRevert(this.saleContract.methods['mint(bytes32[])'](merkleTree_phase1.getHexProof(keccak256(payee0)), { value: 0, from: payee0 }), 'Not whitelisted For this phase');
		});

		it("Should revert when any payee tries to mint with less than 2 eth", async function () {
			const ethValue = ethers.utils.parseEther('1.5').toString();
			await expectRevert(this.saleContract.mint({ value : ethValue ,from: payee0 }) , 'invalid value');
			await expectRevert(this.saleContract.mint({ value : ethValue ,from: payee1 }) , 'invalid value');

		});

		it("Works when any payee tries to mint 5 times", async function () {
			const ethValue = ethers.utils.parseEther('2').toString();
			for(let i = 0 ; i < 5 ; i++){
				await this.saleContract.mint({ value : ethValue ,from: payee0 });
				await this.saleContract.mint({ value : ethValue ,from: payee1 });
			}
		});

		it("Reverts when any payee tries to mint 6th time", async function () {
			const ethValue = ethers.utils.parseEther('2').toString();
			await expectRevert(this.saleContract.mint({ value : ethValue ,from: payee1 }), 'Wallet mint quota of this phase reached');
			await expectRevert(this.saleContract.mint({ value : ethValue ,from: payee0 }), 'Wallet mint quota of this phase reached');
		});
	});

	describe("-> TEST : totalSupply and Token Ownership", async function () {
		it("Total Supply should be 13", async function () {
			await expect(await this.tokenContract.totalSupply()).to.be.bignumber.equal('13');
		});

		it("payee0 owns 6 NFTs", async function () {
			await expect(await this.tokenContract.ownerOf(0)).to.equal(payee0);
			await expect(await this.tokenContract.ownerOf(3)).to.equal(payee0);
			await expect(await this.tokenContract.ownerOf(5)).to.equal(payee0);
			await expect(await this.tokenContract.ownerOf(7)).to.equal(payee0);
			await expect(await this.tokenContract.ownerOf(9)).to.equal(payee0);
			await expect(await this.tokenContract.ownerOf(11)).to.equal(payee0);
		});

		it("payee1 owns 7 NFTs", async function () {
			await expect(await this.tokenContract.ownerOf(1)).to.equal(payee1);
			await expect(await this.tokenContract.ownerOf(2)).to.equal(payee1);
			await expect(await this.tokenContract.ownerOf(4)).to.equal(payee1);
			await expect(await this.tokenContract.ownerOf(6)).to.equal(payee1);
			await expect(await this.tokenContract.ownerOf(8)).to.equal(payee1);
			await expect(await this.tokenContract.ownerOf(10)).to.equal(payee1);
			await expect(await this.tokenContract.ownerOf(12)).to.equal(payee1);
		});
	});

	describe("-> TEST : minting to max cap", async function () {

		it("Payee can mint 7 more NFTs", async function () {
			const ethValue = ethers.utils.parseEther('2').toString();
			for(let i = 0 ; i < 5 ; i++){
				await this.saleContract.mint({ value : ethValue ,from: payee3 });
			}
			for(let i = 0 ; i < 2 ; i++){
				await this.saleContract.mint({ value : ethValue ,from: payee4 });
			}
		});

		it("Reverts when cap is reached", async function () {
			const ethValue = ethers.utils.parseEther('2').toString();
			await expectRevert(this.saleContract.mint({ value : ethValue ,from: payee4 }), 'ERC721Capped: cap exceeded');
		});
	});

});
