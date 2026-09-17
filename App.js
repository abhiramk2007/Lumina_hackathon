import React, { useState, useEffect } from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { TouchableOpacity, Text, StyleSheet, View, ActivityIndicator } from 'react-native';

import { MockCognito } from './services/MockCognito';

import HomeScreen from './screens/HomeScreen';
import MapScreen from './screens/MapScreen';
import SOSScreen from './screens/SOSScreen';
import SafeHavenScreen from './screens/SafeHavenScreen';
import SettingsScreen from './screens/SettingsScreen';
import LoginScreen from './screens/LoginScreen';
import RegisterScreen from './screens/RegisterScreen';

const Stack = createNativeStackNavigator();

export default function App() {
  const [session, setSession] = useState(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const checkSession = async () => {
      const currentSession = await MockCognito.getSession();
      setSession(currentSession);
      setIsLoading(false);
    };
    checkSession();
  }, []);

  const handleLogout = async () => {
    await MockCognito.logout();
    setSession(null);
  };

  if (isLoading) {
    return (
      <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center' }}>
        <ActivityIndicator size="large" color="#007AFF" />
      </View>
    );
  }

  return (
    <NavigationContainer>
      <Stack.Navigator>
        {session == null ? (
          // Auth Stack
          <>
            <Stack.Screen 
              name="Login" 
              component={LoginScreen} 
              options={{ headerShown: false }}
              initialParams={{ setSession }}
            />
            <Stack.Screen 
              name="Register" 
              component={RegisterScreen} 
              options={{ headerShown: false }}
            />
          </>
        ) : (
          // Main App Stack
          <>
            <Stack.Screen 
              name="Home" 
              component={HomeScreen} 
              options={({ navigation }) => ({
                title: 'Safety Navigation',
                headerRight: () => (
                  <View style={styles.headerRightContainer}>
                    <TouchableOpacity onPress={() => navigation.navigate('Settings')}>
                      <Text style={styles.headerButton}>Settings</Text>
                    </TouchableOpacity>
                    <TouchableOpacity onPress={handleLogout}>
                      <Text style={[styles.headerButton, { color: '#FF3B30' }]}>Logout</Text>
                    </TouchableOpacity>
                  </View>
                ),
              })}
            />
            <Stack.Screen name="Map" component={MapScreen} options={{ title: 'Route Details' }} />
            <Stack.Screen name="SOS" component={SOSScreen} options={{ title: 'Emergency SOS' }} />
            <Stack.Screen name="SafeHaven" component={SafeHavenScreen} options={{ title: 'Safe Haven' }} />
            <Stack.Screen name="Settings" component={SettingsScreen} options={{ title: 'Settings' }} />
          </>
        )}
      </Stack.Navigator>
    </NavigationContainer>
  );
}

const styles = StyleSheet.create({
  headerRightContainer: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  headerButton: {
    color: '#007AFF',
    fontSize: 16,
    marginLeft: 15,
  }
});
