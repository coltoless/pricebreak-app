// Firebase configuration and initialization
import { initializeApp, getApps } from 'firebase/app';
import { getFirestore, collection, query, where, orderBy, limit, getDocs } from 'firebase/firestore';
import { getAuth } from 'firebase/auth';
import { Airport } from '../types/flight-filter';
import { searchMockAirports, getMockAirportByIataCode } from './mockAirportData';
import { searchAirportsDatabase, getAirportByIataCode as getAirportFromDatabase } from './airportDatabase';

// Firebase configuration - these should be set in Rails data attributes
const firebaseConfig = {
  apiKey: window.firebaseConfig?.apiKey || '',
  authDomain: window.firebaseConfig?.authDomain || '',
  projectId: window.firebaseConfig?.projectId || '',
  storageBucket: window.firebaseConfig?.storageBucket || '',
  messagingSenderId: window.firebaseConfig?.messagingSenderId || '',
  appId: window.firebaseConfig?.appId || ''
};

// Initialize Firebase with error handling
let app: any = null;
let db: any = null;
let auth: any = null;
let initializationAttempted = false;

// Function to initialize Firebase (can be called multiple times safely)
function initializeFirebaseApp() {
  // If already successfully initialized, return existing instances
  if (auth) {
    return { app, db, auth };
  }
  
  // If we've already attempted and failed, try again (config might be available now)
  if (initializationAttempted) {
    initializationAttempted = false; // Allow retry
  }
  
  initializationAttempted = true;
  
  try {
    // Re-read config in case it wasn't available at module load time
    const currentConfig = {
      apiKey: window.firebaseConfig?.apiKey || '',
      authDomain: window.firebaseConfig?.authDomain || '',
      projectId: window.firebaseConfig?.projectId || '',
      storageBucket: window.firebaseConfig?.storageBucket || '',
      messagingSenderId: window.firebaseConfig?.messagingSenderId || '',
      appId: window.firebaseConfig?.appId || ''
    };
    
    // Check if Firebase config is available
    if (currentConfig.apiKey && currentConfig.projectId) {
      // Check if Firebase is already initialized
      const existingApps = getApps();
      
      if (existingApps.length > 0) {
        app = existingApps[0];
        console.log('✅ Using existing Firebase app instance');
      } else {
        app = initializeApp(currentConfig);
        console.log('✅ Firebase initialized successfully');
      }
      
      db = getFirestore(app);
      auth = getAuth(app);
      
      // Expose auth globally for inline scripts and compatibility
      if (typeof window !== 'undefined') {
        window.firebaseAuthInstance = auth;
        console.log('✅ Firebase auth instance exposed globally');
      }
      
      return { app, db, auth };
    } else {
      console.log('⚠️ Firebase config not available, using mock data');
      return { app: null, db: null, auth: null };
    }
  } catch (error) {
    console.error('❌ Firebase initialization failed:', error);
    console.log('⚠️ Falling back to mock data');
    return { app: null, db: null, auth: null };
  }
}

// Try to initialize immediately
const initResult = initializeFirebaseApp();
app = initResult.app;
db = initResult.db;
auth = initResult.auth;

// Always expose initialization function globally for manual initialization
// Use setTimeout to ensure window is fully available and listeners are set up
if (typeof window !== 'undefined') {
  // Set immediately
  (window as any).initializeFirebase = initializeFirebaseApp;
  console.log('✅ Firebase initialization function set on window.initializeFirebase');
  
  // Also set auth instance if available
  if (auth) {
    (window as any).firebaseAuthInstance = auth;
    console.log('✅ Firebase auth instance set on window.firebaseAuthInstance');
  }
  
  // Dispatch events after a small delay to ensure listeners are set up
  setTimeout(() => {
    // Dispatch a custom event when Firebase function is available
    // This allows inline scripts to know when they can call initializeFirebase
    try {
      window.dispatchEvent(new CustomEvent('firebaseFunctionReady', { 
        detail: { initializeFunction: initializeFirebaseApp, auth } 
      }));
      console.log('✅ Dispatched firebaseFunctionReady event');
    } catch (e) {
      console.error('Error dispatching firebaseFunctionReady:', e);
    }
    
    // Also dispatch when auth is ready (if it already is)
    if (auth) {
      try {
        window.dispatchEvent(new CustomEvent('firebaseReady', { detail: { auth } }));
        console.log('✅ Dispatched firebaseReady event');
      } catch (e) {
        console.error('Error dispatching firebaseReady:', e);
      }
    }
  }, 100);
} else {
  console.warn('⚠️ Window object not available when setting Firebase globals');
}

export { db, auth, initializeFirebaseApp };

// Airport service for autocomplete functionality
export class AirportService {
  private static readonly COLLECTION_NAME = 'airports';
  private static readonly SEARCH_LIMIT = 15;
  private static readonly DEBOUNCE_DELAY = 300;
  private static readonly CACHE_DURATION = 5 * 60 * 1000; // 5 minutes
  private static readonly MAX_CACHE_SIZE = 100;
  
  // In-memory cache for search results
  private static searchCache = new Map<string, { results: Airport[], timestamp: number }>();
  private static airportCache = new Map<string, { airport: Airport | null, timestamp: number }>();

  /**
   * Search for airports by query string with intelligent matching and caching
   * @param searchTerm - The search term (case-insensitive)
   * @returns Promise<Airport[]> - Array of matching airports
   */
  static async searchAirports(searchTerm: string): Promise<Airport[]> {
    if (!searchTerm || searchTerm.trim().length < 2) {
      return [];
    }

    const normalizedQuery = searchTerm.trim().toUpperCase();
    
    // Check cache first
    const cached = this.searchCache.get(normalizedQuery);
    if (cached && (Date.now() - cached.timestamp) < this.CACHE_DURATION) {
      return cached.results;
    }

    try {
      let airports: Airport[] = [];
      
      // Try Firebase first if available
      if (db) {
        try {
          airports = await this.searchFirebase(normalizedQuery);
        } catch (firebaseError) {
          console.warn('Firebase search failed, falling back to local database:', firebaseError);
        }
      }
      
      // If no Firebase results, use comprehensive local database
      if (airports.length === 0) {
        airports = searchAirportsDatabase(searchTerm);
      }
      
      // If still no results, fall back to mock data
      if (airports.length === 0) {
        airports = searchMockAirports(searchTerm);
      }
      
      // Cache the results
      this.cacheSearchResults(normalizedQuery, airports);
      
      return airports;
    } catch (error) {
      console.error('Error searching airports:', error);
      // Fall back to local database on any error
      return searchAirportsDatabase(searchTerm);
    }
  }

  /**
   * Search Firebase Firestore for airports
   * @param searchQuery - Normalized search query
   * @returns Promise<Airport[]> - Array of matching airports from Firebase
   */
  private static async searchFirebase(searchQuery: string): Promise<Airport[]> {
    const airportsRef = collection(db, this.COLLECTION_NAME);
    
    // Create multiple queries for different search strategies
    const queries = [
      // Exact IATA code match
      query(
        airportsRef,
        where('iata_code', '==', searchQuery),
        limit(1)
      ),
      // IATA code starts with query
      query(
        airportsRef,
        where('iata_code', '>=', searchQuery),
        where('iata_code', '<=', searchQuery + '\uf8ff'),
        orderBy('iata_code'),
        limit(this.SEARCH_LIMIT)
      ),
      // Search index contains query
      query(
        airportsRef,
        where('search_index', '>=', searchQuery),
        where('search_index', '<=', searchQuery + '\uf8ff'),
        orderBy('search_index'),
        limit(this.SEARCH_LIMIT)
      )
    ];

    const allResults = new Map<string, Airport>();
    
    for (const q of queries) {
      try {
        const querySnapshot = await getDocs(q);
        querySnapshot.forEach((doc) => {
          const data = doc.data();
          const airport: Airport = {
            iata_code: data.iata_code,
            name: data.name,
            city: data.city,
            country: data.country,
            search_index: data.search_index,
            icao_code: data.icao_code,
            latitude: data.latitude,
            longitude: data.longitude,
            altitude: data.altitude,
            timezone: data.timezone
          };
          allResults.set(airport.iata_code, airport);
        });
      } catch (queryError) {
        console.warn('Firebase query failed:', queryError);
      }
    }
    
    return Array.from(allResults.values()).slice(0, this.SEARCH_LIMIT);
  }

  /**
   * Get airport by IATA code with caching
   * @param iataCode - The IATA code (e.g., 'JFK')
   * @returns Promise<Airport | null> - The airport or null if not found
   */
  static async getAirportByIataCode(iataCode: string): Promise<Airport | null> {
    if (!iataCode || iataCode.trim().length < 3) {
      return null;
    }

    const normalizedCode = iataCode.trim().toUpperCase();
    
    // Check cache first
    const cached = this.airportCache.get(normalizedCode);
    if (cached && (Date.now() - cached.timestamp) < this.CACHE_DURATION) {
      return cached.airport;
    }

    try {
      let airport: Airport | null = null;
      
      // Try Firebase first if available
      if (db) {
        try {
          airport = await this.getAirportFromFirebase(normalizedCode);
        } catch (firebaseError) {
          console.warn('Firebase lookup failed, falling back to local database:', firebaseError);
        }
      }
      
      // If no Firebase result, use comprehensive local database
      if (!airport) {
        airport = getAirportFromDatabase(normalizedCode);
      }
      
      // If still no result, fall back to mock data
      if (!airport) {
        airport = getMockAirportByIataCode(normalizedCode);
      }
      
      // Cache the result
      this.cacheAirportResult(normalizedCode, airport);
      
      return airport;
    } catch (error) {
      console.error('Error getting airport by IATA code:', error);
      // Fall back to local database on any error
      return getAirportFromDatabase(normalizedCode);
    }
  }

  /**
   * Get airport from Firebase Firestore
   * @param iataCode - Normalized IATA code
   * @returns Promise<Airport | null> - The airport or null if not found
   */
  private static async getAirportFromFirebase(iataCode: string): Promise<Airport | null> {
    const airportsRef = collection(db, this.COLLECTION_NAME);
    const q = query(
      airportsRef,
      where('iata_code', '==', iataCode),
      limit(1)
    );

    const querySnapshot = await getDocs(q);
    
    if (querySnapshot.empty) {
      return null;
    }

    const doc = querySnapshot.docs[0];
    const data = doc.data();
    
    return {
      iata_code: data.iata_code,
      name: data.name,
      city: data.city,
      country: data.country,
      search_index: data.search_index,
      icao_code: data.icao_code,
      latitude: data.latitude,
      longitude: data.longitude,
      altitude: data.altitude,
      timezone: data.timezone
    };
  }

  /**
   * Cache search results
   * @param query - The search query
   * @param results - The search results
   */
  private static cacheSearchResults(query: string, results: Airport[]): void {
    // Clean up old cache entries if we're at the limit
    if (this.searchCache.size >= this.MAX_CACHE_SIZE) {
      const oldestKey = this.searchCache.keys().next().value;
      this.searchCache.delete(oldestKey);
    }
    
    this.searchCache.set(query, {
      results,
      timestamp: Date.now()
    });
  }

  /**
   * Cache airport result
   * @param iataCode - The IATA code
   * @param airport - The airport or null
   */
  private static cacheAirportResult(iataCode: string, airport: Airport | null): void {
    // Clean up old cache entries if we're at the limit
    if (this.airportCache.size >= this.MAX_CACHE_SIZE) {
      const oldestKey = this.airportCache.keys().next().value;
      this.airportCache.delete(oldestKey);
    }
    
    this.airportCache.set(iataCode, {
      airport,
      timestamp: Date.now()
    });
  }

  /**
   * Clear all caches
   */
  static clearCache(): void {
    this.searchCache.clear();
    this.airportCache.clear();
  }

  /**
   * Get cache statistics
   */
  static getCacheStats(): { searchCacheSize: number, airportCacheSize: number } {
    return {
      searchCacheSize: this.searchCache.size,
      airportCacheSize: this.airportCache.size
    };
  }

  /**
   * Debounce utility for search queries
   * @param func - The function to debounce
   * @param delay - The delay in milliseconds
   * @returns The debounced function
   */
  static debounce<T extends (...args: any[]) => any>(
    func: T,
    delay: number = this.DEBOUNCE_DELAY
  ): (...args: Parameters<T>) => void {
    let timeoutId: NodeJS.Timeout;
    
    return (...args: Parameters<T>) => {
      clearTimeout(timeoutId);
      timeoutId = setTimeout(() => func.apply(null, args), delay);
    };
  }
}

// Utility function to convert legacy airport format to new format
export function convertLegacyAirport(legacyAirport: { code: string; name: string; city: string; country: string }): Airport {
  return {
    iata_code: legacyAirport.code,
    name: legacyAirport.name,
    city: legacyAirport.city,
    country: legacyAirport.country
  };
}

// Utility function to convert new airport format to legacy format for backward compatibility
export function convertToLegacyAirport(airport: Airport): { code: string; name: string; city: string; country: string } {
  return {
    code: airport.iata_code,
    name: airport.name,
    city: airport.city,
    country: airport.country
  };
}

// Declare global firebaseConfig for Rails integration
declare global {
  interface Window {
    firebaseConfig?: {
      apiKey: string;
      authDomain: string;
      projectId: string;
      storageBucket: string;
      messagingSenderId: string;
      appId: string;
    };
    firebaseAuthInstance?: any;
    firebase?: any;
    initializeFirebase?: () => { app: any; db: any; auth: any };
  }
}

export default app;
