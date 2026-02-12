from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from web3 import Web3
from typing import Optional, List
import json
import os
from dotenv import load_dotenv

load_dotenv()

app = FastAPI(title="Velyrion API", version="1.0.0")

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=[os.getenv("FRONTEND_URL", "http://localhost:5173")],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Web3 setup
RPC_URL = os.getenv("BLOCKCHAIN_RPC_URL")
CONTRACT_ADDRESS = Web3.to_checksum_address(os.getenv("CONTRACT_ADDRESS"))

w3 = Web3(Web3.HTTPProvider(RPC_URL))

# Load contract ABI
with open("contracts/VelyrionMarketplace.json", "r") as f:
    contract_abi = json.load(f)

contract = w3.eth.contract(address=CONTRACT_ADDRESS, abi=contract_abi)

# Pydantic models
class Listing(BaseModel):
    listing_id: int
    seller: str
    data_hash: str
    quality_proof: str
    price: int
    is_active: bool
    created_at: int

class Purchase(BaseModel):
    listing_id: int
    buyer: str
    purchase_time: int
    verified: bool

# Routes
@app.get("/")
async def root():
    return {
        "name": "Velyrion API",
        "version": "1.0.0",
        "contract": CONTRACT_ADDRESS,
        "network": "Polygon Amoy"
    }

@app.get("/health")
async def health_check():
    try:
        block_number = w3.eth.block_number
        return {
            "status": "healthy",
            "blockchain_connected": True,
            "latest_block": block_number,
            "contract_address": CONTRACT_ADDRESS
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Blockchain connection failed: {str(e)}")

@app.get("/listings/{listing_id}")
async def get_listing(listing_id: int):
    try:
        listing = contract.functions.listings(listing_id).call()
        return {
            "listing_id": listing_id,
            "seller": listing[1],
            "data_hash": listing[2],
            "quality_proof": listing[3],
            "price": listing[4],
            "is_active": listing[5],
            "created_at": listing[6]
        }
    except Exception as e:
        raise HTTPException(status_code=404, detail=f"Listing not found: {str(e)}")

@app.get("/listings/seller/{seller_address}")
async def get_seller_listings(seller_address: str):
    try:
        seller_address = Web3.to_checksum_address(seller_address)
        listing_ids = contract.functions.getSellerListings(seller_address).call()
        listings = []
        for listing_id in listing_ids:
            listing = contract.functions.listings(listing_id).call()
            listings.append({
                "listing_id": listing_id,
                "seller": listing[1],
                "data_hash": listing[2],
                "quality_proof": listing[3],
                "price": listing[4],
                "is_active": listing[5],
                "created_at": listing[6]
            })
        return {"seller": seller_address, "listings": listings}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching listings: {str(e)}")

@app.get("/purchases/buyer/{buyer_address}")
async def get_buyer_purchases(buyer_address: str):
    try:
        buyer_address = Web3.to_checksum_address(buyer_address)
        purchases = contract.functions.getBuyerPurchases(buyer_address).call()
        purchases_list = []
        for purchase in purchases:
            purchases_list.append({
                "listing_id": purchase[0],
                "buyer": purchase[1],
                "purchase_time": purchase[2],
                "verified": purchase[3]
            })
        return {"buyer": buyer_address, "purchases": purchases_list}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching purchases: {str(e)}")

@app.get("/stats")
async def get_stats():
    try:
        # Just return listing counter for now
        total_listings = contract.functions.listingCounter().call()
        return {
            "total_listings": total_listings,
            "message": "Stats endpoint working"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching stats: {str(e)}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
