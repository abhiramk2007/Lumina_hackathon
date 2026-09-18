import React, { useState, useEffect } from 'react';
import { StyleSheet, Text, View, ActivityIndicator, Platform, ScrollView, TouchableOpacity, Modal, Button, Vibration } from 'react-native';
import { MockApi } from '../services/MockApi';
import { MockCognito } from '../services/MockCognito';

// Safely import MapView to avoid crashing the web preview if not configured
let MapView, Polyline, Marker;
if (Platform.OS !== 'web') {
  const Maps = require('react-native-maps');
  MapView = Maps.default;
  Polyline = Maps.Polyline;
  Marker = Maps.Marker;
}

// Distance from point to line segment (simplified flat-earth distance for mock)
const distanceToSegment = (p, p1, p2) => {
  const A = p.latitude - p1.latitude;
  const B = p.longitude - p1.longitude;
  const C = p2.latitude - p1.latitude;
  const D = p2.longitude - p1.longitude;

  const dot = A * C + B * D;
  const len_sq = C * C + D * D;
  let param = -1;
  if (len_sq != 0) param = dot / len_sq;

  let xx, yy;
  if (param < 0) { xx = p1.latitude; yy = p1.longitude; }
  else if (param > 1) { xx = p2.latitude; yy = p2.longitude; }
  else { xx = p1.latitude + param * C; yy = p1.longitude + param * D; }

  const dx = p.latitude - xx;
  const dy = p.longitude - yy;
  return Math.sqrt(dx * dx + dy * dy);
};

export default function MapScreen({ route, navigation }) {
  const { origin, destination, transportMode, safetyPreference } = route.params || {};
  const [routes, setRoutes] = useState([]);
  const [safeHavens, setSafeHavens] = useState([]);
  const [loading, setLoading] = useState(true);

  // Phase 17: Navigation & Deviation
  const [isNavigating, setIsNavigating] = useState(false);
  const [currentLocation, setCurrentLocation] = useState(null);
  const [deviationState, setDeviationState] = useState('NORMAL');
  const [deviationModalVisible, setDeviationModalVisible] = useState(false);

  useEffect(() => {
    loadMapData();
  }, [origin, destination, transportMode, safetyPreference]);

  useEffect(() => {
    if (!isNavigating || !currentLocation || routes.length === 0) return;
    const primaryRoute = routes[0];
    if (!primaryRoute || !primaryRoute.geometry) return;

    let minDistance = Infinity;
    for (let i = 0; i < primaryRoute.geometry.length - 1; i++) {
      const p1 = primaryRoute.geometry[i];
      const p2 = primaryRoute.geometry[i+1];
      const dist = distanceToSegment(currentLocation, p1, p2);
      if (dist < minDistance) minDistance = dist;
    }

    const strictness = transportMode === 'Walk' ? 0.0005 : 0.0015;
    const significantThreshold = strictness * 2;

    if (minDistance > significantThreshold) {
      if (deviationState !== 'SIGNIFICANT') {
        setDeviationState('SIGNIFICANT');
        setDeviationModalVisible(true);
        Vibration.vibrate([0, 500, 200, 500]);
      }
    } else if (minDistance > strictness) {
      setDeviationState('MINOR');
    } else {
      setDeviationState('NORMAL');
    }
  }, [currentLocation, isNavigating, routes, transportMode, deviationState]);

  async function loadMapData() {
    setLoading(true);
    try {
      const session = await MockCognito.getSession();
      const email = session ? session.email : null;

      const fetchedRoutes = await MockApi.getRoutes(origin, destination, transportMode, email, safetyPreference);
      setRoutes(fetchedRoutes);
      
      if (fetchedRoutes.length > 0 && fetchedRoutes[0].geometry.length > 0) {
        const startCoord = fetchedRoutes[0].geometry[0];
        setSafeHavens(await MockApi.getSafeHavens(startCoord.latitude, startCoord.longitude));
        setCurrentLocation(startCoord); // Mock starting location
      }
    } catch (error) {
      console.error("Map Load Error:", error);
      alert("Error loading map data");
    } finally {
      setLoading(false);
    }
  }

  const startNavigation = () => {
    setIsNavigating(true);
    setDeviationState('NORMAL');
  };

  const handleSaferReroute = async () => {
    setDeviationModalVisible(false);
    setIsNavigating(false); // Reset to allow them to pick the new route
    
    // Call getRoutes but with high safetyPreference (1.0) and new "origin"
    const session = await MockCognito.getSession();
    const email = session ? session.email : null;
    setLoading(true);
    try {
      const reroutes = await MockApi.getRoutes("Deviated Location", destination, transportMode, email, 1.0);
      setRoutes(reroutes);
    } catch (e) {
      alert("Error finding safer route");
    } finally {
      setLoading(false);
    }
  };

  const handleSOS = async () => {
    try {
      const session = await MockCognito.getSession();
      const email = session ? session.email : 'anonymous';
      await MockApi.triggerSOS(currentLocation, email);
      alert("SOS Dispatched!");
      setDeviationModalVisible(false);
    } catch (e) {
      alert("Error sending SOS");
    }
  };

  // --- MOCK GPS DEV CONTROLS ---
  const simulateMovement = (type) => {
    if (!routes[0]) return;
    const base = routes[0].geometry[0];
    let newLoc;
    if (type === 'NORMAL') {
      newLoc = { latitude: base.latitude, longitude: base.longitude }; // Back on track
    } else if (type === 'MINOR') {
      const offset = transportMode === 'Walk' ? 0.0008 : 0.0025; 
      newLoc = { latitude: base.latitude + offset, longitude: base.longitude }; 
    } else if (type === 'SIGNIFICANT') {
      newLoc = { latitude: base.latitude + 0.015, longitude: base.longitude };
    }
    setCurrentLocation(newLoc);
  };

  const renderRouteDetails = () => (
    <View style={styles.detailsContainer}>
      <Text style={styles.detailsTitle}>Routing to {destination}</Text>
      
      {isNavigating && (
        <View style={styles.navBar}>
          <Text style={styles.navText}>Navigation Active</Text>
          {deviationState === 'MINOR' && <Text style={styles.minorWarning}>Minor Deviation Detected</Text>}
          {deviationState === 'SIGNIFICANT' && <Text style={styles.significantWarning}>SIGNIFICANT DEVIATION!</Text>}
        </View>
      )}

      {!isNavigating && routes.length > 0 && (
        <TouchableOpacity style={styles.startButton} onPress={startNavigation}>
          <Text style={styles.startButtonText}>START NAVIGATION</Text>
        </TouchableOpacity>
      )}
      
      <ScrollView style={styles.routesList}>
        {routes.map((r, index) => (
          <View key={r.id} style={[styles.routeCard, index === 0 ? styles.primaryRoute : styles.altRoute]}>
            <View style={styles.routeHeader}>
              <Text style={styles.routeName}>{r.name}</Text>
              <View style={[styles.safetyBadge, { backgroundColor: r.safety_score > 70 ? '#34C759' : r.safety_score > 40 ? '#FF9500' : '#FF3B30' }]}>
                <Text style={styles.safetyScoreText}>Safety: {r.safety_score}/100</Text>
              </View>
            </View>

            <View style={styles.routeStats}>
              <Text style={styles.routeStatText}>ETA: {r.eta}</Text>
            </View>

            {r.risk_factors && r.risk_factors.length > 0 && (
              <View style={styles.riskContainer}>
                {r.risk_factors.map((risk, i) => (
                  <Text key={i} style={styles.riskItem}>• {risk}</Text>
                ))}
              </View>
            )}
          </View>
        ))}
      </ScrollView>
    </View>
  );

  const renderDeviationModal = () => (
    <Modal animationType="slide" transparent={true} visible={deviationModalVisible}>
      <View style={styles.modalBg}>
        <View style={styles.modalContent}>
          <Text style={styles.modalTitle}>You're off your planned route.</Text>
          <Text style={styles.modalSub}>Did you take a wrong turn, or do you need help?</Text>
          
          <TouchableOpacity style={styles.modalBtnSafe} onPress={() => setDeviationModalVisible(false)}>
            <Text style={styles.btnTextSafe}>CONTINUE (I'M SAFE)</Text>
          </TouchableOpacity>
          
          <TouchableOpacity style={styles.modalBtnReroute} onPress={handleSaferReroute}>
            <Text style={styles.btnTextReroute}>FIND A SAFER ROUTE</Text>
          </TouchableOpacity>
          
          <TouchableOpacity style={styles.modalBtnSOS} onPress={handleSOS}>
            <Text style={styles.btnTextSOS}>SOS</Text>
          </TouchableOpacity>
        </View>
      </View>
    </Modal>
  );

  if (loading) {
    return (
      <View style={styles.centerContainer}>
        <ActivityIndicator size="large" color="#007AFF" />
      </View>
    );
  }

  return (
    <View style={styles.container}>
      {/* Dev Controls */}
      {isNavigating && (
        <View style={styles.devControls}>
          <Text style={{fontSize: 10, fontWeight: 'bold'}}>DEV GPS SPOOFER</Text>
          <Button title="Normal" onPress={() => simulateMovement('NORMAL')} />
          <Button title="Minor Dev" onPress={() => simulateMovement('MINOR')} />
          <Button title="Big Dev" onPress={() => simulateMovement('SIGNIFICANT')} />
        </View>
      )}

      {Platform.OS === 'web' ? (
        <View style={styles.webMapPlaceholder}>
          <Text style={styles.webMapText}>🗺️ MAP PREVIEW 🗺️</Text>
          {routes.map((r, i) => (
            <Text key={r.id} style={styles.webPolylineText}>Route {i+1} drawn</Text>
          ))}
          {currentLocation && isNavigating && (
             <Text style={{color: 'purple', fontWeight: 'bold', marginTop: 10}}>Current Pos: [{currentLocation.latitude.toFixed(4)}, {currentLocation.longitude.toFixed(4)}]</Text>
          )}
        </View>
      ) : (
        <MapView style={styles.map} initialRegion={{ latitude: 37.78825, longitude: -122.4324, latitudeDelta: 0.015, longitudeDelta: 0.0121 }}>
          {routes.map((r, index) => (
            <Polyline key={r.id} coordinates={r.geometry} strokeColor={index === 0 ? '#007AFF' : '#A9A9A9'} strokeWidth={4} />
          ))}
          {currentLocation && isNavigating && (
            <Marker coordinate={currentLocation} title="You are here" pinColor="purple" />
          )}
        </MapView>
      )}
      
      {renderRouteDetails()}
      {renderDeviationModal()}
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#f0f0f0' },
  centerContainer: { flex: 1, justifyContent: 'center', alignItems: 'center' },
  map: { flex: 1 },
  webMapPlaceholder: { flex: 1, backgroundColor: '#e1e4e8', justifyContent: 'center', alignItems: 'center' },
  webMapText: { fontSize: 24, fontWeight: 'bold', color: '#555', marginBottom: 10 },
  webPolylineText: { fontSize: 16, color: '#007AFF' },
  detailsContainer: { flex: 0.6, backgroundColor: '#fff', padding: 15, borderTopLeftRadius: 15, borderTopRightRadius: 15 },
  detailsTitle: { fontSize: 18, fontWeight: 'bold', marginBottom: 10 },
  startButton: { backgroundColor: '#34C759', padding: 15, borderRadius: 8, alignItems: 'center', marginBottom: 10 },
  startButtonText: { color: '#fff', fontWeight: 'bold', fontSize: 16 },
  navBar: { backgroundColor: '#f8f9fa', padding: 10, borderRadius: 8, marginBottom: 10, borderWidth: 1, borderColor: '#ccc' },
  navText: { fontWeight: 'bold', color: '#007AFF', textAlign: 'center' },
  minorWarning: { color: '#FF9500', fontWeight: 'bold', textAlign: 'center', marginTop: 5 },
  significantWarning: { color: '#FF3B30', fontWeight: 'bold', textAlign: 'center', marginTop: 5 },
  routesList: { flex: 1 },
  routeCard: { padding: 15, borderRadius: 8, borderWidth: 1, marginBottom: 10 },
  primaryRoute: { borderColor: '#007AFF', backgroundColor: '#f0f8ff' },
  altRoute: { borderColor: '#ccc', backgroundColor: '#f9f9f9' },
  routeName: { fontSize: 16, fontWeight: 'bold', marginBottom: 5 },
  routeHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 5 },
  safetyBadge: { paddingHorizontal: 8, paddingVertical: 4, borderRadius: 12 },
  safetyScoreText: { color: '#fff', fontSize: 12, fontWeight: 'bold' },
  routeStats: { flexDirection: 'row', justifyContent: 'space-between', marginBottom: 5 },
  routeStatText: { fontSize: 14, color: '#333' },
  riskContainer: { marginTop: 8, padding: 8, backgroundColor: '#fff3cd', borderRadius: 6 },
  riskItem: { fontSize: 12, color: '#856404', marginLeft: 5 },
  
  modalBg: { flex: 1, backgroundColor: 'rgba(0,0,0,0.5)', justifyContent: 'center', alignItems: 'center' },
  modalContent: { width: '85%', backgroundColor: '#fff', padding: 25, borderRadius: 15, alignItems: 'center' },
  modalTitle: { fontSize: 22, fontWeight: 'bold', color: '#FF3B30', textAlign: 'center', marginBottom: 10 },
  modalSub: { fontSize: 16, color: '#666', textAlign: 'center', marginBottom: 30 },
  modalBtnSafe: { backgroundColor: '#34C759', width: '100%', padding: 15, borderRadius: 8, alignItems: 'center', marginBottom: 10 },
  btnTextSafe: { color: '#fff', fontWeight: 'bold', fontSize: 16 },
  modalBtnReroute: { backgroundColor: '#007AFF', width: '100%', padding: 15, borderRadius: 8, alignItems: 'center', marginBottom: 10 },
  btnTextReroute: { color: '#fff', fontWeight: 'bold', fontSize: 16 },
  modalBtnSOS: { backgroundColor: '#FF3B30', width: '100%', padding: 15, borderRadius: 8, alignItems: 'center' },
  btnTextSOS: { color: '#fff', fontWeight: 'bold', fontSize: 16 },

  devControls: { position: 'absolute', top: 40, left: 10, zIndex: 1000, backgroundColor: 'rgba(255,255,255,0.9)', padding: 5, borderRadius: 8 }
});
