// API service for ShopEase
import axios from 'axios';
import { getAuth } from 'firebase/auth';

// Create axios instance with base URL
const api = axios.create({
    baseURL: 'http://localhost:8000',
    timeout: 10000, // 10 second timeout
    headers: {
        'Content-Type': 'application/json'
    }
});

// Add request interceptor to attach auth token
api.interceptors.request.use(async (config) => {
    try {
        const auth = getAuth();
        const user = auth.currentUser;

        if (user) {
            const token = await user.getIdToken();
            config.headers.Authorization = `Bearer ${token}`;
        }
        return config;
    } catch (error) {
        console.error('Error setting auth token:', error);
        return config;
    }
}, (error) => {
    return Promise.reject(error);
});

// Add response interceptor for handling common errors
api.interceptors.response.use(
    (response) => response,
    (error) => {
        console.error('API Error:', error);

        // Check if error is due to network issues
        if (error.code === 'ECONNABORTED' || !error.response) {
            console.error('Network error or API server not responding');
            // You can dispatch actions here if using Redux or emit events
        }

        return Promise.reject(error);
    }
);

export default api;