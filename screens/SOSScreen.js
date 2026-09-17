import React, { useState, useEffect, useRef } from 'react';
import { StyleSheet, Text, View, TouchableOpacity, ActivityIndicator } from 'react-native';
import { MockApi } from '../services/MockApi';
import { MockCognito } from '../services/MockCognito';

export default function SOSScreen({ navigation }) {
  const [status, setStatus] = useState('idle'); // idle, counting, sending, sent, error
  const [countdown, setCountdown] = useState(3);
  const [resultMessage, setResultMessage] = useState('');
  
  const timerRef = useRef(null);

  // Clean up timer on unmount
  useEffect(() => {
    return () => {
      if (timerRef.current) clearInterval(timerRef.current);
    };
  }, []);

  const startSOS = () => {
    setStatus('counting');
    setCountdown(3);

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

  const cancelSOS = () => {
    if (timerRef.current) clearInterval(timerRef.current);
    setStatus('idle');
    setCountdown(3);
  };

  const executeSOS = async () => {
    setStatus('sending');
    try {
      const session = await MockCognito.getSession();
      const email = session ? session.email : 'unknown_user';
      
      // Mock current location
      const currentLocation = { lat: 37.78825, lng: -122.4324 };
      
      const response = await MockApi.triggerSOS(currentLocation, email);
      
      setStatus('sent');
      setResultMessage(response.message);
    } catch (error) {
      setStatus('error');
      setResultMessage('Failed to send SOS: ' + error.message);
    }
  };

  const resetSOS = () => {
    setStatus('idle');
    setResultMessage('');
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Emergency SOS</Text>
      
      {status === 'idle' && (
        <>
          <Text style={styles.description}>
            Press the button below to instantly share your real-time location with your emergency contacts.
          </Text>
          
          <TouchableOpacity style={styles.sosButton} onPress={startSOS}>
            <Text style={styles.sosButtonText}>SOS</Text>
          </TouchableOpacity>
        </>
      )}

      {status === 'counting' && (
        <View style={styles.countdownContainer}>
          <Text style={styles.warningText}>SENDING SOS IN</Text>
          <Text style={styles.countdownNumber}>{countdown}</Text>
          
          <TouchableOpacity style={styles.cancelButton} onPress={cancelSOS}>
            <Text style={styles.cancelButtonText}>CANCEL</Text>
          </TouchableOpacity>
        </View>
      )}

      {status === 'sending' && (
        <View style={styles.statusContainer}>
          <ActivityIndicator size="large" color="#FF3B30" />
          <Text style={styles.statusText}>Sending Location via EventBridge...</Text>
        </View>
      )}

      {(status === 'sent' || status === 'error') && (
        <View style={styles.statusContainer}>
          <Text style={[styles.resultTitle, { color: status === 'sent' ? '#34C759' : '#FF3B30' }]}>
            {status === 'sent' ? 'SOS DISPATCHED' : 'ERROR'}
          </Text>
          <Text style={styles.resultMessage}>{resultMessage}</Text>
          
          <TouchableOpacity style={styles.resetButton} onPress={resetSOS}>
            <Text style={styles.resetButtonText}>Done</Text>
          </TouchableOpacity>
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, alignItems: 'center', justifyContent: 'center', padding: 20, backgroundColor: '#fff' },
  title: { fontSize: 28, fontWeight: 'bold', marginBottom: 20, color: '#333' },
  description: { fontSize: 16, textAlign: 'center', marginBottom: 50, color: '#666', paddingHorizontal: 20 },
  
  sosButton: {
    width: 200,
    height: 200,
    borderRadius: 100,
    backgroundColor: '#FF3B30',
    alignItems: 'center',
    justifyContent: 'center',
    shadowColor: '#FF3B30',
    shadowOffset: { width: 0, height: 10 },
    shadowOpacity: 0.5,
    shadowRadius: 15,
    elevation: 10,
  },
  sosButtonText: { color: '#fff', fontSize: 48, fontWeight: 'bold' },
  
  countdownContainer: { alignItems: 'center' },
  warningText: { fontSize: 24, fontWeight: 'bold', color: '#FF3B30', marginBottom: 10 },
  countdownNumber: { fontSize: 80, fontWeight: 'bold', color: '#333', marginBottom: 40 },
  
  cancelButton: {
    backgroundColor: '#333',
    paddingVertical: 15,
    paddingHorizontal: 40,
    borderRadius: 30,
  },
  cancelButtonText: { color: '#fff', fontSize: 18, fontWeight: 'bold' },
  
  statusContainer: { alignItems: 'center', padding: 20 },
  statusText: { fontSize: 18, color: '#666', marginTop: 20 },
  
  resultTitle: { fontSize: 24, fontWeight: 'bold', marginBottom: 10 },
  resultMessage: { fontSize: 16, textAlign: 'center', color: '#666', marginBottom: 30 },
  
  resetButton: {
    backgroundColor: '#007AFF',
    paddingVertical: 12,
    paddingHorizontal: 30,
    borderRadius: 8,
  },
  resetButtonText: { color: '#fff', fontSize: 16, fontWeight: 'bold' }
});
