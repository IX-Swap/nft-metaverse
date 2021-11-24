const sigUtil = require("eth-sig-util");
const ethUtils = require("ethereumjs-util");

const { expect } = require("chai");
const web3Abi = require("web3-eth-abi");
const { ethers } = require("ethers");
const Token = artifacts.require("IxsNft");
const chaiobjects = require("./setupchai.js");
const BN = chaiobjects.BN;
const { getNetworkDetails } = require('../constants.js');


contract("IxsNft Test", function(accounts) {
    const [initialHolder, recepient, operator, anotherAccount] = accounts;
    
    let networkDetails = getNetworkDetails;
    let name = networkDetails.name;
    let symbol = networkDetails.symbol;
    let baseTokenURI = networkDetails.baseTokenURI;
    let _max_token_number = networkDetails._max_token_number;
    const firstTokenId = new BN('2');
    const secondTokenId = new BN('18');
    const nonExistentTokenId = new BN('19');
    const fourthTokenId = new BN(7);
    const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";


    beforeEach(async() => {
        this.token = await Token.new(name, symbol, baseTokenURI, _max_token_number );
        await token.batchMint(initialHolder, 18);
      });


    const domainType = [
        {
          name: "name",
          type: "string",
        },
        {
          name: "version",
          type: "string",
        },
        {
          name: "verifyingContract",
          type: "address",
        },
        {
          name: "salt",
          type: "bytes32",
        },
      ];
      
      const metaTransactionType = [
        {
          name: "nonce",
          type: "uint256",
        },
        {
          name: "from",
          type: "address",
        },
        {
          name: "functionSignature",
          type: "bytes",
        },
      ];
      
      let safeTransferFromAbi = {
        inputs: [
          {
            internalType: "address",
            name: "from",
            type: "address",
          },
          {
            internalType: "address",
            name: "to",
            type: "address",
          },
          {
            internalType: "uint256",
            name: "tokenId",
            type: "uint256",
          },
        ],
        name: "safeTransferFrom",
        outputs: [],
        stateMutability: "nonpayable",
        type: "function",
      };
      
      let setApprovalForAllAbi = {
        inputs: [
          {
            internalType: "address",
            name: "operator",
            type: "address",
          },
          {
            internalType: "bool",
            name: "approved",
            type: "bool",
          },
        ],
        name: "setApprovalForAll",
        outputs: [],
        stateMutability: "nonpayable",
        type: "function",
      };


      const getTransactionData = async (user, nonce, abi, domainData, params) => {
        const functionSignature = web3Abi.encodeFunctionCall(abi, params);
      
        let message = {};
        message.nonce = parseInt(nonce);
        message.from =  user;
        message.functionSignature = functionSignature;
      
        const dataToSign = {
          types: {
            EIP712Domain: domainType,
            MetaTransaction: metaTransactionType,
          },
          domain: domainData,
          primaryType: "MetaTransaction",
          message: message,
        };
      
        const signature = sigUtil.signTypedData(ethUtils.toBuffer("0xce573c474493a4e1cb68f3b9245fc564ae70e83e21ce0fc00b9c7978938fdf0f"), {
          data: dataToSign,
        });
      
        let r = signature.slice(0, 66);
        let s = "0x".concat(signature.slice(66, 130));
        let v = "0x".concat(signature.slice(130, 132));
        v = parseInt(v);
        if (![27, 28].includes(v)) v += 27;
      
        return {
          r,
          s,
          v,
          functionSignature,
        };
      };


    it("setApprovalForAll MetaTransaction Test", async function () {
    
        let name = await token.name();
        let nonce = await token.getNonce(initialHolder);
        let version = "1";
        let chainId = (await token.getChainId()).toString();
        chainId = await ethers.BigNumber.from(await chainId).toHexString()
        let domainData = {
          name: name,
          version: version,
          verifyingContract: token.address,
          salt: '0x' + chainId.substring(2).padStart(64, '0'),
        };
    
        let { r, s, v, functionSignature } = await getTransactionData(
          initialHolder,
          nonce,
          setApprovalForAllAbi,
          domainData,
          [anotherAccount, true]
        );
        
        expect(
          await token.isApprovedForAll(initialHolder, anotherAccount)
        ).to.equal(false);
    
        const metaTransaction = await token.executeMetaTransaction(
          initialHolder,
          functionSignature,
          r,
          s,
          v,
          {from: anotherAccount}
        );

        await expect(token.executeMetaTransaction(
          initialHolder,
          functionSignature,
          r,
          s,
          v,
          {from: anotherAccount}
        )).to.be.rejected;

        await expect(token.executeMetaTransaction(
          recepient,
          functionSignature,
          r,
          s,
          v,
          {from: anotherAccount}
        )).to.be.rejected;

        expect(
          await token.isApprovedForAll(initialHolder, anotherAccount)
        ).to.equal(true);
      });


    it("balanceOf, ownerOf", async function (){
        expect(await token.balanceOf(initialHolder)).to.be.bignumber.equal('18');
        expect(await token.balanceOf(anotherAccount)).to.be.bignumber.equal('0');
        await expect(token.balanceOf(ZERO_ADDRESS)).to.eventually.be.rejectedWith('ERC721: balance query for the zero address');
        expect(await token.ownerOf(firstTokenId)).to.be.equal(initialHolder);
        await expect(token.ownerOf(nonExistentTokenId)).to.eventually.be.rejectedWith('ERC721: owner query for nonexistent token');
      });

    it("transfers", async function (){
        await token.approve(recepient, firstTokenId, { from: initialHolder });
        await token.setApprovalForAll(operator, true, { from: initialHolder });

        await token.transferFrom(initialHolder, anotherAccount, firstTokenId, { from: recepient })
        expect(await token.balanceOf(anotherAccount)).to.be.bignumber.equal('1');
        expect(await token.ownerOf(firstTokenId)).to.be.equal(anotherAccount);

      })

    it("Minter and only minter can mint tokens", async() => {
        const mintTokens = 1;
        let totalSupply = await token.totalSupply();
        await expect(token.balanceOf(initialHolder)).to.eventually.be.a.bignumber.equal(totalSupply);
        await expect(token.mint(anotherAccount, { from: anotherAccount })).to.eventually.be.rejectedWith("IXSNFT: must have minter role to mint");
        await expect(token.batchMint(anotherAccount, mintTokens, { from: anotherAccount })).to.eventually.be.rejectedWith("IXSNFT: must have minter role to mint");
        await expect(token.batchMint(anotherAccount, 2, { from: anotherAccount })).to.eventually.be.rejectedWith("IXSNFT: must have minter role to mint");
        await expect(token.batchMint(anotherAccount, 500, { from: anotherAccount })).to.eventually.be.rejectedWith("IXSNFT: must have minter role to mint");
      });


    it("no mint above limit", async function (){
        await expect(token.batchMint(initialHolder, 1)).to.be.rejectedWith("IXSNFT: Max mint limit");
        await expect(token.batchMint(initialHolder, 100)).to.be.rejectedWith("IXSNFT: Max mint limit");
        await expect(token.mint(initialHolder)).to.be.rejectedWith("IXSNFT: Max mint limit");
      })
      
    it('name, symbol, decimals, totalSupply, tokenURI', async () => {
        expect(name).to.eq('IX Swap NFT Launch Collection');
        expect(await token.symbol()).to.eq('IXS-NFT');
        expect((await token.totalSupply()).toString()).to.be.equal('18');
        expect((await token.balanceOf(initialHolder)).toString()).to.be.equal('18');
        expect(await this.token.tokenURI(15)).to.be.equal('https://nft.app.ixswap.io/metadata/15.json')
    })

    it('Contract creator has Minter and Pauser role, can grant others Pauser roles, can pause and unpause (no one else can call these methods). Pause stops all transfers, burns', async () => {
      expect(await token.hasRole(web3.utils.sha3('PAUSER_ROLE'), initialHolder)).to.true;
      expect(await token.hasRole(web3.utils.sha3('PAUSER_ROLE'), anotherAccount)).to.false;
      await expect(token.grantRole(web3.utils.sha3('PAUSER_ROLE'), anotherAccount, { from: anotherAccount })).to.eventually.be.rejected;
      await token.grantRole(web3.utils.sha3('PAUSER_ROLE'), anotherAccount, { from: initialHolder });
      expect(await token.hasRole(web3.utils.sha3('PAUSER_ROLE'), anotherAccount)).to.true;
      expect(await token.paused()).to.false;
      await expect(token.pause({ from: recepient })).to.eventually.be.rejectedWith("IXSNFT: must have pauser role to pause");
      await token.pause({ from: initialHolder });
      expect(await token.paused()).to.true;
      await expect(token.transferFrom(initialHolder, recepient, secondTokenId)).to.eventually.be.rejectedWith("ERC721Pausable: token transfer while paused");
      await expect(token.burn(1)).to.eventually.be.rejectedWith("ERC721Pausable: token transfer while paused");
      await expect(token.unpause({ from: recepient })).to.eventually.be.rejectedWith("IXSNFT: must have pauser role to unpause");
      await token.unpause({ from: initialHolder });
      expect(await token.paused()).to.false;

      expect(await token.hasRole(web3.utils.sha3('MINTER_ROLE'), initialHolder)).to.true;
      expect(await token.hasRole(web3.utils.sha3('MINTER_ROLE'), anotherAccount)).to.false;
      await expect(token.grantRole(web3.utils.sha3('MINTER_ROLE'), anotherAccount, { from: anotherAccount })).to.eventually.be.rejected;
      await token.grantRole(web3.utils.sha3('MINTER_ROLE'), anotherAccount, { from: initialHolder });
      expect(await token.hasRole(web3.utils.sha3('MINTER_ROLE'), anotherAccount)).to.true;

    })

    it("It's not possible to send more tokens than Account 1 has", async() => {
        expect(await token.ownerOf(firstTokenId)).to.be.equal(initialHolder);
        await token.transferFrom(initialHolder, anotherAccount, firstTokenId, { from: initialHolder });
        expect(await token.ownerOf(firstTokenId)).to.be.equal(anotherAccount);
        await expect(token.transferFrom(initialHolder, anotherAccount, firstTokenId, { from: initialHolder })).to.be.rejectedWith("ERC721: transfer caller is not owner nor approved");
        await expect(token.safeTransferFrom(initialHolder, anotherAccount, firstTokenId, { from: initialHolder })).to.be.rejectedWith("ERC721: transfer caller is not owner nor approved");

      });

    it("I can burn tokens", async() => {
        await expect(token.balanceOf(initialHolder)).to.eventually.be.a.bignumber.equal('18');
        await expect(token.burn(firstTokenId, {from: initialHolder})).to.eventually.be.fulfilled;
        await expect(token.burn(secondTokenId, {from: anotherAccount})).to.be.rejectedWith("ERC721Burnable: caller is not owner nor approved");
        await expect(token.burn(firstTokenId, {from: initialHolder})).to.eventually.be.rejected;
        await expect(token.balanceOf(initialHolder)).to.eventually.be.a.bignumber.equal('17');
        await expect(token.totalSupply()).to.eventually.be.a.bignumber.equal('17');
    });


});
