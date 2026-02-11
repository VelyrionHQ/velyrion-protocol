// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

contract VelyrionMarketplace {
    // Structs
    struct Listing {
        uint256 id;
        address seller;
        string dataHash;        // IPFS hash of the data
        string qualityProof;    // JSON quality proof
        uint256 price;          // Price in wei
        bool active;
        uint256 createdAt;
    }
    
    struct Purchase {
        uint256 listingId;
        address buyer;
        uint256 timestamp;
        bool delivered;
    }
    
    // State variables
    uint256 public listingCounter;
    uint256 public totalTransactions;
    
    mapping(uint256 => Listing) public listings;
    mapping(address => uint256[]) public sellerListings;
    mapping(address => Purchase[]) public buyerPurchases;
    mapping(uint256 => mapping(address => bool)) public hasPurchased;
    
    // Events
    event ListingCreated(
        uint256 indexed id,
        address indexed seller,
        uint256 price,
        string dataHash
    );
    
    event DataPurchased(
        uint256 indexed listingId,
        address indexed buyer,
        uint256 price
    );
    
    event ListingDeactivated(uint256 indexed id);
    
    // Create a new data listing
    function createListing(
        string memory _dataHash,
        string memory _qualityProof,
        uint256 _price
    ) public returns (uint256) {
        require(_price > 0, "Price must be greater than 0");
        require(bytes(_dataHash).length > 0, "Data hash required");
        require(bytes(_qualityProof).length > 0, "Quality proof required");
        
        listingCounter++;
        
        listings[listingCounter] = Listing({
            id: listingCounter,
            seller: msg.sender,
            dataHash: _dataHash,
            qualityProof: _qualityProof,
            price: _price,
            active: true,
            createdAt: block.timestamp
        });
        
        sellerListings[msg.sender].push(listingCounter);
        
        emit ListingCreated(listingCounter, msg.sender, _price, _dataHash);
        
        return listingCounter;
    }
    
    // Purchase data
    function purchaseData(uint256 _listingId) public payable {
        Listing storage listing = listings[_listingId];
        
        require(listing.active, "Listing not active");
        require(msg.value >= listing.price, "Insufficient payment");
        require(msg.sender != listing.seller, "Cannot buy your own listing");
        require(!hasPurchased[_listingId][msg.sender], "Already purchased");
        
        // Transfer payment to seller
        payable(listing.seller).transfer(listing.price);
        
        // Refund excess payment
        if (msg.value > listing.price) {
            payable(msg.sender).transfer(msg.value - listing.price);
        }
        
        // Record purchase
        buyerPurchases[msg.sender].push(Purchase({
            listingId: _listingId,
            buyer: msg.sender,
            timestamp: block.timestamp,
            delivered: true
        }));
        
        hasPurchased[_listingId][msg.sender] = true;
        totalTransactions++;
        
        emit DataPurchased(_listingId, msg.sender, listing.price);
    }
    
    // Deactivate listing
    function deactivateListing(uint256 _listingId) public {
        Listing storage listing = listings[_listingId];
        require(msg.sender == listing.seller, "Only seller can deactivate");
        require(listing.active, "Already inactive");
        
        listing.active = false;
        emit ListingDeactivated(_listingId);
    }
    
    // Get listing details
    function getListing(uint256 _id) public view returns (
        uint256 id,
        address seller,
        string memory dataHash,
        string memory qualityProof,
        uint256 price,
        bool active,
        uint256 createdAt
    ) {
        Listing memory listing = listings[_id];
        return (
            listing.id,
            listing.seller,
            listing.dataHash,
            listing.qualityProof,
            listing.price,
            listing.active,
            listing.createdAt
        );
    }
    
    // Get seller's listings
    function getSellerListings(address _seller) public view returns (uint256[] memory) {
        return sellerListings[_seller];
    }
    
    // Get buyer's purchases
    function getBuyerPurchases(address _buyer) public view returns (Purchase[] memory) {
        return buyerPurchases[_buyer];
    }
    
    // Get total active listings
    function getTotalListings() public view returns (uint256) {
        return listingCounter;
    }
    
    // Check if buyer has purchased a listing
    function checkPurchaseStatus(uint256 _listingId, address _buyer) public view returns (bool) {
        return hasPurchased[_listingId][_buyer];
    }
}