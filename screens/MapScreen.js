import React from 'react';
import { StyleSheet, Text, View, Button } from 'react-native';

export default function MapScreen({ navigation }) {
  return (
    <View style={styles.container}>
      <Text style={styles.title}>Map Screen</Text>
      <Text style={styles.text}>Routing and Map will be coming in Phase 5</Text>
      <Button title="Go Back" onPress={() => navigation.goBack()} />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, justifyContent: 'center', alignItems: 'center', padding: 20 },
  title: { fontSize: 24, fontWeight: 'bold', marginBottom: 10 },
  text: { fontSize: 16, marginBottom: 20, textAlign: 'center' }
});
