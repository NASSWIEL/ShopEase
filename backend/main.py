from fastapi import FastAPI, Depends, HTTPException, status, Header, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from fastapi.staticfiles import StaticFiles
from fastapi.responses import JSONResponse
from firebase_admin import auth, firestore, initialize_app
from firebase_admin import credentials
from pydantic import BaseModel
from typing import List, Optional, Dict, Any, Union
import firebase_admin
import os
import uuid
from datetime import datetime
import json
import requests
import shutil
import cloudinary
import cloudinary.uploader
import cloudinary.api
from pathlib import Path
from dotenv import load_dotenv

# Load environment variables
load_dotenv()
FIREBASE_WEB_API_KEY = os.getenv("FIREBASE_WEB_API_KEY")

# Configure Cloudinary
cloudinary.config(
    cloud_name=os.getenv("CLOUDINARY_CLOUD_NAME"),
    api_key=os.getenv("CLOUDINARY_API_KEY"),
    api_secret=os.getenv("CLOUDINARY_API_SECRET"),
    secure=True
)

# Initialize Firebase Admin
cred_path = os.getenv("FIREBASE_CREDENTIALS_PATH", "serviceAccountKey.json")
cred = credentials.Certificate(cred_path)
firebase_app = initialize_app(cred)
db = firestore.client()

# Create temporary upload directory if it doesn't exist
UPLOAD_DIR = "tmp_uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)

# FastAPI app
app = FastAPI(title="ShopEase API")

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, replace with your frontend URL
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# OAuth2 password bearer for token handling
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login")

# Models
class UserCreate(BaseModel):
    name: str
    email: str
    password: str
    user_type: str  # 'customer', 'vendor', 'admin'

class User(BaseModel):
    id: str
    name: str
    email: str
    user_type: str

class UserLogin(BaseModel):
    email: str
    password: str

class LoginResponse(BaseModel):
    token: str
    user: User
    
class Product(BaseModel):
    id: Optional[str] = None
    name: str
    description: str
    price: float
    image_url: Optional[str] = None
    stock: int
    vendor_id: str
    barcode: Optional[str] = None  # Adding barcode field to Product model
    
class Order(BaseModel):
    id: Optional[str] = None
    user_id: str
    products: List[dict]  # List of product IDs and quantities
    total_price: float
    status: str = "pending"  # pending, confirmed, shipped, delivered
    created_at: Optional[str] = None
    
# Helper functions
async def get_current_user(token: str = Depends(oauth2_scheme)):
    try:
        decoded_token = auth.verify_id_token(token)
        uid = decoded_token['uid']
        user_doc = db.collection('users').document(uid).get()
        
        if not user_doc.exists:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
        
        user_data = user_doc.to_dict()
        return {
            "id": uid,
            "name": user_data.get("name", ""),
            "email": user_data.get("email", ""),
            "user_type": user_data.get("user_type", "customer")
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )

# Function to upload an image to Cloudinary
async def upload_image_to_cloudinary(image_file: UploadFile) -> str:
    """Upload an image to Cloudinary and return the URL"""
    if not image_file or not image_file.filename:
        return None
        
    try:
        # Create a temporary file
        temp_file_path = os.path.join(UPLOAD_DIR, f"temp_{uuid.uuid4()}{os.path.splitext(image_file.filename)[1]}")
        
        # Write file content to temporary file
        with open(temp_file_path, "wb") as buffer:
            contents = await image_file.read()
            buffer.write(contents)
        
        # Reset file pointer for potential reuse
        await image_file.seek(0)
        
        # Upload to Cloudinary with a unique public_id based on timestamp and random ID
        folder = "shopease/products"
        public_id = f"{folder}/{datetime.now().strftime('%Y%m%d_%H%M%S')}_{uuid.uuid4().hex[:8]}"
        
        upload_result = cloudinary.uploader.upload(
            temp_file_path,
            public_id=public_id,
            folder=None,  # Already included in public_id
            overwrite=True,
            resource_type="auto"
        )
        
        # Delete temporary file
        if os.path.exists(temp_file_path):
            os.remove(temp_file_path)
        
        # Return the secure URL
        return upload_result["secure_url"]
        
    except Exception as e:
        print(f"Error uploading to Cloudinary: {e}")
        if os.path.exists(temp_file_path):
            os.remove(temp_file_path)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error uploading image: {str(e)}"
        )

# Function to delete an image from Cloudinary
def delete_image_from_cloudinary(image_url: str) -> bool:
    """Delete an image from Cloudinary using its URL"""
    if not image_url or "cloudinary.com" not in image_url:
        return False
        
    try:
        # Extract public_id from URL
        # URL format: https://res.cloudinary.com/cloud_name/image/upload/v1234567890/shopease/products/filename.jpg
        parts = image_url.split("upload/")
        if len(parts) < 2:
            print(f"Could not parse Cloudinary URL: {image_url}")
            return False
            
        # Get the path after version number (v1234567890/)
        path_with_version = parts[1]
        # Find the version part (v1234567890/)
        version_parts = path_with_version.split("/", 1)
        if len(version_parts) < 2:
            # No version number, use the whole path
            public_id = path_with_version
        else:
            # Remove the version number
            public_id = version_parts[1]
        
        # Remove file extension
        public_id = os.path.splitext(public_id)[0]
        
        # Delete from Cloudinary
        result = cloudinary.uploader.destroy(public_id)
        
        if result.get("result") == "ok":
            return True
        else:
            print(f"Cloudinary deletion returned: {result}")
            return False
            
    except Exception as e:
        print(f"Error deleting from Cloudinary: {e}")
        return False

# Auth endpoints
@app.post("/auth/register", response_model=LoginResponse)
async def register_user(user: UserCreate):
    try:
        # Create user in Firebase Auth
        firebase_user = auth.create_user(
            email=user.email,
            password=user.password,
            display_name=user.name
        )

        # Create user document in Firestore
        user_data = {
            "name": user.name,
            "email": user.email,
            "user_type": user.user_type,
            "created_at": firestore.SERVER_TIMESTAMP
        }
        db.collection('users').document(firebase_user.uid).set(user_data)

        # Sign in the user immediately using REST API to get an ID token
        rest_api_url = "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword"
        payload = json.dumps({
            "email": user.email,
            "password": user.password,
            "returnSecureToken": True
        })
        params = {"key": FIREBASE_WEB_API_KEY}
        
        rest_response = requests.post(rest_api_url, params=params, data=payload)
        rest_response.raise_for_status() # Raise exception for bad status codes
        
        auth_data = rest_response.json()
        id_token = auth_data.get("idToken")

        if not id_token:
             raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Could not obtain ID token after registration")

        # Return user and Firebase ID token
        return {
            "token": id_token,
            "user": {
                "id": firebase_user.uid,
                "name": user.name,
                "email": user.email,
                "user_type": user.user_type
            }
        }
    except requests.exceptions.RequestException as e:
         # Handle specific REST API errors if needed
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=f"Firebase REST API error: {e}")
    except auth.UserNotFoundError:
         raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found after creation somehow.")
    except Exception as e:
        # Catch potential Firebase Admin SDK errors during user creation
        if hasattr(e, 'code') and e.code == 'EMAIL_ALREADY_EXISTS':
             raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Email already exists")
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))

@app.post("/auth/login", response_model=LoginResponse)
async def login_user(user: UserLogin):
    if not FIREBASE_WEB_API_KEY:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Firebase Web API Key not configured")
        
    try:
        # Debug logging
        print(f"Login attempt for email: {user.email}")
        
        # Verify user credentials with Firebase Auth REST API
        rest_api_url = "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword"
        payload = json.dumps({
            "email": user.email,
            "password": user.password,
            "returnSecureToken": True
        })
        params = {"key": FIREBASE_WEB_API_KEY}
        
        print(f"Sending request to Firebase Auth API: {rest_api_url}")
        rest_response = requests.post(rest_api_url, params=params, data=payload)
        print(f"Firebase response status: {rest_response.status_code}")
        
        if rest_response.status_code != 200:
            # Debug logging
            print(f"Firebase error response: {rest_response.text}")
            
            # Attempt to parse Firebase error
            try:
                error_data = rest_response.json()
                error_message = error_data.get("error", {}).get("message", "Invalid credentials")
                print(f"Firebase error message: {error_message}")
                
                # Return appropriate HTTP status based on error type
                if error_message == "INVALID_LOGIN_CREDENTIALS":
                    # IMPORTANT: Don't use raise HTTPException here to avoid potential issues
                    return JSONResponse(
                        status_code=status.HTTP_401_UNAUTHORIZED,
                        content={"detail": "Email ou mot de passe incorrect"},
                    )
                elif error_message == "USER_DISABLED":
                    return JSONResponse(
                        status_code=status.HTTP_403_FORBIDDEN,
                        content={"detail": "Ce compte utilisateur est désactivé"},
                    )
                else:
                    return JSONResponse(
                        status_code=status.HTTP_401_UNAUTHORIZED,
                        content={"detail": f"Erreur d'authentification: {error_message}"},
                    )
                    
            except json.JSONDecodeError:
                # Fallback if response is not JSON
                return JSONResponse(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    content={"detail": "Identifiants invalides"},
                )

        # -- Success path continues here --
        auth_data = rest_response.json()
        id_token = auth_data.get("idToken")
        uid = auth_data.get("localId")
        
        print(f"Successfully authenticated user with ID: {uid}")

        if not id_token or not uid:
            print("Missing idToken or localId in Firebase response")
            raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, 
                                detail="Failed to retrieve token or user ID from Firebase")

        # Get user data from Firestore
        print(f"Fetching user data from Firestore for UID: {uid}")
        user_doc = db.collection('users').document(uid).get()
        if not user_doc.exists:
            print(f"User document not found in Firestore for UID: {uid}")
            # This case might happen if Firestore data is inconsistent with Auth
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, 
                               detail="User data not found in database")
             
        user_data = user_doc.to_dict()
        print(f"Successfully retrieved user data: {user_data}")

        # Return user and Firebase ID token
        return {
            "token": id_token,
            "user": {
                "id": uid,
                "name": user_data.get("name", ""),
                "email": user_data.get("email", user.email), # Use Firestore email, fallback to request email
                "user_type": user_data.get("user_type", "customer")
            }
        }
    except requests.exceptions.RequestException as e:
        print(f"Request exception during login: {e}")
        # Handle network or other request errors
        raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, 
                           detail=f"Firebase Auth service unavailable: {e}")
    except Exception as e:
        print(f"Unexpected error during login: {type(e).__name__}: {str(e)}")
        import traceback
        traceback.print_exc()
        # Catch-all for other unexpected errors
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, 
            detail=f"An unexpected error occurred: {str(e)}"
        )

@app.post("/auth/logout")
async def logout_user(current_user: dict = Depends(get_current_user)):
    # In this architecture, logout is handled client-side by removing the token
    # The backend doesn't need to do anything
    return {"message": "Logout successful"}

# User endpoints
@app.get("/users/me", response_model=User)
async def get_current_user_profile(current_user: dict = Depends(get_current_user)):
    return current_user

# Product endpoints
@app.get("/products/")
async def get_products():
    products = []
    docs = db.collection('products').stream()
    
    for doc in docs:
        product_data = doc.to_dict()
        product_data["id"] = doc.id
        products.append(product_data)
        
    return products

@app.get("/products/{product_id}")
async def get_product(product_id: str):
    doc = db.collection('products').document(product_id).get()
    
    if not doc.exists:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found")
        
    product_data = doc.to_dict()
    product_data["id"] = doc.id
    return product_data

@app.post("/products/")
async def create_product(
    name: str = Form(...),
    description: str = Form(...),
    price: float = Form(...),
    stock: int = Form(...),
    image: UploadFile = File(None),
    barcode: Optional[str] = Form(None),  # Adding barcode field to product creation
    current_user: dict = Depends(get_current_user)
):
    # Ensure user is a vendor
    if current_user["user_type"] != "vendor" and current_user["user_type"] != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, 
            detail="Only vendors can create products"
        )
    
    # Upload the image to Cloudinary if provided
    image_url = await upload_image_to_cloudinary(image) if image else None
    
    # Create product document
    product_dict = {
        "name": name,
        "description": description,
        "price": price,
        "stock": stock,
        "image_url": image_url,
        "vendor_id": current_user["id"],
        "barcode": barcode,  # Adding barcode to product document
        # Ne pas utiliser SERVER_TIMESTAMP ici pour éviter les erreurs de sérialisation
        "created_at": datetime.now().isoformat()
    }
    
    # Add to Firestore
    doc_ref = db.collection('products').document()
    # Copie du dictionnaire pour ajouter SERVER_TIMESTAMP uniquement lors de l'enregistrement
    firestore_dict = product_dict.copy()
    firestore_dict["created_at"] = firestore.SERVER_TIMESTAMP
    doc_ref.set(firestore_dict)
    
    # Return created product
    created_product = product_dict.copy()
    created_product["id"] = doc_ref.id
    return created_product

@app.put("/products/{product_id}")
async def update_product(
    product_id: str, 
    name: str = Form(...),
    description: str = Form(...),
    price: float = Form(...),
    stock: int = Form(...),
    image: UploadFile = File(None),
    delete_image: bool = Form(False),
    barcode: Optional[str] = Form(None),  # Adding barcode field to product update
    current_user: dict = Depends(get_current_user)
):
    # Check if product exists
    doc = db.collection('products').document(product_id).get()
    if not doc.exists:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found")
    
    # Check if user is owner or admin
    product_data = doc.to_dict()
    if (product_data["vendor_id"] != current_user["id"] and 
        current_user["user_type"] != "admin"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, 
            detail="You can only update your own products"
        )
    
    # Handle image operations
    image_url = None
    current_image_url = product_data.get("image_url")
    
    # Delete existing image if requested or if a new one is being uploaded
    if (delete_image or image) and current_image_url:
        delete_image_from_cloudinary(current_image_url)
        current_image_url = None
    
    # Upload the new image if provided
    if image:
        image_url = await upload_image_to_cloudinary(image)
    
    # Update product
    update_data = {
        "name": name,
        "description": description,
        "price": price,
        "stock": stock,
        "image_url": image_url if image else (None if delete_image else current_image_url),
        "barcode": barcode  # Adding barcode to product update
    }
    db.collection('products').document(product_id).update(update_data)
    
    # Return updated product
    updated_product = update_data.copy()
    updated_product["id"] = product_id
    updated_product["vendor_id"] = product_data["vendor_id"]
    return updated_product

@app.delete("/products/{product_id}")
async def delete_product(
    product_id: str, 
    current_user: dict = Depends(get_current_user)
):
    # Check if product exists
    doc = db.collection('products').document(product_id).get()
    if not doc.exists:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found")
    
    # Check if user is owner or admin
    product_data = doc.to_dict()
    if (product_data["vendor_id"] != current_user["id"] and 
        current_user["user_type"] != "admin"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, 
            detail="You can only delete your own products"
        )
    
    # Delete the image from Cloudinary if it exists
    if product_data.get("image_url"):
        delete_image_from_cloudinary(product_data["image_url"])
    
    # Delete product
    db.collection('products').document(product_id).delete()
    
    return {"message": "Product deleted successfully"}

# Order endpoints
@app.post("/orders/")
async def create_order(order: Order, current_user: dict = Depends(get_current_user)):
    # Create order document
    order_dict = order.dict(exclude={"id"})
    order_dict["user_id"] = current_user["id"]
    order_dict["created_at"] = firestore.SERVER_TIMESTAMP
    
    # Add to Firestore
    doc_ref = db.collection('orders').document()
    doc_ref.set(order_dict)
    
    # Return created order
    created_order = order_dict.copy()
    created_order["id"] = doc_ref.id
    return created_order

@app.get("/orders/")
async def get_user_orders(current_user: dict = Depends(get_current_user)):
    orders = []
    
    if current_user["user_type"] == "admin":
        # Admins can see all orders
        docs = db.collection('orders').stream()
    elif current_user["user_type"] == "vendor":
        # Vendors can see orders with their products
        # This is a simplification - in a real app, you'd need a more efficient query
        docs = db.collection('orders').stream()
        vendor_orders = []
        for doc in docs:
            order_data = doc.to_dict()
            for product in order_data.get("products", []):
                product_doc = db.collection('products').document(product["product_id"]).get()
                if product_doc.exists and product_doc.to_dict().get("vendor_id") == current_user["id"]:
                    order_data["id"] = doc.id
                    vendor_orders.append(order_data)
                    break
        return vendor_orders
    else:
        # Customers can only see their own orders
        docs = db.collection('orders').where("user_id", "==", current_user["id"]).stream()
    
    for doc in docs:
        order_data = doc.to_dict()
        order_data["id"] = doc.id
        orders.append(order_data)
        
    return orders

@app.get("/orders/{order_id}")
async def get_order(order_id: str, current_user: dict = Depends(get_current_user)):
    doc = db.collection('orders').document(order_id).get()
    
    if not doc.exists:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found")
        
    order_data = doc.to_dict()
    
    # Check permissions
    if (current_user["user_type"] != "admin" and 
        order_data["user_id"] != current_user["id"]):
        # For vendors, check if they have products in this order
        if current_user["user_type"] == "vendor":
            vendor_has_product = False
            for product in order_data.get("products", []):
                product_doc = db.collection('products').document(product["product_id"]).get()
                if product_doc.exists and product_doc.to_dict().get("vendor_id") == current_user["id"]:
                    vendor_has_product = True
                    break
            
            if not vendor_has_product:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN, 
                    detail="You don't have permission to view this order"
                )
        else:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN, 
                detail="You don't have permission to view this order"
            )
    
    order_data["id"] = doc.id
    return order_data

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)