# ShopEase - Flutter App with FastAPI and Firebase Backend

## Overview

ShopEase is a mobile application built with Flutter that uses a FastAPI backend. The backend leverages Firebase for authentication and data storage, providing a RESTful API for the Flutter frontend. The Flutter app does not interact directly with Firebase.

## Project Structure

```
ShopEase/
├── lib/                      # Flutter app code
│   └── services/
│       └── api_service.dart # Service to connect Flutter with FastAPI backend
├── backend/                  # FastAPI backend code
│   ├── main.py              # Main FastAPI application
│   ├── firebase_admin_config.py # Firebase Admin SDK configuration
│   └── requirements.txt     # Python dependencies
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

### 2. Backend Setup

1.  Install Python dependencies:

    ```bash
    cd backend
    pip install -r requirements.txt
    ```

2.  Set environment variables (create a .env file in the backend directory):

    ```
    FIREBASE_CREDENTIALS_PATH=../serviceAccountKey.json
    FIREBASE_WEB_API_KEY=YOUR_FIREBASE_WEB_API_KEY # Add your key here
    ```

3.  Start the FastAPI server:
    ```bash
    cd backend
    uvicorn main:app --reload
    ```

### 3. Flutter App Setup

1.  Install app dependencies:

    ```bash
    # Ensure you have dio and shared_preferences
    flutter pub add dio shared_preferences
    # Remove firebase_core and firebase_auth if previously added
    # flutter pub remove firebase_core firebase_auth
    ```

2.  Update your Flutter app's `main.dart` to remove any `Firebase.initializeApp()` calls if present.

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
