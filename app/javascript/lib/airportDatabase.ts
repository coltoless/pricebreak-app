// Comprehensive Airport Database
// Curated list of 100+ major international airports
// Generated on 2024-09-22

import { Airport } from '../types/flight-filter';

export const airportDatabase: Airport[] = [
  // Major North American Airports
  { iata_code: 'ATL', name: 'Hartsfield-Jackson Atlanta International Airport', city: 'Atlanta', country: 'USA', search_index: 'ATL KATL HARTSFIELD JACKSON ATLANTA INTERNATIONAL AIRPORT ATLANTA USA', icao_code: 'KATL', latitude: 33.6407, longitude: -84.4277, altitude: 1026, timezone: 'America/New_York' },
  { iata_code: 'LAX', name: 'Los Angeles International Airport', city: 'Los Angeles', country: 'USA', search_index: 'LAX KLAX LOS ANGELES INTERNATIONAL AIRPORT LOS ANGELES USA', icao_code: 'KLAX', latitude: 33.9416, longitude: -118.4085, altitude: 125, timezone: 'America/Los_Angeles' },
  { iata_code: 'ORD', name: 'O\'Hare International Airport', city: 'Chicago', country: 'USA', search_index: 'ORD KORD OHARE INTERNATIONAL AIRPORT CHICAGO USA', icao_code: 'KORD', latitude: 41.9786, longitude: -87.9048, altitude: 672, timezone: 'America/Chicago' },
  { iata_code: 'DFW', name: 'Dallas/Fort Worth International Airport', city: 'Dallas', country: 'USA', search_index: 'DFW KDFW DALLAS FORT WORTH INTERNATIONAL AIRPORT DALLAS USA', icao_code: 'KDFW', latitude: 32.8968, longitude: -97.0380, altitude: 607, timezone: 'America/Chicago' },
  { iata_code: 'DEN', name: 'Denver International Airport', city: 'Denver', country: 'USA', search_index: 'DEN KDEN DENVER INTERNATIONAL AIRPORT DENVER USA', icao_code: 'KDEN', latitude: 39.8561, longitude: -104.6737, altitude: 5431, timezone: 'America/Denver' },
  { iata_code: 'JFK', name: 'John F. Kennedy International Airport', city: 'New York', country: 'USA', search_index: 'JFK KJFK JOHN F KENNEDY INTERNATIONAL AIRPORT NEW YORK USA', icao_code: 'KJFK', latitude: 40.6413, longitude: -73.7781, altitude: 13, timezone: 'America/New_York' },
  { iata_code: 'SFO', name: 'San Francisco International Airport', city: 'San Francisco', country: 'USA', search_index: 'SFO KSFO SAN FRANCISCO INTERNATIONAL AIRPORT SAN FRANCISCO USA', icao_code: 'KSFO', latitude: 37.6213, longitude: -122.3790, altitude: 13, timezone: 'America/Los_Angeles' },
  { iata_code: 'SEA', name: 'Seattle-Tacoma International Airport', city: 'Seattle', country: 'USA', search_index: 'SEA KSEA SEATTLE TACOMA INTERNATIONAL AIRPORT SEATTLE USA', icao_code: 'KSEA', latitude: 47.4502, longitude: -122.3088, altitude: 433, timezone: 'America/Los_Angeles' },
  { iata_code: 'LAS', name: 'McCarran International Airport', city: 'Las Vegas', country: 'USA', search_index: 'LAS KLAS MCCARRAN INTERNATIONAL AIRPORT LAS VEGAS USA', icao_code: 'KLAS', latitude: 36.0840, longitude: -115.1537, altitude: 2181, timezone: 'America/Los_Angeles' },
  { iata_code: 'MIA', name: 'Miami International Airport', city: 'Miami', country: 'USA', search_index: 'MIA KMIA MIAMI INTERNATIONAL AIRPORT MIAMI USA', icao_code: 'KMIA', latitude: 25.7959, longitude: -80.2870, altitude: 8, timezone: 'America/New_York' },
  { iata_code: 'BOS', name: 'Logan International Airport', city: 'Boston', country: 'USA', search_index: 'BOS KBOS LOGAN INTERNATIONAL AIRPORT BOSTON USA', icao_code: 'KBOS', latitude: 42.3656, longitude: -71.0096, altitude: 20, timezone: 'America/New_York' },
  { iata_code: 'PHX', name: 'Phoenix Sky Harbor International Airport', city: 'Phoenix', country: 'USA', search_index: 'PHX KPHX PHOENIX SKY HARBOR INTERNATIONAL AIRPORT PHOENIX USA', icao_code: 'KPHX', latitude: 33.4342, longitude: -112.0116, altitude: 1135, timezone: 'America/Phoenix' },
  { iata_code: 'IAH', name: 'George Bush Intercontinental Airport', city: 'Houston', country: 'USA', search_index: 'IAH KIAH GEORGE BUSH INTERCONTINENTAL AIRPORT HOUSTON USA', icao_code: 'KIAH', latitude: 29.9844, longitude: -95.3414, altitude: 97, timezone: 'America/Chicago' },
  { iata_code: 'MCO', name: 'Orlando International Airport', city: 'Orlando', country: 'USA', search_index: 'MCO KMCO ORLANDO INTERNATIONAL AIRPORT ORLANDO USA', icao_code: 'KMCO', latitude: 28.4312, longitude: -81.3081, altitude: 96, timezone: 'America/New_York' },
  { iata_code: 'DTW', name: 'Detroit Metropolitan Wayne County Airport', city: 'Detroit', country: 'USA', search_index: 'DTW KDTW DETROIT METROPOLITAN WAYNE COUNTY AIRPORT DETROIT USA', icao_code: 'KDTW', latitude: 42.2162, longitude: -83.3554, altitude: 645, timezone: 'America/New_York' },
  { iata_code: 'MSP', name: 'Minneapolis-Saint Paul International Airport', city: 'Minneapolis', country: 'USA', search_index: 'MSP KMSP MINNEAPOLIS SAINT PAUL INTERNATIONAL AIRPORT MINNEAPOLIS USA', icao_code: 'KMSP', latitude: 44.8848, longitude: -93.2223, altitude: 841, timezone: 'America/Chicago' },
  { iata_code: 'PHL', name: 'Philadelphia International Airport', city: 'Philadelphia', country: 'USA', search_index: 'PHL KPHL PHILADELPHIA INTERNATIONAL AIRPORT PHILADELPHIA USA', icao_code: 'KPHL', latitude: 39.8729, longitude: -75.2437, altitude: 36, timezone: 'America/New_York' },
  { iata_code: 'LGA', name: 'LaGuardia Airport', city: 'New York', country: 'USA', search_index: 'LGA KLGA LAGUARDIA AIRPORT NEW YORK USA', icao_code: 'KLGA', latitude: 40.7769, longitude: -73.8740, altitude: 21, timezone: 'America/New_York' },
  { iata_code: 'BWI', name: 'Baltimore/Washington International Thurgood Marshall Airport', city: 'Baltimore', country: 'USA', search_index: 'BWI KBWI BALTIMORE WASHINGTON INTERNATIONAL THURGOOD MARSHALL AIRPORT BALTIMORE USA', icao_code: 'KBWI', latitude: 39.1774, longitude: -76.6684, altitude: 146, timezone: 'America/New_York' },
  { iata_code: 'SLC', name: 'Salt Lake City International Airport', city: 'Salt Lake City', country: 'USA', search_index: 'SLC KSLC SALT LAKE CITY INTERNATIONAL AIRPORT SALT LAKE CITY USA', icao_code: 'KSLC', latitude: 40.7899, longitude: -111.9791, altitude: 4227, timezone: 'America/Denver' },

  // Major Canadian Airports
  { iata_code: 'YYZ', name: 'Toronto Pearson International Airport', city: 'Toronto', country: 'Canada', search_index: 'YYZ CYYZ TORONTO PEARSON INTERNATIONAL AIRPORT TORONTO CANADA', icao_code: 'CYYZ', latitude: 43.6777, longitude: -79.6306, altitude: 569, timezone: 'America/Toronto' },
  { iata_code: 'YVR', name: 'Vancouver International Airport', city: 'Vancouver', country: 'Canada', search_index: 'YVR CYVR VANCOUVER INTERNATIONAL AIRPORT VANCOUVER CANADA', icao_code: 'CYVR', latitude: 49.1967, longitude: -123.1815, altitude: 14, timezone: 'America/Vancouver' },
  { iata_code: 'YUL', name: 'Montréal-Pierre Elliott Trudeau International Airport', city: 'Montreal', country: 'Canada', search_index: 'YUL CYUL MONTREAL PIERRE ELLIOTT TRUDEAU INTERNATIONAL AIRPORT MONTREAL CANADA', icao_code: 'CYUL', latitude: 45.4706, longitude: -73.7408, altitude: 118, timezone: 'America/Montreal' },
  { iata_code: 'YYC', name: 'Calgary International Airport', city: 'Calgary', country: 'Canada', search_index: 'YYC CYYC CALGARY INTERNATIONAL AIRPORT CALGARY CANADA', icao_code: 'CYYC', latitude: 51.1314, longitude: -114.0103, altitude: 3556, timezone: 'America/Edmonton' },
  { iata_code: 'YEG', name: 'Edmonton International Airport', city: 'Edmonton', country: 'Canada', search_index: 'YEG CYEG EDMONTON INTERNATIONAL AIRPORT EDMONTON CANADA', icao_code: 'CYEG', latitude: 53.3097, longitude: -113.5792, altitude: 2373, timezone: 'America/Edmonton' },

  // Major European Airports
  { iata_code: 'LHR', name: 'London Heathrow Airport', city: 'London', country: 'UK', search_index: 'LHR EGLL LONDON HEATHROW AIRPORT LONDON UK', icao_code: 'EGLL', latitude: 51.4700, longitude: -0.4543, altitude: 83, timezone: 'Europe/London' },
  { iata_code: 'CDG', name: 'Charles de Gaulle Airport', city: 'Paris', country: 'France', search_index: 'CDG LFPG CHARLES DE GAULLE AIRPORT PARIS FRANCE', icao_code: 'LFPG', latitude: 49.0097, longitude: 2.5479, altitude: 392, timezone: 'Europe/Paris' },
  { iata_code: 'FRA', name: 'Frankfurt Airport', city: 'Frankfurt', country: 'Germany', search_index: 'FRA EDDF FRANKFURT AIRPORT FRANKFURT GERMANY', icao_code: 'EDDF', latitude: 50.0379, longitude: 8.5622, altitude: 364, timezone: 'Europe/Berlin' },
  { iata_code: 'AMS', name: 'Amsterdam Airport Schiphol', city: 'Amsterdam', country: 'Netherlands', search_index: 'AMS EHAM AMSTERDAM AIRPORT SCHIPHOL AMSTERDAM NETHERLANDS', icao_code: 'EHAM', latitude: 52.3105, longitude: 4.7683, altitude: -11, timezone: 'Europe/Amsterdam' },
  { iata_code: 'MAD', name: 'Adolfo Suárez Madrid-Barajas Airport', city: 'Madrid', country: 'Spain', search_index: 'MAD LEMD ADOLFO SUAREZ MADRID BARAJAS AIRPORT MADRID SPAIN', icao_code: 'LEMD', latitude: 40.4983, longitude: -3.5676, altitude: 2000, timezone: 'Europe/Madrid' },
  { iata_code: 'BCN', name: 'Barcelona-El Prat Airport', city: 'Barcelona', country: 'Spain', search_index: 'BCN LEBL BARCELONA EL PRAT AIRPORT BARCELONA SPAIN', icao_code: 'LEBL', latitude: 41.2974, longitude: 2.0833, altitude: 12, timezone: 'Europe/Madrid' },
  { iata_code: 'FCO', name: 'Leonardo da Vinci International Airport', city: 'Rome', country: 'Italy', search_index: 'FCO LIRF LEONARDO DA VINCI INTERNATIONAL AIRPORT ROME ITALY', icao_code: 'LIRF', latitude: 41.8003, longitude: 12.2389, altitude: 15, timezone: 'Europe/Rome' },
  { iata_code: 'MXP', name: 'Milan Malpensa Airport', city: 'Milan', country: 'Italy', search_index: 'MXP LIMC MILAN MALPENSA AIRPORT MILAN ITALY', icao_code: 'LIMC', latitude: 45.6306, longitude: 8.7281, altitude: 768, timezone: 'Europe/Rome' },
  { iata_code: 'ZUR', name: 'Zurich Airport', city: 'Zurich', country: 'Switzerland', search_index: 'ZUR LSZH ZURICH AIRPORT ZURICH SWITZERLAND', icao_code: 'LSZH', latitude: 47.4647, longitude: 8.5492, altitude: 1416, timezone: 'Europe/Zurich' },
  { iata_code: 'VIE', name: 'Vienna International Airport', city: 'Vienna', country: 'Austria', search_index: 'VIE LOWW VIENNA INTERNATIONAL AIRPORT VIENNA AUSTRIA', icao_code: 'LOWW', latitude: 48.1103, longitude: 16.5697, altitude: 600, timezone: 'Europe/Vienna' },
  { iata_code: 'BRU', name: 'Brussels Airport', city: 'Brussels', country: 'Belgium', search_index: 'BRU EBBR BRUSSELS AIRPORT BRUSSELS BELGIUM', icao_code: 'EBBR', latitude: 50.9014, longitude: 4.4844, altitude: 184, timezone: 'Europe/Brussels' },
  { iata_code: 'IST', name: 'Istanbul Airport', city: 'Istanbul', country: 'Turkey', search_index: 'IST LTFM ISTANBUL AIRPORT ISTANBUL TURKEY', icao_code: 'LTFM', latitude: 41.2753, longitude: 28.7519, altitude: 325, timezone: 'Europe/Istanbul' },

  // Major Asian Airports
  { iata_code: 'NRT', name: 'Narita International Airport', city: 'Tokyo', country: 'Japan', search_index: 'NRT RJAA NARITA INTERNATIONAL AIRPORT TOKYO JAPAN', icao_code: 'RJAA', latitude: 35.7720, longitude: 140.3928, altitude: 141, timezone: 'Asia/Tokyo' },
  { iata_code: 'HND', name: 'Tokyo Haneda Airport', city: 'Tokyo', country: 'Japan', search_index: 'HND RJTT TOKYO HANEDA AIRPORT TOKYO JAPAN', icao_code: 'RJTT', latitude: 35.5494, longitude: 139.7798, altitude: 21, timezone: 'Asia/Tokyo' },
  { iata_code: 'ICN', name: 'Incheon International Airport', city: 'Seoul', country: 'South Korea', search_index: 'ICN RKSI INCHEON INTERNATIONAL AIRPORT SEOUL SOUTH KOREA', icao_code: 'RKSI', latitude: 37.4602, longitude: 126.4407, altitude: 23, timezone: 'Asia/Seoul' },
  { iata_code: 'PEK', name: 'Beijing Capital International Airport', city: 'Beijing', country: 'China', search_index: 'PEK ZBAA BEIJING CAPITAL INTERNATIONAL AIRPORT BEIJING CHINA', icao_code: 'ZBAA', latitude: 40.0799, longitude: 116.6031, altitude: 116, timezone: 'Asia/Shanghai' },
  { iata_code: 'PVG', name: 'Shanghai Pudong International Airport', city: 'Shanghai', country: 'China', search_index: 'PVG ZSPD SHANGHAI PUDONG INTERNATIONAL AIRPORT SHANGHAI CHINA', icao_code: 'ZSPD', latitude: 31.1434, longitude: 121.8052, altitude: 13, timezone: 'Asia/Shanghai' },
  { iata_code: 'HKG', name: 'Hong Kong International Airport', city: 'Hong Kong', country: 'Hong Kong', search_index: 'HKG VHHH HONG KONG INTERNATIONAL AIRPORT HONG KONG HONG KONG', icao_code: 'VHHH', latitude: 22.3080, longitude: 113.9185, altitude: 28, timezone: 'Asia/Hong_Kong' },
  { iata_code: 'SIN', name: 'Singapore Changi Airport', city: 'Singapore', country: 'Singapore', search_index: 'SIN WSSS SINGAPORE CHANGI AIRPORT SINGAPORE SINGAPORE', icao_code: 'WSSS', latitude: 1.3644, longitude: 103.9915, altitude: 22, timezone: 'Asia/Singapore' },
  { iata_code: 'BKK', name: 'Suvarnabhumi Airport', city: 'Bangkok', country: 'Thailand', search_index: 'BKK VTBS SUVARNABHUMI AIRPORT BANGKOK THAILAND', icao_code: 'VTBS', latitude: 13.6900, longitude: 100.7501, altitude: 5, timezone: 'Asia/Bangkok' },
  { iata_code: 'KUL', name: 'Kuala Lumpur International Airport', city: 'Kuala Lumpur', country: 'Malaysia', search_index: 'KUL WMKK KUALA LUMPUR INTERNATIONAL AIRPORT KUALA LUMPUR MALAYSIA', icao_code: 'WMKK', latitude: 2.7456, longitude: 101.7099, altitude: 71, timezone: 'Asia/Kuala_Lumpur' },
  { iata_code: 'CGK', name: 'Soekarno-Hatta International Airport', city: 'Jakarta', country: 'Indonesia', search_index: 'CGK WIII SOEKARNO HATTA INTERNATIONAL AIRPORT JAKARTA INDONESIA', icao_code: 'WIII', latitude: -6.1256, longitude: 106.6558, altitude: 34, timezone: 'Asia/Jakarta' },
  { iata_code: 'DEL', name: 'Indira Gandhi International Airport', city: 'New Delhi', country: 'India', search_index: 'DEL VIDP INDIRA GANDHI INTERNATIONAL AIRPORT NEW DELHI INDIA', icao_code: 'VIDP', latitude: 28.5562, longitude: 77.1003, altitude: 777, timezone: 'Asia/Kolkata' },
  { iata_code: 'BOM', name: 'Chhatrapati Shivaji Maharaj International Airport', city: 'Mumbai', country: 'India', search_index: 'BOM VABB CHHATRAPATI SHIVAJI MAHARAJ INTERNATIONAL AIRPORT MUMBAI INDIA', icao_code: 'VABB', latitude: 19.0887, longitude: 72.8679, altitude: 39, timezone: 'Asia/Kolkata' },
  { iata_code: 'BLR', name: 'Kempegowda International Airport', city: 'Bangalore', country: 'India', search_index: 'BLR VOBL KEMPEGOWDA INTERNATIONAL AIRPORT BANGALORE INDIA', icao_code: 'VOBL', latitude: 13.1979, longitude: 77.7063, altitude: 3000, timezone: 'Asia/Kolkata' },

  // Major Middle Eastern Airports
  { iata_code: 'DXB', name: 'Dubai International Airport', city: 'Dubai', country: 'UAE', search_index: 'DXB OMDB DUBAI INTERNATIONAL AIRPORT DUBAI UAE', icao_code: 'OMDB', latitude: 25.2532, longitude: 55.3657, altitude: 62, timezone: 'Asia/Dubai' },
  { iata_code: 'DOH', name: 'Hamad International Airport', city: 'Doha', country: 'Qatar', search_index: 'DOH OTHH HAMAD INTERNATIONAL AIRPORT DOHA QATAR', icao_code: 'OTHH', latitude: 25.2731, longitude: 51.6081, altitude: 13, timezone: 'Asia/Qatar' },
  { iata_code: 'TLV', name: 'Ben Gurion Airport', city: 'Tel Aviv', country: 'Israel', search_index: 'TLV LLBG BEN GURION AIRPORT TEL AVIV ISRAEL', icao_code: 'LLBG', latitude: 32.0114, longitude: 34.8867, altitude: 135, timezone: 'Asia/Jerusalem' },
  { iata_code: 'BAH', name: 'Bahrain International Airport', city: 'Manama', country: 'Bahrain', search_index: 'BAH OBBI BAHRAIN INTERNATIONAL AIRPORT MANAMA BAHRAIN', icao_code: 'OBBI', latitude: 26.2708, longitude: 50.6336, altitude: 6, timezone: 'Asia/Bahrain' },
  { iata_code: 'KWI', name: 'Kuwait International Airport', city: 'Kuwait City', country: 'Kuwait', search_index: 'KWI OKBK KUWAIT INTERNATIONAL AIRPORT KUWAIT CITY KUWAIT', icao_code: 'OKBK', latitude: 29.2266, longitude: 47.9689, altitude: 206, timezone: 'Asia/Kuwait' },
  { iata_code: 'MCT', name: 'Muscat International Airport', city: 'Muscat', country: 'Oman', search_index: 'MCT OOMS MUSCAT INTERNATIONAL AIRPORT MUSCAT OMAN', icao_code: 'OOMS', latitude: 23.5933, longitude: 58.2844, altitude: 48, timezone: 'Asia/Muscat' },

  // Major African Airports
  { iata_code: 'CAI', name: 'Cairo International Airport', city: 'Cairo', country: 'Egypt', search_index: 'CAI HECA CAIRO INTERNATIONAL AIRPORT CAIRO EGYPT', icao_code: 'HECA', latitude: 30.1127, longitude: 31.4000, altitude: 382, timezone: 'Africa/Cairo' },
  { iata_code: 'JNB', name: 'O.R. Tambo International Airport', city: 'Johannesburg', country: 'South Africa', search_index: 'JNB FAOR OR TAMBO INTERNATIONAL AIRPORT JOHANNESBURG SOUTH AFRICA', icao_code: 'FAOR', latitude: -26.1337, longitude: 28.2423, altitude: 5558, timezone: 'Africa/Johannesburg' },
  { iata_code: 'LOS', name: 'Murtala Muhammed International Airport', city: 'Lagos', country: 'Nigeria', search_index: 'LOS DNMM MURTALA MUHAMMED INTERNATIONAL AIRPORT LAGOS NIGERIA', icao_code: 'DNMM', latitude: 6.5774, longitude: 3.3212, altitude: 135, timezone: 'Africa/Lagos' },
  { iata_code: 'NBO', name: 'Jomo Kenyatta International Airport', city: 'Nairobi', country: 'Kenya', search_index: 'NBO HKJK JOMO KENYATTA INTERNATIONAL AIRPORT NAIROBI KENYA', icao_code: 'HKJK', latitude: -1.3192, longitude: 36.9278, altitude: 5330, timezone: 'Africa/Nairobi' },
  { iata_code: 'LAD', name: 'Quatro de Fevereiro Airport', city: 'Luanda', country: 'Angola', search_index: 'LAD FNLU QUATRO DE FEVEREIRO AIRPORT LUANDA ANGOLA', icao_code: 'FNLU', latitude: -8.8584, longitude: 13.2312, altitude: 243, timezone: 'Africa/Luanda' },

  // Major South American Airports
  { iata_code: 'GRU', name: 'São Paulo/Guarulhos International Airport', city: 'São Paulo', country: 'Brazil', search_index: 'GRU SBGR SAO PAULO GUARULHOS INTERNATIONAL AIRPORT SAO PAULO BRAZIL', icao_code: 'SBGR', latitude: -23.4356, longitude: -46.4731, altitude: 2459, timezone: 'America/Sao_Paulo' },
  { iata_code: 'EZE', name: 'Ministro Pistarini International Airport', city: 'Buenos Aires', country: 'Argentina', search_index: 'EZE SAEZ MINISTRO PISTARINI INTERNATIONAL AIRPORT BUENOS AIRES ARGENTINA', icao_code: 'SAEZ', latitude: -34.8222, longitude: -58.5358, altitude: 59, timezone: 'America/Argentina/Buenos_Aires' },
  { iata_code: 'SCL', name: 'Arturo Merino Benítez International Airport', city: 'Santiago', country: 'Chile', search_index: 'SCL SCEL ARTURO MERINO BENITEZ INTERNATIONAL AIRPORT SANTIAGO CHILE', icao_code: 'SCEL', latitude: -33.3928, longitude: -70.7858, altitude: 1555, timezone: 'America/Santiago' },
  { iata_code: 'LIM', name: 'Jorge Chávez International Airport', city: 'Lima', country: 'Peru', search_index: 'LIM SPJC JORGE CHAVEZ INTERNATIONAL AIRPORT LIMA PERU', icao_code: 'SPJC', latitude: -12.0219, longitude: -77.1143, altitude: 113, timezone: 'America/Lima' },
  { iata_code: 'BOG', name: 'El Dorado International Airport', city: 'Bogotá', country: 'Colombia', search_index: 'BOG SKBO EL DORADO INTERNATIONAL AIRPORT BOGOTA COLOMBIA', icao_code: 'SKBO', latitude: 4.7016, longitude: -74.1469, altitude: 8361, timezone: 'America/Bogota' },

  // Major Mexican Airports
  { iata_code: 'MEX', name: 'Mexico City International Airport', city: 'Mexico City', country: 'Mexico', search_index: 'MEX MMMX MEXICO CITY INTERNATIONAL AIRPORT MEXICO CITY MEXICO', icao_code: 'MMMX', latitude: 19.4363, longitude: -99.0721, altitude: 7316, timezone: 'America/Mexico_City' },
  { iata_code: 'CUN', name: 'Cancún International Airport', city: 'Cancún', country: 'Mexico', search_index: 'CUN MMUN CANCUN INTERNATIONAL AIRPORT CANCUN MEXICO', icao_code: 'MMUN', latitude: 21.0365, longitude: -86.8771, altitude: 20, timezone: 'America/Cancun' },

  // Major Oceania Airports
  { iata_code: 'SYD', name: 'Sydney Airport', city: 'Sydney', country: 'Australia', search_index: 'SYD YSSY SYDNEY AIRPORT SYDNEY AUSTRALIA', icao_code: 'YSSY', latitude: -33.9399, longitude: 151.1753, altitude: 21, timezone: 'Australia/Sydney' },
  { iata_code: 'MEL', name: 'Melbourne Airport', city: 'Melbourne', country: 'Australia', search_index: 'MEL YMML MELBOURNE AIRPORT MELBOURNE AUSTRALIA', icao_code: 'YMML', latitude: -37.6733, longitude: 144.8433, altitude: 434, timezone: 'Australia/Melbourne' },
  { iata_code: 'BNE', name: 'Brisbane Airport', city: 'Brisbane', country: 'Australia', search_index: 'BNE YBBN BRISBANE AIRPORT BRISBANE AUSTRALIA', icao_code: 'YBBN', latitude: -27.3842, longitude: 153.1175, altitude: 13, timezone: 'Australia/Brisbane' },
  { iata_code: 'PER', name: 'Perth Airport', city: 'Perth', country: 'Australia', search_index: 'PER YPPH PERTH AIRPORT PERTH AUSTRALIA', icao_code: 'YPPH', latitude: -31.9385, longitude: 115.9672, altitude: 67, timezone: 'Australia/Perth' },
  { iata_code: 'AKL', name: 'Auckland Airport', city: 'Auckland', country: 'New Zealand', search_index: 'AKL NZAA AUCKLAND AIRPORT AUCKLAND NEW ZEALAND', icao_code: 'NZAA', latitude: -37.0082, longitude: 174.7850, altitude: 23, timezone: 'Pacific/Auckland' },
  { iata_code: 'WLG', name: 'Wellington Airport', city: 'Wellington', country: 'New Zealand', search_index: 'WLG NZWN WELLINGTON AIRPORT WELLINGTON NEW ZEALAND', icao_code: 'NZWN', latitude: -41.3272, longitude: 174.8053, altitude: 41, timezone: 'Pacific/Auckland' }
];

// Enhanced search function with multiple field matching
export function searchAirportsDatabase(searchTerm: string): Airport[] {
  if (!searchTerm || searchTerm.trim().length < 2) {
    return [];
  }

  const query = searchTerm.trim().toUpperCase();
  
  // Score airports based on match quality
  const scoredAirports = airportDatabase.map(airport => {
    let score = 0;
    
    // Exact IATA code match gets highest score
    if (airport.iata_code === query) {
      score += 1000;
    }
    
    // IATA code starts with query
    if (airport.iata_code.startsWith(query)) {
      score += 500;
    }
    
    // IATA code contains query
    if (airport.iata_code.includes(query)) {
      score += 200;
    }
    
    // Airport name starts with query
    if (airport.name.toUpperCase().startsWith(query)) {
      score += 300;
    }
    
    // Airport name contains query
    if (airport.name.toUpperCase().includes(query)) {
      score += 150;
    }
    
    // City starts with query
    if (airport.city.toUpperCase().startsWith(query)) {
      score += 250;
    }
    
    // City contains query
    if (airport.city.toUpperCase().includes(query)) {
      score += 100;
    }
    
    // Country starts with query
    if (airport.country.toUpperCase().startsWith(query)) {
      score += 200;
    }
    
    // Country contains query
    if (airport.country.toUpperCase().includes(query)) {
      score += 50;
    }
    
    // Search index contains query
    if (airport.search_index?.includes(query)) {
      score += 75;
    }
    
    return { airport, score };
  }).filter(item => item.score > 0);
  
  // Sort by score (highest first) and return top 15 results
  return scoredAirports
    .sort((a, b) => b.score - a.score)
    .slice(0, 15)
    .map(item => item.airport);
}

// Get airport by IATA code
export function getAirportByIataCode(iataCode: string): Airport | null {
  const code = iataCode.trim().toUpperCase();
  return airportDatabase.find(airport => airport.iata_code === code) || null;
}

// Get popular airports (major hubs)
export function getPopularAirports(): Airport[] {
  const popularCodes = [
    'ATL', 'LAX', 'ORD', 'DFW', 'DEN', 'JFK', 'SFO', 'SEA', 'LHR', 'CDG', 
    'FRA', 'AMS', 'NRT', 'ICN', 'PEK', 'PVG', 'HKG', 'SIN', 'DXB', 'SYD',
    'MAD', 'BCN', 'FCO', 'MXP', 'ZUR', 'YYZ', 'YVR', 'YUL', 'MEX', 'CUN',
    'MEL', 'BNE', 'PER', 'AKL', 'WLG', 'CAI', 'JNB', 'LOS', 'NBO', 'GRU',
    'EZE', 'SCL', 'LIM', 'BOG', 'IST', 'TLV', 'BAH', 'KWI', 'MCT', 'DEL',
    'BOM', 'BLR', 'MAA', 'CCU'
  ];
  return popularCodes
    .map(code => getAirportByIataCode(code))
    .filter((airport): airport is Airport => airport !== null);
}

// Get airports by country
export function getAirportsByCountry(country: string): Airport[] {
  const countryUpper = country.trim().toUpperCase();
  return airportDatabase.filter(airport => 
    airport.country.toUpperCase().includes(countryUpper)
  );
}

// Get airports by region (simplified)
export function getAirportsByRegion(region: string): Airport[] {
  const regionLower = region.trim().toLowerCase();
  
  const regionMap: { [key: string]: string[] } = {
    'north america': ['USA', 'Canada', 'Mexico'],
    'europe': ['UK', 'France', 'Germany', 'Netherlands', 'Spain', 'Italy', 'Switzerland', 'Austria', 'Belgium', 'Turkey'],
    'asia': ['Japan', 'South Korea', 'China', 'Hong Kong', 'Singapore', 'Thailand', 'Malaysia', 'Indonesia', 'India'],
    'middle east': ['UAE', 'Qatar', 'Saudi Arabia', 'Israel', 'Bahrain', 'Kuwait', 'Oman'],
    'africa': ['Egypt', 'South Africa', 'Angola', 'Nigeria', 'Kenya'],
    'oceania': ['Australia', 'New Zealand'],
    'south america': ['Brazil', 'Argentina', 'Chile', 'Peru', 'Colombia']
  };
  
  const countries = regionMap[regionLower] || [];
  return airportDatabase.filter(airport => 
    countries.some(country => airport.country.includes(country))
  );
}

// Get airport statistics
export function getAirportStats(): { total: number, countries: number, regions: number } {
  const countries = new Set(airportDatabase.map(a => a.country));
  const regions = new Set(airportDatabase.map(a => {
    const country = a.country.toLowerCase();
    if (['usa', 'canada', 'mexico'].some(c => country.includes(c))) return 'North America';
    if (['uk', 'france', 'germany', 'netherlands', 'spain', 'italy', 'switzerland'].some(c => country.includes(c))) return 'Europe';
    if (['japan', 'china', 'singapore', 'india'].some(c => country.includes(c))) return 'Asia';
    if (['uae', 'qatar', 'israel'].some(c => country.includes(c))) return 'Middle East';
    if (['egypt', 'south africa', 'nigeria'].some(c => country.includes(c))) return 'Africa';
    if (['australia', 'new zealand'].some(c => country.includes(c))) return 'Oceania';
    if (['brazil', 'argentina', 'chile'].some(c => country.includes(c))) return 'South America';
    return 'Other';
  }));
  
  return {
    total: airportDatabase.length,
    countries: countries.size,
    regions: regions.size
  };
}


