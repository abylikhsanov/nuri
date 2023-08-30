// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract NuriToken is ERC20 {

    address immutable public _owner;
    mapping(address => bool) _allowedToMint;

    constructor() ERC20("NuriToken", "NuriT") {
        _owner = msg.sender;
    }

    function setAllowedToMint(address account) external {
        require(msg.sender == _owner, "Only owner can set the allowed to mint addresses");
        _allowedToMint[account] = true;
    }

    function mint(address to, uint tokens) external {
        require(_allowedToMint[msg.sender] == true, "You are not allowed to mint, ask the owner of the contract");
        uint amount = tokens * 10 ** decimals();
        _mint(to, amount);
    }

    function mintAmount(address to, uint amount) public {
        require(_allowedToMint[msg.sender] == true, "You are not allowed to mint, ask the owner of the contract");
        _mint(to, amount);
    }

    function approve(address spender, uint256 tokens) public override returns (bool) {
        uint amount = tokens * 10 ** decimals();
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }
}