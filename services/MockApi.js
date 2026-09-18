// This file has been transitioned from Mock to Real API Gateway Endpoints!
import { fetchAuthSession } from 'aws-amplify/auth';
const API_URL = 'https://e5kbjdyjh5.execute-api.us-east-1.amazonaws.com/prod';

const getAuthHeaders = async (customHeaders = {}) => {
  try {
    const session = await fetchAuthSession();
    return {
      'Authorization': session.tokens?.idToken?.toString() || '',
      ...customHeaders
    };
  } catch (error) {
    console.warn("No active AWS Auth Session found:", error);
    return customHeaders;
  }
};

export const MockApi = {
  getHealth: async () => {
    return { status: "ok", service: "aws-serverless-backend" };
  },

  getUserProfile: async (email) => {
    try {
      const headers = await getAuthHeaders();
      const response = await fetch(`${API_URL}/profile?email=${encodeURIComponent(email)}`, { headers });
      if (!response.ok) {
        throw new Error(`Failed to fetch profile: ${response.status}`);
      }
      return await response.json();
    } catch (error) {
      // Throw to let the caller handle it (e.g. SensorMonitor) without spamming the console
      throw error;
    }
  },

  putUserProfile: async (email, profileData) => {
    try {
      const headers = await getAuthHeaders({ 'Content-Type': 'application/json' });
      const response = await fetch(`${API_URL}/profile`, {
        method: 'PUT',
        headers,
        body: JSON.stringify({ email, ...profileData })
      });
      if (!response.ok) throw new Error("Failed to update profile");
      return await response.json();
    } catch (error) {
      console.error(error);
      throw error;
    }
  },

  getRoutes: async (origin, destination, mode, email, explicitSafetyPreference) => {
    try {
      let url = `${API_URL}/routes?origin=${encodeURIComponent(origin)}&destination=${encodeURIComponent(destination)}&mode=${encodeURIComponent(mode)}`;
      if (email) url += `&email=${encodeURIComponent(email)}`;
      if (explicitSafetyPreference !== undefined) url += `&explicitSafetyPreference=${encodeURIComponent(explicitSafetyPreference)}`;
      
      const headers = await getAuthHeaders();
      const response = await fetch(url, { headers });
      if (!response.ok) {
        const errText = await response.text();
        console.error("Route Fetch Error Body:", errText);
        throw new Error("Failed to fetch routes: " + errText);
      }
      return await response.json();
    } catch (error) {
      console.error("Route fetch exception:", error);
      throw error;
    }
  },

  getSafetySegment: async (segmentId) => {
    // Keep local mock for now as Segment data is too large for simple Lambda
    const processedData = require('../data/safety-navigation-data/processed/output.json');
    const segment = processedData.find(s => s.segment_id === segmentId);
    
    if (!segment) throw new Error("Segment not found");

    return {
      segment_id: segment.segment_id,
      crime_score: Math.round((1 - segment.crime_density) * 100),
      lighting_score: Math.round(segment.lighting_density * 100),
      activity_score: Math.round(segment.activity_density * 100),
      user_score: 90,
      emergency_proximity: 95,
      confidence: 0.86
    };
  },

  triggerSOS: async (location, userEmail) => {
    try {
      const headers = await getAuthHeaders({ 'Content-Type': 'application/json' });
      const response = await fetch(`${API_URL}/sos`, {
        method: 'POST',
        headers,
        body: JSON.stringify({ location, email: userEmail })
      });
      if (!response.ok) throw new Error("Failed to trigger SOS");
      return await response.json();
    } catch (error) {
      console.error(error);
      throw error;
    }
  },

  getSafeHavens: async (lat, lng) => {
    // Dummy static for now, would typically hit a Places API lambda
    return [
      { id: 'haven_1', name: 'Central Police Station', type: 'Police', geometry: { latitude: lat + 0.002, longitude: lng + 0.003 } },
      { id: 'haven_2', name: 'City General Hospital', type: 'Hospital', geometry: { latitude: lat - 0.003, longitude: lng - 0.001 } },
      { id: 'haven_3', name: '24/7 Pharmacy', type: 'Store', geometry: { latitude: lat + 0.001, longitude: lng - 0.004 } }
    ];
  },

  submitReport: async (reportData) => {
    try {
      const headers = await getAuthHeaders({ 'Content-Type': 'application/json' });
      const response = await fetch(`${API_URL}/reports`, {
        method: 'POST',
        headers,
        body: JSON.stringify(reportData)
      });
      if (!response.ok) throw new Error("Failed to submit report");
      return await response.json();
    } catch (error) {
      console.error(error);
      throw error;
    }
  }
};
