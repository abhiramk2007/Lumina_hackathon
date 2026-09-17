import React from 'react';
import { StyleSheet, Text, View, Button } from 'react-native';

export default function SOSScreen({ navigation }) {
  return (
    <View style={[styles.container, { backgroundColor: '#ffebe9' }]}>
      <Text style={[styles.title, { color: '#FF3B30' }]}>SOS System</Text>
      <Text style={styles.text}>Coming in Phase 14 - Emergency architecture will be integrated here.</Text>
      <Button color="#FF3B30" title="Go Back" onPress={() => navigation.goBack()} />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, justifyContent: 'center', alignItems: 'center', padding: 20 },
  title: { fontSize: 24, fontWeight: 'bold', marginBottom: 10 },
  text: { fontSize: 16, marginBottom: 20, textAlign: 'center' }
});
