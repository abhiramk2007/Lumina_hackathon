// This file simulates an API Gateway + Lambda backend
import AsyncStorage from '@react-native-async-storage/async-storage';

export const MockApi = {
  // Simulates: GET /health
  getHealth: async () => {
    // Simulate network delay
    await new Promise(resolve => setTimeout(resolve, 500));
    
    return {
      status: "ok",
      service: "safety-navigation-api"
    };
  },

  // Simulates: GET /user/profile (Authenticated endpoint)
  getUserProfile: async (email) => {
    await new Promise(resolve => setTimeout(resolve, 300));
    
    try {
      const usersStr = await AsyncStorage.getItem('@mock_cognito_users');
      const users = usersStr ? JSON.parse(usersStr) : [];
      const user = users.find(u => u.email === email);
      
      if (!user) {
        throw new Error("User not found");
      }
      
      return {
        email: user.email,
        transportPreference: user.transportPreference || 'Car',
        safetyPreference: user.safetyPreference ?? 0.5,
        emergencyContacts: user.emergencyContacts || []
      };
    } catch (error) {
      throw error;
    }
  },

  // Simulates: PUT /user/profile
  putUserProfile: async (email, profileData) => {
    await new Promise(resolve => setTimeout(resolve, 300));
    
    try {
      const usersStr = await AsyncStorage.getItem('@mock_cognito_users');
      let users = usersStr ? JSON.parse(usersStr) : [];
      const userIndex = users.findIndex(u => u.email === email);
      
      if (userIndex === -1) {
        throw new Error("User not found");
      }
      
      // Update user with new preferences
      users[userIndex] = {
        ...users[userIndex],
        transportPreference: profileData.transportPreference,
        safetyPreference: profileData.safetyPreference,
        emergencyContacts: profileData.emergencyContacts
      };
      
      await AsyncStorage.setItem('@mock_cognito_users', JSON.stringify(users));
      return { success: true, message: "Profile updated successfully" };
    } catch (error) {
      throw error;
    }
  },

  // Simulates: ML Safety Scoring Model (Bedrock / SageMaker)
  SafetyScoringFunction: (segmentData, timeOfDay, transportMode) => {
    // A mock heuristic model to simulate ML scoring
    let baseScore = (segmentData.crime_score * 0.5) + (segmentData.lighting_score * 0.3) + (segmentData.activity_score * 0.2);
    
    let riskFactors = [];
    if (segmentData.crime_score < 40) riskFactors.push("High historical crime");
    if (segmentData.lighting_score < 40) riskFactors.push("Poor lighting");
    if (segmentData.activity_score < 40) riskFactors.push("Isolated area");

    // Adjust for time of day (mock: night time reduces score)
    if (timeOfDay === 'night' && segmentData.lighting_score < 60) {
      baseScore -= 15;
      riskFactors.push("Night travel in poorly lit area");
    }

    // Adjust for transport mode
    if (transportMode === 'Walk' && segmentData.crime_score < 50) {
      baseScore -= 10;
      riskFactors.push("Walking in high crime area");
    }

    // Ensure score is clamped between 0 and 100
    const finalScore = Math.max(0, Math.min(100, Math.round(baseScore)));

    return {
      safety_score: finalScore,
      risk_factors: [...new Set(riskFactors)], // Deduplicate
      confidence: segmentData.confidence || 0.85
    };
  },

  // Simulates: GET /routes (Route Lambda -> Map Provider)
  getRoutes: async (origin, destination, mode, email) => {
    await new Promise(resolve => setTimeout(resolve, 800)); // Simulate routing engine delay

    // Fetch user profile to get safety preference (defaults to 0.5)
    let safetyPreference = 0.5;
    if (email) {
      try {
        const profile = await MockApi.getUserProfile(email);
        safetyPreference = profile.safetyPreference;
      } catch (e) {
        console.warn("Could not fetch profile for routing preference");
      }
    }

    // Fetch segments from mock DynamoDB
    const seg1 = await MockApi.getSafetySegment('seg_1');
    const seg2 = await MockApi.getSafetySegment('seg_2');
    const seg3 = await MockApi.getSafetySegment('seg_3');
    
    // Pass through Mock ML Scoring Model
    const timeOfDay = new Date().getHours() >= 18 || new Date().getHours() < 6 ? 'night' : 'day';
    
    let seg1Scored = MockApi.SafetyScoringFunction(seg1, timeOfDay, mode);
    let seg2Scored = MockApi.SafetyScoringFunction(seg2, timeOfDay, mode);
    let seg3Scored = MockApi.SafetyScoringFunction(seg3, timeOfDay, mode);

    // PHASE 14: Dynamic Hazard Avoidance
    // Fetch active crowdsourced hazards from DB
    try {
      const reportsStr = await AsyncStorage.getItem('@mock_reports');
      const reports = reportsStr ? JSON.parse(reportsStr) : [];
      
      if (reports.length > 0) {
        // Mock intersection logic: Pretend the hazard intersects with seg_2
        console.log(`[Lambda Mock] Detected ${reports.length} active hazards intersecting seg_2`);
        seg2Scored.safety_score = Math.max(0, seg2Scored.safety_score - 40); // Heavy Penalty
        seg2Scored.risk_factors.push("Active Crowdsourced Hazard");
      }
    } catch (e) {
      console.warn("Could not fetch hazards");
    }

    // Calculate average route safety scores
    const route1Safety = Math.round((seg1Scored.safety_score + seg2Scored.safety_score) / 2);
    const route2Safety = Math.round((seg1Scored.safety_score + seg3Scored.safety_score) / 2);

    // Create route array
    let routes = [
      {
        id: 'route_fastest',
        name: 'Fastest Route',
        distance: '5.2 km',
        eta_mins: 15, // numeric for sorting
        eta: '15 min',
        safety_score: route1Safety,
        risk_factors: [...new Set([...seg1Scored.risk_factors, ...seg2Scored.risk_factors])],
        geometry: [
          { latitude: 37.78825, longitude: -122.4324 },
          { latitude: 37.78925, longitude: -122.4334 },
          { latitude: 37.79025, longitude: -122.4344 }
        ],
        segments: [
          { id: 'seg_1', safety: seg1Scored },
          { id: 'seg_2', safety: seg2Scored }
        ]
      },
      {
        id: 'route_alternative',
        name: 'Safest Route',
        distance: '6.1 km',
        eta_mins: 18, // numeric for sorting
        eta: '18 min',
        safety_score: route2Safety,
        risk_factors: [...new Set([...seg1Scored.risk_factors, ...seg3Scored.risk_factors])],
        geometry: [
          { latitude: 37.78825, longitude: -122.4324 },
          { latitude: 37.78725, longitude: -122.4314 },
          { latitude: 37.79025, longitude: -122.4344 }
        ],
        segments: [
          { id: 'seg_1', safety: seg1Scored },
          { id: 'seg_3', safety: seg3Scored }
        ]
      }
    ];

    // SORTING ALGORITHM (Phase 11)
    // If preference > 0.5, sort by Highest Safety.
    // If preference <= 0.5, sort by Lowest ETA.
    if (safetyPreference > 0.5) {
      routes.sort((a, b) => b.safety_score - a.safety_score); // Descending safety
      // Rename top route for UI clarity
      routes[0].name += ' (Recommended Safe)';
    } else {
      routes.sort((a, b) => a.eta_mins - b.eta_mins); // Ascending time
      routes[0].name += ' (Recommended Fast)';
    }

    return routes;
  },

  // Simulates: GET /safety/segment/{segment_id}
  getSafetySegment: async (segmentId) => {
    await new Promise(resolve => setTimeout(resolve, 300));
    
    // We require the JSON file generated by our Phase 6 pipeline
    try {
      const processedData = require('../data/safety-navigation-data/processed/output.json');
      const segment = processedData.find(s => s.segment_id === segmentId);
      
      if (!segment) {
        throw new Error("Segment not found in database");
      }

      // Convert 0-1 densities from pipeline into 0-100 scores for the API
      // Inversely proportional for risks (high crime density = low safety score)
      const crime_score = Math.round((1 - segment.crime_density) * 100);
      const lighting_score = Math.round(segment.lighting_density * 100);
      const activity_score = Math.round(segment.activity_density * 100);

      // Add mock data for fields that require user feedback or ML (Phase 8+)
      return {
        segment_id: segment.segment_id,
        crime_score: crime_score,
        lighting_score: lighting_score,
        activity_score: activity_score,
        user_score: 90, // Mocked until user feedback is implemented
        emergency_proximity: 95, // Mocked
        confidence: 0.86 // Mocked
      };
    } catch (error) {
      throw new Error("DynamoDB Simulation Error: " + error.message);
    }
  },

  // Simulates: POST /sos (EventBridge Event Routing)
  triggerSOS: async (location, userEmail) => {
    await new Promise(resolve => setTimeout(resolve, 500));
    
    try {
      const usersStr = await AsyncStorage.getItem('@mock_cognito_users');
      const users = usersStr ? JSON.parse(usersStr) : [];
      const user = users.find(u => u.email === userEmail);
      
      const contacts = user?.emergencyContacts || [];
      const contactNames = contacts.map(c => c.name).join(', ') || 'No contacts configured';
      
      console.log(`[AWS EventBridge Mock] SOS Triggered by ${userEmail} at [${location.lat}, ${location.lng}]`);
      console.log(`[Amazon SNS Mock] Sending SMS to: ${contactNames}`);
      
      return { 
        success: true, 
        message: `SOS Sent to ${contactNames}`,
        event_id: `evt_${Date.now()}`
      };
    } catch (error) {
      throw error;
    }
  },

  // Simulates: GET /safe-havens?lat={lat}&lng={lng}
  getSafeHavens: async (lat, lng) => {
    await new Promise(resolve => setTimeout(resolve, 400));
    
    // Return dummy safe havens near the given coordinates
    return [
      {
        id: 'haven_1',
        name: 'Central Police Station',
        type: 'Police',
        geometry: { latitude: lat + 0.002, longitude: lng + 0.003 }
      },
      {
        id: 'haven_2',
        name: 'City General Hospital',
        type: 'Hospital',
        geometry: { latitude: lat - 0.003, longitude: lng - 0.001 }
      },
      {
        id: 'haven_3',
        name: '24/7 Pharmacy',
        type: 'Store',
        geometry: { latitude: lat + 0.001, longitude: lng - 0.004 }
      }
    ];
  },

  // Simulates: POST /report (Crowdsourcing Incident Report)
  submitReport: async (reportData) => {
    await new Promise(resolve => setTimeout(resolve, 600));
    
    try {
      const reportsStr = await AsyncStorage.getItem('@mock_reports');
      const reports = reportsStr ? JSON.parse(reportsStr) : [];
      
      const newReport = {
        id: `rep_${Date.now()}`,
        timestamp: new Date().toISOString(),
        ...reportData
      };
      
      reports.push(newReport);
      await AsyncStorage.setItem('@mock_reports', JSON.stringify(reports));
      
      console.log(`[DynamoDB Mock] Saved Report: ${JSON.stringify(newReport)}`);
      
      return { success: true, report_id: newReport.id };
    } catch (error) {
      throw error;
    }
  }
};
