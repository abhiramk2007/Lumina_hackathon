import React from 'react';
import { StyleSheet, Text, View, Button } from 'react-native';

export default function SafeHavenScreen({ navigation }) {
  return (
    <View style={[styles.container, { backgroundColor: '#e6f2ff' }]}>
      <Text style={[styles.title, { color: '#007AFF' }]}>Safe Haven</Text>
      <Text style={styles.text}>Coming in Phase 15 - Routing to nearest safe locations.</Text>
      <Button color="#007AFF" title="Go Back" onPress={() => navigation.goBack()} />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, justifyContent: 'center', alignItems: 'center', padding: 20 },
  title: { fontSize: 24, fontWeight: 'bold', marginBottom: 10 },
  text: { fontSize: 16, marginBottom: 20, textAlign: 'center' }
});
