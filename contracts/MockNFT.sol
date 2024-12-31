// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MockNFT is ERC721, Ownable {
    uint256 public tokenCounter;

    constructor() ERC721("MockNFT", "MNFT") Ownable(msg.sender) {
        tokenCounter = 0;
    }

    function mint(address to) external {
        _safeMint(to, tokenCounter);
        tokenCounter++;
    }
}
