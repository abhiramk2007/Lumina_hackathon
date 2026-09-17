import React, { useState } from 'react';
import { StyleSheet, Text, View, TextInput, TouchableOpacity, ScrollView } from 'react-native';
import Slider from '@react-native-community/slider';

export default function HomeScreen({ navigation }) {
  const [destination, setDestination] = useState('');
  const [transportMode, setTransportMode] = useState('Car');
  const [safetyPreference, setSafetyPreference] = useState(0.5);

  const transportModes = ['Walk', 'Bicycle', '2-Wheeler', 'Car', 'Transit'];

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.contentContainer}>
      <Text style={styles.header}>SAFETY NAVIGATION</Text>
      
      <View style={styles.section}>
        <Text style={styles.label}>From:</Text>
        <Text style={styles.currentLocation}>Current Location</Text>
      </View>

      <View style={styles.section}>
        <Text style={styles.label}>To:</Text>
        <TextInput 
          style={styles.input} 
          placeholder="Search destination" 
          value={destination}
          onChangeText={setDestination}
        />
      </View>

      <View style={styles.section}>
        <Text style={styles.label}>Transportation:</Text>
        <View style={styles.modesContainer}>
          {transportModes.map(mode => (
            <TouchableOpacity 
              key={mode} 
              style={[styles.modeButton, transportMode === mode && styles.modeButtonActive]}
              onPress={() => setTransportMode(mode)}
            >
              <Text style={[styles.modeText, transportMode === mode && styles.modeTextActive]}>{mode}</Text>
            </TouchableOpacity>
          ))}
        </View>
      </View>

      <View style={styles.section}>
        <Text style={styles.label}>Safety Preference:</Text>
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

      <TouchableOpacity 
        style={styles.findRouteButton} 
        onPress={() => navigation.navigate('Map', { 
          origin: 'Current Location', 
          destination: destination || 'Unknown Destination', 
          transportMode 
        })}
      >
        <Text style={styles.findRouteText}>FIND ROUTE</Text>
      </TouchableOpacity>

      <View style={styles.emergencyContainer}>
        <TouchableOpacity 
          style={[styles.actionButton, styles.sosButton]} 
          onPress={() => navigation.navigate('SOS')}
        >
          <Text style={styles.actionButtonText}>SOS</Text>
        </TouchableOpacity>
        
        <TouchableOpacity 
          style={[styles.actionButton, styles.reportButton]} 
          onPress={() => navigation.navigate('Report')}
        >
          <Text style={styles.actionButtonText}>Report Hazard</Text>
        </TouchableOpacity>

        <TouchableOpacity 
          style={[styles.actionButton, styles.safeHavenButton]} 
          onPress={() => navigation.navigate('SafeHaven')}
        >
          <Text style={styles.actionButtonText}>SAFE HAVEN</Text>
        </TouchableOpacity>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
  },
  contentContainer: {
    padding: 20,
    paddingBottom: 40,
  },
  header: {
    fontSize: 24,
    fontWeight: 'bold',
    marginBottom: 20,
    textAlign: 'center',
  },
  section: {
    marginBottom: 20,
  },
  label: {
    fontSize: 16,
    fontWeight: 'bold',
    marginBottom: 8,
  },
  currentLocation: {
    fontSize: 16,
    color: '#007AFF',
    padding: 12,
    backgroundColor: '#f0f8ff',
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#b0d4ff',
  },
  input: {
    borderWidth: 1,
    borderColor: '#ccc',
    borderRadius: 8,
    padding: 12,
    fontSize: 16,
  },
  modesContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
  },
  modeButton: {
    paddingVertical: 8,
    paddingHorizontal: 12,
    borderWidth: 1,
    borderColor: '#ccc',
    borderRadius: 20,
    marginBottom: 8,
  },
  modeButtonActive: {
    backgroundColor: '#007AFF',
    borderColor: '#007AFF',
  },
  modeText: {
    fontSize: 14,
    color: '#333',
  },
  modeTextActive: {
    color: '#fff',
    fontWeight: 'bold',
  },
  sliderLabels: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingHorizontal: 10,
  },
  sliderLabel: {
    fontSize: 12,
    color: '#666',
    fontWeight: 'bold',
  },
  slider: {
    width: '100%',
    height: 40,
  },
  findRouteButton: {
    backgroundColor: '#34C759',
    padding: 15,
    borderRadius: 8,
    alignItems: 'center',
    marginTop: 10,
    marginBottom: 30,
  },
  findRouteText: {
    color: '#fff',
    fontSize: 18,
    fontWeight: 'bold',
  },
  emergencyContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    gap: 10,
  },
  actionButton: {
    flex: 1,
    padding: 15,
    borderRadius: 8,
    alignItems: 'center',
  },
  sosButton: {
    backgroundColor: '#FF3B30',
  },
  reportButton: {
    backgroundColor: '#FF9500',
  },
  safeHavenButton: {
    backgroundColor: '#007AFF',
  },
  actionButtonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: 'bold',
    textAlign: 'center',
  }
});
