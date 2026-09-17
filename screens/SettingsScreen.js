import React, { useState, useEffect } from 'react';
import { StyleSheet, Text, View, Button, ActivityIndicator, TextInput, ScrollView } from 'react-native';
import Slider from '@react-native-community/slider';
import { MockApi } from '../services/MockApi';
import { MockCognito } from '../services/MockCognito';

export default function SettingsScreen({ navigation }) {
  const [email, setEmail] = useState('');
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  
  // Phase 7 API Test State
  const [testSegmentId, setTestSegmentId] = useState('seg_1');
  const [testingApi, setTestingApi] = useState(false);
  const [safetyApiResult, setSafetyApiResult] = useState(null);
  
  // Profile Data
  const [transportPreference, setTransportPreference] = useState('Car');
  const [safetyPreference, setSafetyPreference] = useState(0.5);
  const [emergencyContactName, setEmergencyContactName] = useState('');
  const [emergencyContactPhone, setEmergencyContactPhone] = useState('');

  useEffect(() => {
    loadProfile();
  }, []);

  const testSafetyApi = async () => {
    if (!testSegmentId) {
      alert('Please enter a segment ID');
      return;
    }
    setTestingApi(true);
    try {
      const response = await MockApi.getSafetySegment(testSegmentId);
      setSafetyApiResult(JSON.stringify(response, null, 2));
    } catch (error) {
      setSafetyApiResult(error.message);
    } finally {
      setTestingApi(false);
    }
  };

  const loadProfile = async () => {
    setLoading(true);
    try {
      const session = await MockCognito.getSession();
      if (!session) {
        alert("Not logged in");
        return;
      }
      setEmail(session.email);
      
      const profile = await MockApi.getUserProfile(session.email);
      setTransportPreference(profile.transportPreference);
      setSafetyPreference(profile.safetyPreference);
      
      if (profile.emergencyContacts && profile.emergencyContacts.length > 0) {
        setEmergencyContactName(profile.emergencyContacts[0].name || '');
        setEmergencyContactPhone(profile.emergencyContacts[0].phone || '');
      }
    } catch (error) {
      alert('Error loading profile: ' + error.message);
    } finally {
      setLoading(false);
    }
  };

  const saveProfile = async () => {
    setSaving(true);
    try {
      const profileData = {
        transportPreference,
        safetyPreference,
        emergencyContacts: [
          { name: emergencyContactName, phone: emergencyContactPhone }
        ]
      };
      
      await MockApi.putUserProfile(email, profileData);
      alert('Profile saved successfully!');
    } catch (error) {
      alert('Error saving profile: ' + error.message);
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return (
      <View style={[styles.container, { justifyContent: 'center' }]}>
        <ActivityIndicator size="large" color="#007AFF" />
      </View>
    );
  }

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.contentContainer}>
      <Text style={styles.title}>User Profile</Text>
      <Text style={styles.emailText}>Logged in as: {email}</Text>
      
      <View style={styles.section}>
        <Text style={styles.label}>Default Transportation:</Text>
        <TextInput 
          style={styles.input} 
          value={transportPreference} 
          onChangeText={setTransportPreference}
          placeholder="e.g. Car, Walk, Bicycle"
        />
      </View>

      <View style={styles.section}>
        <Text style={styles.label}>Default Safety Preference:</Text>
        <View style={styles.sliderLabels}>
          <Text style={styles.sliderLabel}>FAST</Text>
          <Text style={styles.sliderLabel}>SAFE</Text>
        </View>
        <Slider
          style={styles.slider}
          minimumValue={0}
          maximumValue={1}
          value={safetyPreference}
          onValueChange={setSafetyPreference}
          minimumTrackTintColor="#007AFF"
          maximumTrackTintColor="#d3d3d3"
        />
      </View>

      <View style={styles.section}>
        <Text style={styles.label}>Emergency Contact:</Text>
        <TextInput 
          style={styles.input} 
          value={emergencyContactName} 
          onChangeText={setEmergencyContactName}
          placeholder="Contact Name (e.g., Mom)"
        />
        <TextInput 
          style={[styles.input, { marginTop: 10 }]} 
          value={emergencyContactPhone} 
          onChangeText={setEmergencyContactPhone}
          placeholder="Phone Number"
          keyboardType="phone-pad"
        />
      </View>

      <Button title={saving ? "Saving..." : "Save Profile"} onPress={saveProfile} color="#34C759" disabled={saving} />
      
      <View style={styles.spacer} />

      <View style={styles.apiTestContainer}>
        <Text style={styles.subtitle}>Safety Database Test (Phase 7)</Text>
        <TextInput 
          style={[styles.input, { width: '100%', backgroundColor: '#fff', marginBottom: 10 }]} 
          value={testSegmentId} 
          onChangeText={setTestSegmentId}
          placeholder="Enter segment_id (e.g., seg_1)"
        />
        <Button title="Test GET /safety/segment" onPress={testSafetyApi} color="#007AFF" />
        
        {testingApi && <ActivityIndicator style={{ marginTop: 10 }} />}
        
        {safetyApiResult && (
          <View style={styles.responseBox}>
            <Text style={styles.responseText}>{safetyApiResult}</Text>
          </View>
        )}
      </View>

      <View style={styles.spacer} />
      <Button title="Go Back" onPress={() => navigation.goBack()} />
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#f8f9fa' },
  contentContainer: { padding: 20 },
  title: { fontSize: 24, fontWeight: 'bold', marginBottom: 5 },
  emailText: { fontSize: 14, color: '#666', marginBottom: 20 },
  section: { marginBottom: 25 },
  label: { fontSize: 16, fontWeight: 'bold', marginBottom: 8 },
  input: { borderWidth: 1, borderColor: '#ccc', borderRadius: 8, padding: 12, fontSize: 16, backgroundColor: '#fff' },
  sliderLabels: { flexDirection: 'row', justifyContent: 'space-between', paddingHorizontal: 10 },
  sliderLabel: { fontSize: 12, color: '#666', fontWeight: 'bold' },
  slider: { width: '100%', height: 40 },
  spacer: { height: 20 },
  apiTestContainer: { 
    width: '100%', 
    padding: 15, 
    backgroundColor: '#e9ecef', 
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#ced4da',
    alignItems: 'center'
  },
  subtitle: { fontSize: 16, fontWeight: 'bold', marginBottom: 10 },
  responseBox: {
    marginTop: 15,
    padding: 10,
    backgroundColor: '#282c34',
    borderRadius: 6,
    width: '100%',
  },
  responseText: {
    color: '#61dafb',
    fontFamily: 'monospace',
    fontSize: 12,
  }
});
