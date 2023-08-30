// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

import "./NuriNFT.sol";
import "./NuriToken.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract Nuri is IERC721Receiver {

    /**
    * This contract interacts with NuriNFT (ERC721) and NuriToken (ERC20)
    */
    NuriNFT private _nftContract;
    NuriToken private _tokenContract;

    /**
    * When the account wants to mint the NuriNFT via this contract, we set the price in
    * NuriToken which will be set to 10 tokens but this price is in 18 decimals
    */
    uint public _priceOfNFT;

    /**
    * Account can stake NuriNFTs via this contract and every _stakedTime, account will receive
    * NuriTokens (which by default will be set 10 NuriTokens for every 24h of _stakedTime
    */
    uint public _timeForStake;

    /**
    * To keep track of who is the "real" owner of the NFT when the account decides to stake it
    * because when account decides to stake NuriNFT, it should "deposit" to this contract's address
    */
    mapping(uint => address) public _prevOwner;

    /**
    * Keeps track of when the account called stake function so this contract starts the counter
    * It also a timestamp when the account calls the stake withdraw function
    */
    mapping(uint => uint) public _lastStakedTime;

    /**
    * Timestamp difference between the two stake withdraw function calls. This would allow this contract
    * to decide on how many tokens can the staked account withdraw.
    */
    mapping(uint => uint) public _stakedTime;

    address immutable public _owner;


    constructor(NuriNFT nftContract, NuriToken tokenContract) {
        _nftContract = nftContract;
        _tokenContract = tokenContract;
        _priceOfNFT = 10 * 10 ** _tokenContract.decimals();
        _timeForStake = 24 * 60 * 60;
        _owner = msg.sender;
    }

    /**
    * For testing purposes, we can set the time for stake
    */
    function setTimeForStake(uint s) external {
        require(msg.sender == _owner, "Only owner can set the time for stake");
        require(s > 10, "Minimum 10 seconds is allowed");
        _timeForStake = s;
    }


    /**
    * If user wants to mint the NFT which is limited to maximum of 10 tokens, user has to supply 10 NuriTokens and NuriNFT contract
    * would take care of the rest by minting the correct token ID and checking the max supply. 
    * Note: we do not have to check that allowance is sufficient (as we as smart contract on behalf of the account 
    * transfering tokens to our account address) as it will be checked by ERC20 contract anyway
    */
    function mintNFT() external {
        require(_tokenContract.balanceOf(msg.sender) >= 10 * 10 ** _tokenContract.decimals(), "Not enough balance to mint");
        // To save some gas, modifier would check before calling functions below. 
        _tokenContract.transferFrom(msg.sender, address(this), 10 * 10 ** _tokenContract.decimals());

        // After we have succesfully transfered 10 tokens to our account, we can start minting NFT for the user
        // Note that NuriNFT would check the max supply and based on ERC721, nothing stops us as a smart contract to
        // mint the NuriNFT to the account that is not a smart contract.
        // No need to send any emits as it will be done by ERC721 contract
        _nftContract.mint(msg.sender);
    }

    /**
    * Account can stake NFT and return 10 tokens every 24 hours. Owner of the NFT tokenId will be transfered to this account
    * and the timestamp of the ownership transfer will be recorded (so that we could tell how many tokens can previous owner
    * of the staked NFT can withdraw)
    */
    function stake(address from, uint tokenId) external {
        require(from == msg.sender, "Cannot stake as addresses do not match");
        _nftContract.safeTransferFrom(from, address(this), tokenId);
        _prevOwner[tokenId] = from;
        _lastStakedTime[tokenId] = block.timestamp;

    }

    /**
    * Account that staked its NFT can always withdraw its NFT given it was staked. Note that this contract
    * would erase the _prevOwnership (by just setting to address(0)) so that this account can no longer
    * call withdrawStakedTokens
    */
    function withdrawNFT(address to, uint tokenId) external {
        require(to == msg.sender, "Cannot withdraw NFT by someone else");
        require(to == _prevOwner[tokenId], "This is not your NFT scammer, try next time");
        _nftContract.safeTransferFrom(address(this), to, tokenId);
        _prevOwner[tokenId] = address(0);
    }

    /**
    * Account can only withdraw staked tokens if sufficient time has passed and that account is the previous owner
    * of the NFT that was given for stake. 
    */
    function withdrawStakedTokens(address to, uint tokenId) external {
        require(to == _prevOwner[tokenId], "You are not the owner of this token ID");
        _stakedTime[tokenId] += (block.timestamp - _lastStakedTime[tokenId]);
        _lastStakedTime[tokenId] = block.timestamp;
        require(_stakedTime[tokenId] >= _timeForStake, "Cannot withdraw");

        // Calculate the amount of tokens that can be withdrawn (10 every 24 hours). So if
        // staked for 48 hours, this function would transfer or mint 20 tokens, if 47 then
        // only 10 tokens but we subtract 47 % 24 * 24 from 47
        uint tokensAllowed = 10 * (_stakedTime[tokenId] / _timeForStake);

        uint amountToTransfer = tokensAllowed * 10 ** _tokenContract.decimals();
        // Calculate the amount that can be withdrawn
        if (_tokenContract.balanceOf(address(this)) < amountToTransfer) {
            uint amountToMint = amountToTransfer - _tokenContract.balanceOf(address(this));
            _tokenContract.mintAmount(to, amountToMint);
            amountToTransfer -= amountToMint;
        }

        _tokenContract.transfer(to, amountToTransfer);
        
        // If account called withdraw stake after 47 hours, meaning that only 10 tokens will be transferred
        // this contract would keep track of the difference so 1 hour later the same account can withdraw another 10 tokens
        _stakedTime[tokenId] -= (tokensAllowed / 10) * _timeForStake;
    }

    /**
    * This contract should be able to deposit NFTs that were used to stake so we have to implement the following function
    */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }


}