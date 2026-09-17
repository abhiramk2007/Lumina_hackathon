import React, { useState, useEffect } from 'react';
import { StyleSheet, Text, View, ActivityIndicator, Platform, ScrollView } from 'react-native';
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

export default function MapScreen({ route, navigation }) {
  const { origin, destination, transportMode } = route.params || {};
  const [routes, setRoutes] = useState([]);
  const [safeHavens, setSafeHavens] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadMapData();
  }, [origin, destination, transportMode]);

  const loadMapData = async () => {
    setLoading(true);
    try {
      // Get current user to pass to routing engine for preference-based sorting
      const session = await MockCognito.getSession();
      const email = session ? session.email : null;

      const fetchedRoutes = await MockApi.getRoutes(origin, destination, transportMode, email);
      setRoutes(fetchedRoutes);
      
      // Load safe havens near the starting coordinate
      if (fetchedRoutes.length > 0 && fetchedRoutes[0].geometry.length > 0) {
        const startCoord = fetchedRoutes[0].geometry[0];
        const fetchedHavens = await MockApi.getSafeHavens(startCoord.latitude, startCoord.longitude);
        setSafeHavens(fetchedHavens);
      }
    } catch (error) {
      alert("Error loading map data");
    } finally {
      setLoading(false);
    }
  };

  const getHavenIcon = (type) => {
    if (type === 'Police') return '👮';
    if (type === 'Hospital') return '🏥';
    return '🏪'; // Store
  };

  const renderRouteDetails = () => (
    <View style={styles.detailsContainer}>
      <Text style={styles.detailsTitle}>Routing from {origin || 'Start'} to {destination}</Text>
      <Text style={styles.detailsSubtitle}>Mode: {transportMode}</Text>
      
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
              <Text style={styles.routeStatText}>Distance: {r.distance}</Text>
              <Text style={styles.routeStatText}>ETA: {r.eta}</Text>
            </View>

            {r.risk_factors && r.risk_factors.length > 0 && (
              <View style={styles.riskContainer}>
                <Text style={styles.riskTitle}>Risk Factors:</Text>
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

  if (loading) {
    return (
      <View style={styles.centerContainer}>
        <ActivityIndicator size="large" color="#007AFF" />
        <Text style={{ marginTop: 10 }}>Loading routes and safe havens...</Text>
      </View>
    );
  }

  // Web Fallback
  if (Platform.OS === 'web') {
    return (
      <View style={styles.container}>
        <View style={styles.webMapPlaceholder}>
          <Text style={styles.webMapText}>🗺️ MAP PREVIEW 🗺️</Text>
          <Text style={styles.webMapSubtext}>(Native MapView is disabled on Web preview)</Text>
          {routes.map((r, i) => (
            <Text key={r.id} style={styles.webPolylineText}>
              Route {i+1} drawn ({r.geometry.length} coordinates)
            </Text>
          ))}
          <Text style={styles.webHavenTitle}>Safe Havens Found:</Text>
          {safeHavens.map((h, i) => (
            <Text key={h.id} style={styles.webHavenText}>
              {getHavenIcon(h.type)} {h.name}
            </Text>
          ))}
        </View>
        {renderRouteDetails()}
      </View>
    );
  }

  // Native Mobile (iOS/Android)
  return (
    <View style={styles.container}>
      <MapView
        style={styles.map}
        initialRegion={{
          latitude: 37.78825,
          longitude: -122.4324,
          latitudeDelta: 0.015,
          longitudeDelta: 0.0121,
        }}
      >
        {routes.map((r, index) => (
          <Polyline
            key={r.id}
            coordinates={r.geometry}
            strokeColor={index === 0 ? '#007AFF' : '#A9A9A9'} // Blue for primary, Gray for alt
            strokeWidth={4}
          />
        ))}
        {safeHavens.map((h) => (
          <Marker
            key={h.id}
            coordinate={h.geometry}
            title={h.name}
            description={`Safe Haven Type: ${h.type}`}
          >
            <View style={styles.markerBadge}>
              <Text style={{fontSize: 20}}>{getHavenIcon(h.type)}</Text>
            </View>
          </Marker>
        ))}
      </MapView>
      {renderRouteDetails()}
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#f0f0f0' },
  centerContainer: { flex: 1, justifyContent: 'center', alignItems: 'center' },
  map: { flex: 1 },
  webMapPlaceholder: {
    flex: 1,
    backgroundColor: '#e1e4e8',
    justifyContent: 'center',
    alignItems: 'center',
    borderBottomWidth: 1,
    borderBottomColor: '#ccc',
  },
  webMapText: { fontSize: 24, fontWeight: 'bold', color: '#555' },
  webMapSubtext: { fontSize: 14, color: '#888', marginBottom: 20 },
  webPolylineText: { fontSize: 16, color: '#007AFF', marginVertical: 2 },
  webHavenTitle: { fontSize: 18, fontWeight: 'bold', color: '#333', marginTop: 15, marginBottom: 5 },
  webHavenText: { fontSize: 16, color: '#34C759', marginVertical: 2 },
  detailsContainer: {
    height: 250,
    backgroundColor: '#fff',
    padding: 15,
    borderTopLeftRadius: 15,
    borderTopRightRadius: 15,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: -2 },
    shadowOpacity: 0.1,
    shadowRadius: 5,
    elevation: 5,
  },
  detailsTitle: { fontSize: 18, fontWeight: 'bold' },
  detailsSubtitle: { fontSize: 14, color: '#666', marginBottom: 15 },
  routesList: { flex: 1 },
  routeCard: {
    padding: 15,
    borderRadius: 8,
    borderWidth: 1,
    marginBottom: 10,
  },
  primaryRoute: {
    borderColor: '#007AFF',
    backgroundColor: '#f0f8ff',
  },
  altRoute: {
    borderColor: '#ccc',
    backgroundColor: '#f9f9f9',
  },
  routeName: { fontSize: 16, fontWeight: 'bold', marginBottom: 5 },
  routeHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 5 },
  safetyBadge: { paddingHorizontal: 8, paddingVertical: 4, borderRadius: 12 },
  safetyScoreText: { color: '#fff', fontSize: 12, fontWeight: 'bold' },
  routeStats: { flexDirection: 'row', justifyContent: 'space-between', marginBottom: 5 },
  routeStatText: { fontSize: 14, color: '#333' },
  riskContainer: { marginTop: 8, padding: 8, backgroundColor: '#fff3cd', borderRadius: 6 },
  riskTitle: { fontSize: 12, fontWeight: 'bold', color: '#856404', marginBottom: 4 },
  riskItem: { fontSize: 12, color: '#856404', marginLeft: 5 },
  markerBadge: { backgroundColor: '#fff', padding: 4, borderRadius: 15, borderWidth: 1, borderColor: '#34C759' }
});
