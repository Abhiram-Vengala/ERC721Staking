// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./MyNFT.sol";
import "./MyToken.sol";

contract NftStaking {

    MyNFT public nft;
    MyToken public token;
    address private immutable owner;

    uint256 totalStaked;//represents the total staked nft's

    uint256 unboundtime = 5 minutes;// The time till which the user cannot withdraw the nft's

    uint256 delayperiod = 2 minutes ;// The time till which the user cannot claim rewards .


    //creates a struct which contains the owner of an Staked NFT , that nft token Id and last Stale time .
    struct StakedNft{
        address owner;
        uint256 tokenId;
        uint256 lastStakeTime;
    }

    mapping (uint256=>StakedNft) public stakedNfts;//A mapping to the staked Nft's with their token Id .

    mapping (address=>mapping (uint256=>uint256)) unboundTimeOfUser;//stores the unbound time of every user and their each nft.

    mapping (address=>uint256) rewards;//stores the rewards of each user.

    mapping (address=>uint256) delayPeriodOfUser;//stores the delay period of each user.

    event NFTStaked(address _sender , address _receiver , uint256 tokenId);
    event NFTWithdraw(address _sender , address _receiver , uint256 tokenId); 
    event RewardsClaimed(address account , uint256 amount);  

    //constructor takes two arguments.
    //one is deployed MyNFT contract address and other one is deployed MyToken contract address.
    constructor(address _nft , address _token ){
        nft = MyNFT(_nft);
        token=MyToken(_token);
        owner =  msg.sender;
    }

    modifier onlyOwner(){
        require(msg.sender==owner,"Only owner can access this function");
        _;
    }

    //First the user should have nft's to stake for that , Mint Nft's from MyNFT usinf safemint function .
    //secondly , The user need's to approve the NftSTaking contract to receive nft for staking .
    //For that  , user can approve individual token by approve function in MyNFT by passing deployed NftStaling address.
    //or the user can approve all nft by setApprovalForAll functions in MyNFT by passing deployed NftStaking address and true.
    //can pass the arguments for single nft or multiple token Ids to stake .
    function stake(uint256[] calldata _tokenIds  ) external {
        totalStaked = totalStaked+_tokenIds.length;
        for(uint i;i<_tokenIds.length;i++){
            uint256 tokenId = _tokenIds[i];
            require(nft.ownerOf(tokenId)==msg.sender,"You are not the owner");
            require(stakedNfts[tokenId].tokenId==0,"Token already staked");

            //transfers mft from user to this contract
            nft.transferFrom(msg.sender, address(this), tokenId);

            // emits the staked event .
            emit NFTStaked(msg.sender, address(this), tokenId);

            stakedNfts[tokenId] = StakedNft({
                owner:msg.sender,
                tokenId:uint256(tokenId),
                lastStakeTime:block.timestamp
            });
            //sets the delay period to current time and further adds the deplay time.
            delayPeriodOfUser[msg.sender]=block.timestamp; 
        }

    }

    //user can unstake the single or multiple nfts by passinf token Ids .
    //By unstaking the contract still has the nfts , user get nfts only after withdraw.
    function unStake(uint256[] calldata _tokenIds) external {
        totalStaked-=_tokenIds.length;
        for(uint i;i<_tokenIds.length;i++){
            uint256 tokenId = _tokenIds[i];
            StakedNft memory stakedNft = stakedNfts[tokenId];
            require(stakedNft.owner==msg.sender,"You are not the owner of this NFT");

            delete stakedNfts[tokenId];

            //sets the unbound time for every nft that each user own . 
            unboundTimeOfUser[msg.sender][tokenId]=calculcatUnBoundTime();
        }
    }

    //calculates the unbound time .
    function calculcatUnBoundTime()internal view returns(uint256 time){
        return  block.timestamp+unboundtime;
    }

    //the user can claim their rewards , which are erc20 tokens.By passing their Nft token Ids.
    //The user can claim rewards after the delay period .
    //After the rewards are claimed it resets the delay period.
    function claim(uint256[] calldata _tokenIds) external{
        require(delayPeriodOfUser[msg.sender]+delayperiod<=block.timestamp,"Delay period not passed");
        delayPeriodOfUser[msg.sender]=block.timestamp;
        uint256 rewardAmount = RewardAmount(_tokenIds , msg.sender);
        token.mint(msg.sender, rewardAmount);
        emit RewardsClaimed(msg.sender, rewardAmount);
    }

    //calculates the reward Amount for each user .
    function RewardAmount(uint256[] calldata _tokenIds , address _account)internal returns(uint256){
        uint256 reward=0;
        for(uint i;i<_tokenIds.length;i++){
            
            uint256 tokenId = _tokenIds[i];
            StakedNft memory staked = stakedNfts[tokenId];
            require(staked.owner==_account,"You are not the owner");

            reward +=100000 ether *(block.timestamp-staked.lastStakeTime)/1 days;

            stakedNfts[tokenId] = StakedNft({
                owner:msg.sender,
                tokenId:tokenId,
                lastStakeTime:block.timestamp
            });
        }
        return reward;
    }
    //Let's user withdraw their Nft by passing ther nft token Ids , only after unbound time is passed.
    function withdrawNFTs(uint256[] calldata _tokenIds) external{
        for(uint i;i<_tokenIds.length;i++){
            uint256 tokenId = _tokenIds[i];
            require(stakedNfts[tokenId].owner==address(0x0),"You can withdraw Nft until you unstake the NFT");
            require(unboundTimeOfUser[msg.sender][tokenId]<=block.timestamp,"unbound period not passed ");
            emit NFTWithdraw(address(this), msg.sender,tokenId);
            nft.transferFrom(address(this), msg.sender, tokenId);
            delete unboundTimeOfUser[msg.sender][tokenId];
        }
    }

    //sets the unbound time .
    function setUnboundTime(uint256 _time ) external onlyOwner{
        unboundtime = _time * 1 minutes;
    }
    //sets the delay time .
    function setDelayPeriod(uint256 _time) external onlyOwner{
        delayperiod = _time * 1 minutes;
    }

    //gets the unbound time, In minutes.
    function getUnboundTime() external view returns(uint256){
        return unboundtime;
    }

    //get the delaytime , In minutes.
    function getDelayPeriod() external view returns(uint256){
        return delayperiod;
    }
    //Lets this contract receive the nft's .
    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
      require(from == address(0x0), "Cannot send nfts to this contract directly");
      return IERC721Receiver.onERC721Received.selector;
    }

}