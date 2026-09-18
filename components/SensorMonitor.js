import React, { useState, useEffect, useRef } from 'react';
import { StyleSheet, Text, View, Modal, TouchableOpacity, ActivityIndicator, Platform } from 'react-native';
import { Accelerometer } from 'expo-sensors';
import { MockApi } from '../services/MockApi';
import { MockCognito } from '../services/MockCognito';
import AsyncStorage from '@react-native-async-storage/async-storage';

// Threshold for physical disturbance (G-Force vector length)
const DISTURBANCE_THRESHOLD = 2.5; 

export default function SensorMonitor({ children }) {
  const [monitoringEnabled, setMonitoringEnabled] = useState(false);
  const [modalVisible, setModalVisible] = useState(false);
  const [countdown, setCountdown] = useState(10);
  const [status, setStatus] = useState('idle'); // idle, counting, sending, sent, error
  const [resultMessage, setResultMessage] = useState('');
  const [currentUser, setCurrentUser] = useState(null);

  const subscription = useRef(null);
  const timerRef = useRef(null);
  const settingsInterval = useRef(null);

  useEffect(() => {
    // Check if sensors are available (Web doesn't support them out of the box without permissions, but Expo handles it gracefully usually, or we can just mock it)
    if (Platform.OS !== 'web') {
      Accelerometer.isAvailableAsync().then(available => {
        if (!available) console.warn("Accelerometer is not available on this device.");
      });
    }

    // Periodically check if the user is logged in and has monitoring enabled
    const checkSettings = async () => {
      try {
        const session = await MockCognito.getSession();
        if (session && session.email) {
          setCurrentUser(session.email);
          const profile = await MockApi.getUserProfile(session.email);
          const isEnabled = profile.disturbanceDetection !== false; // default true
          setMonitoringEnabled(isEnabled);
        } else {
          setMonitoringEnabled(false);
        }
      } catch (e) {
        setMonitoringEnabled(false);
      }
    };

    checkSettings();
    settingsInterval.current = setInterval(checkSettings, 5000);

    return () => {
      if (settingsInterval.current) clearInterval(settingsInterval.current);
      unsubscribeSensor();
    };
  }, []);

  useEffect(() => {
    if (monitoringEnabled && Platform.OS !== 'web' && status === 'idle' && !modalVisible) {
      subscribeSensor();
    } else {
      unsubscribeSensor();
    }
    return () => unsubscribeSensor();
  }, [monitoringEnabled, status, modalVisible]);

  const subscribeSensor = () => {
    if (subscription.current) return;
    
    Accelerometer.setUpdateInterval(500); // Check twice a second
    subscription.current = Accelerometer.addListener(accelerometerData => {
      const { x, y, z } = accelerometerData;
      // Calculate total G-Force vector length
      const gForce = Math.sqrt(x * x + y * y + z * z);
      
      if (gForce > DISTURBANCE_THRESHOLD) {
        console.log(`[SensorMonitor] High G-Force detected: ${gForce.toFixed(2)}G`);
        handleDisturbance();
      }
    });
  };

  const unsubscribeSensor = () => {
    if (subscription.current) {
      subscription.current.remove();
      subscription.current = null;
    }
  };

  const handleDisturbance = () => {
    unsubscribeSensor();
    setModalVisible(true);
    setStatus('counting');
    setCountdown(10);

    timerRef.current = setInterval(() => {
      setCountdown((prev) => {
        if (prev <= 1) {
          clearInterval(timerRef.current);
          executeSOS();
          return 0;
        }
        return prev - 1;
      });
    }, 1000);
  };

  const cancelAlert = () => {
    if (timerRef.current) clearInterval(timerRef.current);
    setStatus('idle');
    setModalVisible(false);
    
    // Resume monitoring after a short delay to prevent instant re-trigger
    setTimeout(() => {
      if (monitoringEnabled) subscribeSensor();
    }, 2000);
  };

  const executeSOS = async () => {
    if (timerRef.current) clearInterval(timerRef.current);
    setStatus('sending');
    try {
      const email = currentUser || 'anonymous';
      const location = { lat: 37.78825, lng: -122.4324 }; // Mock location
      const response = await MockApi.triggerSOS(location, email);
      
      setStatus('sent');
      setResultMessage(response.message);
    } catch (error) {
      setStatus('error');
      setResultMessage('Failed to send SOS: ' + error.message);
    }
  };

  const closeResult = () => {
    setStatus('idle');
    setModalVisible(false);
    setTimeout(() => {
      if (monitoringEnabled) subscribeSensor();
    }, 2000);
  };

  return (
    <View style={styles.container}>
      {children}

      {/* Web fallback for testing sensor since Accelerometer isn't available */}
      {Platform.OS === 'web' && monitoringEnabled && status === 'idle' && !modalVisible && (
        <TouchableOpacity 
          style={styles.devButton} 
          onPress={handleDisturbance}
        >
          <Text style={styles.devButtonText}>[DEV] Simulate Shake</Text>
        </TouchableOpacity>
      )}

      <Modal
        animationType="slide"
        transparent={false}
        visible={modalVisible}
        onRequestClose={() => {}} // Disable physical back button to prevent accidental closure
      >
        <View style={styles.modalContainer}>
          {status === 'counting' && (
            <>
              <Text style={styles.warningTitle}>Unusual Movement Detected!</Text>
              <Text style={styles.warningSubtitle}>Are you okay?</Text>
              
              <View style={styles.countdownBox}>
                <Text style={styles.countdownNumber}>{countdown}</Text>
                <Text style={styles.countdownText}>seconds until automatic SOS dispatch</Text>
              </View>

              <TouchableOpacity style={styles.safeButton} onPress={cancelAlert}>
                <Text style={styles.safeButtonText}>I'M SAFE</Text>
              </TouchableOpacity>

              <TouchableOpacity style={styles.sosButton} onPress={executeSOS}>
                <Text style={styles.sosButtonText}>SEND SOS NOW</Text>
              </TouchableOpacity>
            </>
          )}

          {status === 'sending' && (
            <View style={styles.resultBox}>
              <ActivityIndicator size="large" color="#FF3B30" />
              <Text style={styles.statusText}>Dispatching Emergency Alert...</Text>
            </View>
          )}

          {(status === 'sent' || status === 'error') && (
            <View style={styles.resultBox}>
              <Text style={[styles.resultTitle, { color: status === 'sent' ? '#34C759' : '#FF3B30' }]}>
                {status === 'sent' ? 'SOS DISPATCHED' : 'ERROR'}
              </Text>
              <Text style={styles.resultMessage}>{resultMessage}</Text>
              
              <TouchableOpacity style={styles.dismissButton} onPress={closeResult}>
                <Text style={styles.dismissButtonText}>Acknowledge</Text>
              </TouchableOpacity>
            </View>
          )}
        </View>
      </Modal>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  modalContainer: {
    flex: 1,
    backgroundColor: '#fff',
    justifyContent: 'center',
    alignItems: 'center',
    padding: 20,
  },
  warningTitle: { fontSize: 28, fontWeight: 'bold', color: '#FF3B30', textAlign: 'center', marginBottom: 10 },
  warningSubtitle: { fontSize: 20, color: '#333', marginBottom: 40 },
  countdownBox: { alignItems: 'center', marginBottom: 50 },
  countdownNumber: { fontSize: 100, fontWeight: 'bold', color: '#333' },
  countdownText: { fontSize: 16, color: '#666', marginTop: -10 },
  
  safeButton: { backgroundColor: '#34C759', paddingVertical: 18, paddingHorizontal: 60, borderRadius: 30, marginBottom: 20, width: '90%', alignItems: 'center' },
  safeButtonText: { color: '#fff', fontSize: 24, fontWeight: 'bold' },
  
  sosButton: { backgroundColor: '#FF3B30', paddingVertical: 18, paddingHorizontal: 60, borderRadius: 30, width: '90%', alignItems: 'center' },
  sosButtonText: { color: '#fff', fontSize: 20, fontWeight: 'bold' },
  
  resultBox: { alignItems: 'center', padding: 20 },
  statusText: { fontSize: 20, color: '#666', marginTop: 20 },
  resultTitle: { fontSize: 28, fontWeight: 'bold', marginBottom: 15 },
  resultMessage: { fontSize: 18, textAlign: 'center', color: '#666', marginBottom: 40 },
  dismissButton: { backgroundColor: '#007AFF', paddingVertical: 15, paddingHorizontal: 40, borderRadius: 10 },
  dismissButtonText: { color: '#fff', fontSize: 18, fontWeight: 'bold' },

  devButton: {
    position: 'absolute',
    top: 50,
    right: 20,
    backgroundColor: 'rgba(255, 149, 0, 0.8)',
    padding: 10,
    borderRadius: 8,
    zIndex: 1000,
  },
  devButtonText: { color: '#fff', fontWeight: 'bold', fontSize: 12 }
});
