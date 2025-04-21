import firebase_admin
from firebase_admin import credentials, firestore, auth
import os
from dotenv import load_dotenv

load_dotenv()

def initialize_firebase_app():
    """Initialize Firebase Admin SDK"""
    cred_path = os.getenv('FIREBASE_CREDENTIALS_PATH', 'serviceAccountKey.json')
    
    try:
        # Initialize the app if not already initialized
        if not firebase_admin._apps:
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)
        
        # Get Firestore client
        db = firestore.client()
        
        return db
    except Exception as e:
        print(f"Error initializing Firebase: {e}")
        raise e

def get_db():
    """Get Firestore database client"""
    return initialize_firebase_app()