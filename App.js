import React from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { TouchableOpacity, Text, StyleSheet } from 'react-native';

import HomeScreen from './screens/HomeScreen';
import MapScreen from './screens/MapScreen';
import SOSScreen from './screens/SOSScreen';
import SafeHavenScreen from './screens/SafeHavenScreen';
import SettingsScreen from './screens/SettingsScreen';

const Stack = createNativeStackNavigator();

export default function App() {
  return (
    <NavigationContainer>
      <Stack.Navigator initialRouteName="Home">
        <Stack.Screen 
          name="Home" 
          component={HomeScreen} 
          options={({ navigation }) => ({
            title: 'Safety Navigation',
            headerRight: () => (
              <TouchableOpacity onPress={() => navigation.navigate('Settings')}>
                <Text style={styles.headerButton}>Settings</Text>
              </TouchableOpacity>
            ),
          })}
        />
        <Stack.Screen name="Map" component={MapScreen} options={{ title: 'Route Details' }} />
        <Stack.Screen name="SOS" component={SOSScreen} options={{ title: 'Emergency SOS' }} />
        <Stack.Screen name="SafeHaven" component={SafeHavenScreen} options={{ title: 'Safe Haven' }} />
        <Stack.Screen name="Settings" component={SettingsScreen} options={{ title: 'Settings' }} />
      </Stack.Navigator>
    </NavigationContainer>
  );
}

const styles = StyleSheet.create({
  headerButton: {
    color: '#007AFF',
    fontSize: 16,
    marginRight: 15,
  }
});
