// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTMarketplace is Ownable {
    struct Listing {
        address seller;
        uint256 price;
        address paymentToken; // Address(0) for native token (ETHW), ERC20 address otherwise
        address creator;
        uint256 royaltyPercentage; // Royalty percentage (e.g., 5 for 5%)
    }

    mapping(address => mapping(uint256 => Listing)) public listings;

    event NFTListed(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address seller,
        uint256 price,
        address paymentToken
    );
    event NFTSold(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address buyer,
        uint256 price,
        address paymentToken
    );
    event NFTUnlisted(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address seller
    );
    event RoyaltyPaid(
        address indexed creator,
        uint256 amount,
        address paymentToken
    );

    constructor() Ownable(msg.sender) {}

    function listNFT(
        address nftAddress,
        uint256 tokenId,
        uint256 price,
        address paymentToken,
        address creator,
        uint256 royaltyPercentage
    ) external {
        require(price > 0, "Price must be greater than zero");
        require(royaltyPercentage <= 10, "Royalty percentage too high");

        IERC721 nft = IERC721(nftAddress);
        require(
            nft.ownerOf(tokenId) == msg.sender,
            "You are not the NFT owner"
        );
        require(
            nft.getApproved(tokenId) == address(this),
            "Marketplace not approved"
        );

        listings[nftAddress][tokenId] = Listing(
            msg.sender,
            price,
            paymentToken,
            creator,
            royaltyPercentage
        );

        emit NFTListed(nftAddress, tokenId, msg.sender, price, paymentToken);
    }

    function buyNFT(address nftAddress, uint256 tokenId) external payable {
        Listing memory listing = listings[nftAddress][tokenId];
        require(listing.price > 0, "NFT is not listed");

        uint256 royalty = (listing.price * listing.royaltyPercentage) / 100;
        uint256 sellerProceeds = listing.price - royalty;

        if (listing.paymentToken == address(0)) {
            require(msg.value >= listing.price, "Insufficient payment");

            if (royalty > 0) {
                payable(listing.creator).transfer(royalty);
                emit RoyaltyPaid(listing.creator, royalty, address(0));
            }

            payable(listing.seller).transfer(sellerProceeds);
        } else {
            IERC20 token = IERC20(listing.paymentToken);
            require(
                token.transferFrom(msg.sender, address(this), listing.price),
                "Payment failed"
            );

            if (royalty > 0) {
                require(
                    token.transfer(listing.creator, royalty),
                    "Royalty payment failed"
                );
                emit RoyaltyPaid(
                    listing.creator,
                    royalty,
                    listing.paymentToken
                );
            }
            require(
                token.transfer(listing.seller, sellerProceeds),
                "Seller payment failed"
            );
        }

        IERC721(nftAddress).safeTransferFrom(
            listing.seller,
            msg.sender,
            tokenId
        );

        delete listings[nftAddress][tokenId];
        emit NFTSold(
            nftAddress,
            tokenId,
            msg.sender,
            listing.price,
            listing.paymentToken
        );
    }

    function cancelListing(address nftAddress, uint256 tokenId) external {
        Listing memory listing = listings[nftAddress][tokenId];
        require(listing.seller == msg.sender, "You are not the seller");

        delete listings[nftAddress][tokenId];
        emit NFTUnlisted(nftAddress, tokenId, msg.sender);
    }
}
