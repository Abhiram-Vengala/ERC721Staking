# ERC721 Staking 

This project demonstrates NFT staking smart contract. It comes with contracts , tests for that contract, and a script that deploys that contract.
This project has following contracts 

--> Proxy.sol : It implements a Universal Upgradeable Proxy Standard , to upgrade the contracts .

--> MyNFT.sol : This contract is responsible for minting and approving the NFT's.

--> MyToken.sol : This contract mints the native tokens . Mainly used to mint rewards for NftStaking

--> NftStaking.sol : This contract stakes and unstakes the NFTs and lets user to earn reward according to their staked NFTs.

open a terminal
First Run the following task , to run a hardhat node.
```
npx hardhat node
```
open another terminal (second terminal)
Compile the contracts .
```
npx hardhat compile
```
Run the tests
```
npx hardhat test
```

deploy the smart contracts 
```
npx hardhat run scripts/deploy.js --network localhost
```

