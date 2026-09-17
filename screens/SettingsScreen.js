import React from 'react';
import { StyleSheet, Text, View, Button } from 'react-native';

export default function SettingsScreen({ navigation }) {
  return (
    <View style={styles.container}>
      <Text style={styles.title}>Settings</Text>
      <Text style={styles.text}>Coming in later phases...</Text>
      <Button title="Go Back" onPress={() => navigation.goBack()} />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, justifyContent: 'center', alignItems: 'center', padding: 20 },
  title: { fontSize: 24, fontWeight: 'bold', marginBottom: 10 },
  text: { fontSize: 16, marginBottom: 20, textAlign: 'center' }
});
