// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";


contract MyNFT is  ERC721Enumerable {
    uint256 public tokenId;//represents the total nft supply and last minted token id .
    string public baseURI;//contains the link to the json format data of nft
    uint256 public maxSupply = 10000;//the total nft's that can be minted.
    uint256 public minMintAmount = 5;//the nft's that can be minted by user at max.
    bool public paused = false;
    address private immutable owner;

    
    constructor()ERC721("MyNFT", "mnft"){
        owner=msg.sender;
    }

    modifier onlyOwner(){
        require(msg.sender==owner,"Only owner can access this function");
        _;
    }

    function _baseURI()internal virtual view override returns (string memory){
        return "";
    }

    /** This function mints the nft's
    @param _to - receiver address 
    @param _amount - total no.of nft that need to be minted
    */
    function safeMint(address _to , uint256 _amount) public{
        require(!paused);
        require(_amount>0,"Mint amount should be greater than zero");
        require(_amount<=minMintAmount,"Mint amount should be less than or equal to 5");
        require(tokenId+_amount<=maxSupply, "Total mint amount reached to it's max ");
        uint256 _tokenId = tokenId;
        for(uint i;i<_amount ;i++){
            _safeMint(_to, _tokenId+i);
        }
        tokenId=totalSupply();
    }

    //This functions returns the array of token Ids owned by the user.
    function tokenOwnedByUser(address _owner) public view returns(uint256[] memory){
        uint256 ownersTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownersTokenCount);
        for(uint256 i ; i<ownersTokenCount;i++){
            tokenIds[i]=tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    //Let's the owner the set new Max supply
    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply=_maxSupply;
    }

    //Let's the owner the set new base uri
    function setBaseURI(string memory _baseuri) public onlyOwner {
        baseURI = _baseuri;
    }

    //let's the owner to pause the nft contract.
    function pause(bool _state) public onlyOwner{
        paused = _state;
    }
    
    function withdraw()public payable {
        require(payable (msg.sender).send(address(this).balance));
    }
}