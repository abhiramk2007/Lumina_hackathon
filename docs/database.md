# Database Architecture (Amazon DynamoDB)

For this hackathon, we design our database to be NoSQL-friendly, minimizing the number of tables (Single-Table Design pattern where possible) to reduce costs and complexity.

## Table: `SafetyNav_Users`
Stores user profile information, preferences, and emergency contacts.

* **Partition Key (PK):** `userId` (String) - Typically the Cognito Sub UUID or Email.
* **Sort Key (SK):** Not required for basic user lookup.

### Entity Structure
```json
{
  "userId": "user@example.com",
  "createdAt": "2023-10-27T10:00:00Z",
  "transportPreference": "Car",
  "safetyPreference": 0.8,
  "emergencyContacts": [
    {
      "name": "Mom",
      "phone": "+1234567890",
      "relationship": "Parent"
    }
  ]
}
```

## Table: `SafetyNav_Routes` (Planned for later phases)
Stores processed road segment safety data and historical user feedback.

* **Partition Key (PK):** `segmentId` (String)
* **Sort Key (SK):** `dataType` (String) - E.g., `METADATA`, `FEEDBACK#<timestamp>`

*(Note: During development when AWS is inaccessible, these tables are simulated using React Native's `AsyncStorage` local persistence, matching the exact JSON structures planned above).*
