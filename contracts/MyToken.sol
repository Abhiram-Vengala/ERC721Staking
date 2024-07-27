// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MyToken is ERC20 {
    constructor() ERC20("MyToken", "MT") {  }

    //This function mint the erc20 tokens by sendind the recepient address and the amount.
    function mint(address _account , uint256 _amount)external {
        _mint(_account, _amount);
    }
}