# ShopEase - Flutter App with FastAPI and Firebase Backend

## About ShopEase

ShopEase is a comprehensive e-commerce mobile application designed to provide a seamless shopping experience. Built with Flutter for the frontend and FastAPI for the backend, it offers a robust solution for both customers and vendors.

### Key Features:

- **User Authentication**: Secure login and registration system using Firebase Authentication
- **Product Management**: Vendors can add, edit, and remove their products with image uploads via Cloudinary
- **Shopping Cart**: Intuitive cart system for adding and managing product selections
- **Order Processing**: Complete checkout flow including address selection and payment processing
- **User Profiles**: Personalized user experiences with profile management
- **Responsive UI**: Modern, clean interface designed for ease of use across different device sizes

### Tech Stack:

- **Frontend**: Flutter with Provider for state management
- **Backend**: FastAPI (Python)
- **Authentication & Database**: Firebase (Auth and Firestore)
- **Image Storage**: Cloudinary
- **API Communication**: RESTful endpoints with authentication tokens

### Target Audience:

- Consumers looking for a streamlined shopping experience
- Vendors seeking a platform to showcase and sell their products
- Developers interested in a modern full-stack e-commerce implementation

## Overview

ShopEase is a mobile application built with Flutter that uses a FastAPI backend. The backend leverages Firebase for authentication and data storage, providing a RESTful API for the Flutter frontend. The Flutter app does not interact directly with Firebase.

## Project Structure

```
ShopEase/
├── lib/                      # Flutter app code
│   ├── screens/              # Flutter UI screens
│   ├── models/               # Data models
│   ├── providers/            # State management
│   ├── services/             # Services including API service
│   │   └── api_service.dart  # Service to connect Flutter with FastAPI backend
│   └── utils/                # Utility functions
│       └── server_config_util.dart # Server configuration utilities
├── backend/                  # FastAPI backend code
│   ├── main.py              # Main FastAPI application
│   ├── requirements.txt     # Python dependencies
│   └── .env                 # Environment variables (create this)
├── serviceAccountKey.json    # Firebase service account credentials (you need to create this)
└── README.md                # This file
```

## Setup Instructions

### 1. Firebase Setup (Backend Only)

1.  Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2.  Enable Firebase Authentication with Email/Password
3.  Create a Firestore Database
4.  Generate a Firebase Admin SDK service account:
    - Go to Project Settings > Service accounts
    - Click "Generate new private key"
    - Save the JSON file as `serviceAccountKey.json` in your project root directory (or update path in `.env`).
5.  Get your Web API Key:
    - Go to Project Settings > General
    - Find the Web API Key under "Your apps" or "SDK setup and configuration".

### 2. Cloudinary Setup

1. Create a Cloudinary account at [Cloudinary](https://cloudinary.com/)
2. Get your Cloudinary credentials:
   - Cloud Name
   - API Key
   - API Secret

### 3. Backend Setup

1.  Install Python dependencies:

    ```bash
    cd backend
    pip install -r requirements.txt
    ```

2.  Set environment variables (create a .env file in the backend directory):

    ```
    FIREBASE_CREDENTIALS_PATH=../serviceAccountKey.json
    FIREBASE_WEB_API_KEY=YOUR_FIREBASE_WEB_API_KEY # Add your key here
    CLOUDINARY_CLOUD_NAME=YOUR_CLOUDINARY_CLOUD_NAME
    CLOUDINARY_API_KEY=YOUR_CLOUDINARY_API_KEY
    CLOUDINARY_API_SECRET=YOUR_CLOUDINARY_API_SECRET
    ```

3.  Start the FastAPI server:
    ```bash
    cd backend
    uvicorn main:app --reload
    ```

### 4. Flutter App Setup

1.  Install app dependencies:

    ```bash
    # Ensure you have required dependencies
    flutter pub get
    ```

2.  Configure the server address in the Flutter app if needed using the server configuration utilities.

## API Endpoints

The FastAPI backend provides the following endpoints:

- **Authentication**

  - `POST /auth/register` - Register a new user (via Firebase Auth)
  - `POST /auth/login` - Log in a user (verifies with Firebase Auth, returns Firebase ID token)
  - `POST /auth/logout` - (Client-side token removal primarily)

- **Users**

  - `GET /users/me` - Get current user profile (requires valid Firebase ID token)

- **Products** (Require valid Firebase ID token)

  - `GET /products/` - List all products
  - `POST /products/` - Create a product (vendors only)
  - `GET /products/{product_id}` - Get product details
  - `PUT /products/{product_id}` - Update product (owner only)
  - `DELETE /products/{product_id}` - Delete product (owner only)

- **Orders** (Require valid Firebase ID token)
  - `GET /orders/` - List user's orders
  - `POST /orders/` - Create a new order
  - `GET /orders/{order_id}` - Get order details

## Testing the API

Once the server is running, you can access the interactive API documentation:

- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## Note on Firebase Integration

This setup uses the Firebase Admin SDK on the backend (FastAPI) to interact with Firebase services (Auth, Firestore). The Flutter frontend communicates _only_ with the FastAPI backend. When a user registers or logs in via the FastAPI endpoints, the backend handles the interaction with Firebase Auth. For login, the backend verifies credentials using the Firebase Auth REST API and returns a Firebase ID Token to the Flutter app. This token is then sent by the Flutter app in the `Authorization: Bearer <token>` header for subsequent requests to protected backend endpoints. The backend verifies this token using the Firebase Admin SDK.

## Image Storage

The application uses Cloudinary for storing product images. When vendors upload product images, they are stored in Cloudinary and the URL is saved in the Firestore database.
