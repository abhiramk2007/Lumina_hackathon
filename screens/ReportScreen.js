import React, { useState } from 'react';
import { StyleSheet, Text, View, TextInput, TouchableOpacity, ActivityIndicator } from 'react-native';
import { MockApi } from '../services/MockApi';
import { MockCognito } from '../services/MockCognito';

export default function ReportScreen({ navigation }) {
  const [selectedCategories, setSelectedCategories] = useState([]);
  const [description, setDescription] = useState('');
  const [submitting, setSubmitting] = useState(false);

  const categories = ['Poor lighting', 'Suspicious activity', 'Road hazard'];

  const toggleCategory = (cat) => {
    setSelectedCategories(prev => 
      prev.includes(cat) ? prev.filter(item => item !== cat) : [...prev, cat]
    );
  };

  const handleSubmit = async () => {
    if (selectedCategories.length === 0) {
      alert("Please select at least one category");
      return;
    }

    setSubmitting(true);
    try {
      const session = await MockCognito.getSession();
      const email = session ? session.email : 'anonymous';
      
      const reportData = {
        categories: selectedCategories,
        description,
        email,
        location: { lat: 37.78825, lng: -122.4324 } // Mock current location
      };

      await MockApi.submitReport(reportData);
      
      alert("Report submitted successfully! Thank you for keeping the community safe.");
      navigation.goBack();
    } catch (error) {
      alert("Failed to submit report: " + error.message);
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Report Hazard</Text>
      <Text style={styles.subtitle}>Help others by reporting safety concerns in your current area.</Text>

      <Text style={styles.label}>Select Category:</Text>
      <View style={styles.categoryContainer}>
        {categories.map(cat => (
          <TouchableOpacity 
            key={cat} 
            style={[styles.categoryButton, selectedCategories.includes(cat) && styles.categorySelected]}
            onPress={() => toggleCategory(cat)}
          >
            <Text style={[styles.categoryText, selectedCategories.includes(cat) && styles.categoryTextSelected]}>
              {cat}
            </Text>
          </TouchableOpacity>
        ))}
      </View>

      <Text style={styles.label}>Description (Optional):</Text>
      <TextInput
        style={styles.input}
        multiline
        numberOfLines={4}
        placeholder="Provide additional details..."
        value={description}
        onChangeText={setDescription}
      />

      <TouchableOpacity 
        style={styles.submitButton} 
        onPress={handleSubmit}
        disabled={submitting}
      >
        {submitting ? (
          <ActivityIndicator color="#fff" />
        ) : (
          <Text style={styles.submitButtonText}>SUBMIT REPORT</Text>
        )}
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, padding: 20, backgroundColor: '#fff' },
  title: { fontSize: 28, fontWeight: 'bold', marginBottom: 10, color: '#333' },
  subtitle: { fontSize: 16, color: '#666', marginBottom: 30 },
  label: { fontSize: 16, fontWeight: 'bold', marginBottom: 10, color: '#333' },
  categoryContainer: { flexDirection: 'row', flexWrap: 'wrap', marginBottom: 20 },
  categoryButton: {
    paddingHorizontal: 15,
    paddingVertical: 10,
    borderRadius: 20,
    borderWidth: 1,
    borderColor: '#007AFF',
    marginRight: 10,
    marginBottom: 10,
  },
  categorySelected: {
    backgroundColor: '#007AFF',
  },
  categoryText: {
    color: '#007AFF',
    fontWeight: 'bold',
  },
  categoryTextSelected: {
    color: '#fff',
  },
  input: {
    borderWidth: 1,
    borderColor: '#ccc',
    borderRadius: 8,
    padding: 15,
    fontSize: 16,
    height: 100,
    textAlignVertical: 'top',
    marginBottom: 30,
  },
  submitButton: {
    backgroundColor: '#34C759',
    padding: 15,
    borderRadius: 8,
    alignItems: 'center',
  },
  submitButtonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: 'bold',
  }
});
