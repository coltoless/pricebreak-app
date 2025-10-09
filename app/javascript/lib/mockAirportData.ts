// Mock airport data for development/testing when Firebase is not available
import { Airport } from '../types/flight-filter';

export const mockAirports: Airport[] = [
  {
    iata_code: 'LAX',
    name: 'Los Angeles International Airport',
    city: 'Los Angeles',
    country: 'USA',
    search_index: 'LAX LOS ANGELES INTERNATIONAL AIRPORT LOS ANGELES',
    icao_code: 'KLAX',
    latitude: 33.9425,
    longitude: -118.4081,
    altitude: 125,
    timezone: 'America/Los_Angeles'
  },
  {
    iata_code: 'JFK',
    name: 'John F. Kennedy International Airport',
    city: 'New York',
    country: 'USA',
    search_index: 'JFK JOHN F. KENNEDY INTERNATIONAL AIRPORT NEW YORK',
    icao_code: 'KJFK',
    latitude: 40.6413,
    longitude: -73.7781,
    altitude: 13,
    timezone: 'America/New_York'
  },
  {
    iata_code: 'SFO',
    name: 'San Francisco International Airport',
    city: 'San Francisco',
    country: 'USA',
    search_index: 'SFO SAN FRANCISCO INTERNATIONAL AIRPORT SAN FRANCISCO',
    icao_code: 'KSFO',
    latitude: 37.6213,
    longitude: -122.3790,
    altitude: 13,
    timezone: 'America/Los_Angeles'
  },
  {
    iata_code: 'ORD',
    name: 'O\'Hare International Airport',
    city: 'Chicago',
    country: 'USA',
    search_index: 'ORD O\'HARE INTERNATIONAL AIRPORT CHICAGO',
    icao_code: 'KORD',
    latitude: 41.9786,
    longitude: -87.9048,
    altitude: 672,
    timezone: 'America/Chicago'
  },
  {
    iata_code: 'MIA',
    name: 'Miami International Airport',
    city: 'Miami',
    country: 'USA',
    search_index: 'MIA MIAMI INTERNATIONAL AIRPORT MIAMI',
    icao_code: 'KMIA',
    latitude: 25.7959,
    longitude: -80.2870,
    altitude: 8,
    timezone: 'America/New_York'
  },
  {
    iata_code: 'LAS',
    name: 'Harry Reid International Airport',
    city: 'Las Vegas',
    country: 'USA',
    search_index: 'LAS HARRY REID INTERNATIONAL AIRPORT LAS VEGAS',
    icao_code: 'KLAS',
    latitude: 36.0840,
    longitude: -115.1537,
    altitude: 2181,
    timezone: 'America/Los_Angeles'
  },
  {
    iata_code: 'LHR',
    name: 'London Heathrow Airport',
    city: 'London',
    country: 'UK',
    search_index: 'LHR LONDON HEATHROW AIRPORT LONDON',
    icao_code: 'EGLL',
    latitude: 51.4700,
    longitude: -0.4543,
    altitude: 83,
    timezone: 'Europe/London'
  },
  {
    iata_code: 'CDG',
    name: 'Charles de Gaulle Airport',
    city: 'Paris',
    country: 'France',
    search_index: 'CDG CHARLES DE GAULLE AIRPORT PARIS',
    icao_code: 'LFPG',
    latitude: 49.0097,
    longitude: 2.5479,
    altitude: 392,
    timezone: 'Europe/Paris'
  },
  {
    iata_code: 'NRT',
    name: 'Narita International Airport',
    city: 'Tokyo',
    country: 'Japan',
    search_index: 'NRT NARITA INTERNATIONAL AIRPORT TOKYO',
    icao_code: 'RJAA',
    latitude: 35.7720,
    longitude: 140.3928,
    altitude: 141,
    timezone: 'Asia/Tokyo'
  },
  {
    iata_code: 'SYD',
    name: 'Sydney Airport',
    city: 'Sydney',
    country: 'Australia',
    search_index: 'SYD SYDNEY AIRPORT SYDNEY',
    icao_code: 'YSSY',
    latitude: -33.9399,
    longitude: 151.1753,
    altitude: 21,
    timezone: 'Australia/Sydney'
  },
  {
    iata_code: 'DXB',
    name: 'Dubai International Airport',
    city: 'Dubai',
    country: 'UAE',
    search_index: 'DXB DUBAI INTERNATIONAL AIRPORT DUBAI',
    icao_code: 'OMDB',
    latitude: 25.2532,
    longitude: 55.3657,
    altitude: 62,
    timezone: 'Asia/Dubai'
  },
  {
    iata_code: 'SIN',
    name: 'Singapore Changi Airport',
    city: 'Singapore',
    country: 'Singapore',
    search_index: 'SIN SINGAPORE CHANGI AIRPORT SINGAPORE',
    icao_code: 'WSSS',
    latitude: 1.3644,
    longitude: 103.9915,
    altitude: 22,
    timezone: 'Asia/Singapore'
  },
  {
    iata_code: 'FRA',
    name: 'Frankfurt Airport',
    city: 'Frankfurt',
    country: 'Germany',
    search_index: 'FRA FRANKFURT AIRPORT FRANKFURT',
    icao_code: 'EDDF',
    latitude: 50.0379,
    longitude: 8.5622,
    altitude: 364,
    timezone: 'Europe/Berlin'
  },
  {
    iata_code: 'AMS',
    name: 'Amsterdam Airport Schiphol',
    city: 'Amsterdam',
    country: 'Netherlands',
    search_index: 'AMS AMSTERDAM AIRPORT SCHIPHOL AMSTERDAM',
    icao_code: 'EHAM',
    latitude: 52.3105,
    longitude: 4.7683,
    altitude: -11,
    timezone: 'Europe/Amsterdam'
  },
  {
    iata_code: 'ICN',
    name: 'Incheon International Airport',
    city: 'Seoul',
    country: 'South Korea',
    search_index: 'ICN INCHEON INTERNATIONAL AIRPORT SEOUL',
    icao_code: 'RKSI',
    latitude: 37.4602,
    longitude: 126.4407,
    altitude: 23,
    timezone: 'Asia/Seoul'
  }
];

export function searchMockAirports(searchTerm: string): Airport[] {
  if (!searchTerm || searchTerm.trim().length < 2) {
    return [];
  }

  const query = searchTerm.trim().toUpperCase();
  
  return mockAirports.filter(airport => 
    airport.search_index?.includes(query) ||
    airport.iata_code.includes(query) ||
    airport.name.toUpperCase().includes(query) ||
    airport.city.toUpperCase().includes(query) ||
    airport.country.toUpperCase().includes(query)
  ).slice(0, 10);
}

export function getMockAirportByIataCode(iataCode: string): Airport | null {
  const code = iataCode.trim().toUpperCase();
  return mockAirports.find(airport => airport.iata_code === code) || null;
}





