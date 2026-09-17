# 🌟 Lumina: Intelligent Safety Navigation

**Lumina** is a crowdsourced, ML-powered safety navigation app designed to ensure pedestrians and commuters can find the absolute safest routes to their destinations, especially at night or in unfamiliar areas.

## 🏆 The Problem
Standard navigation apps prioritize speed and distance. They do not account for environmental safety factors like poor street lighting, historical crime rates, or isolation. Lumina changes the paradigm by introducing **Safety First Routing**, crowdsourced hazard reporting, and instant SOS dispatching.

## 🚀 Key Features

* **🧠 ML Safety Scoring Model**: Analyzes route segments based on historical crime data, lighting density, and crowd activity levels to assign a 0-100 Safety Score to every path.
* **🗺️ Dynamic Rerouting**: Actively scans for crowdsourced hazards (e.g., suspicious activity, broken streetlights) and dynamically penalizes dangerous routes, instantly offering a safe alternative.
* **🚨 EventBridge SOS Dispatch**: A 3-second countdown SOS button that instantly routes your live GPS coordinates to your emergency contacts via SMS and Email.
* **🏥 Safe Haven Tracking**: Automatically scans your route for verified 24/7 safe havens (Hospitals, Police Stations, 24/7 Stores) and drops distinct markers on your map.
* **🗣️ Community Reporting**: Keep your neighborhood safe by submitting real-time reports of road hazards or suspicious activities.

---

## 🏗️ AWS Cloud Architecture (Target State)
Lumina is designed to be fully cloud-native, utilizing a robust suite of Amazon Web Services:

* **Amazon API Gateway**: Acts as the front door for all mobile client requests (Routing, Reporting, Safe Havens).
* **Amazon Cognito**: Handles secure user authentication, registration, and session management.
* **AWS Lambda**: Serverless compute executing the Route Optimization and ML Scoring algorithms.
* **Amazon DynamoDB**: NoSQL database storing User Profiles, Emergency Contacts, Processed Safety Segments, and real-time Crowdsourced Hazards.
* **Amazon S3**: Data lake storing massive datasets of raw historical crime and lighting data.
* **Amazon SageMaker / Bedrock**: Ingests the raw data to train and deploy the predictive safety scoring model.
* **Amazon EventBridge & SNS**: Event-driven architecture that listens for SOS triggers and instantly broadcasts SMS/Email alerts to emergency contacts.

---

## 🛠️ The "Mock-AWS" Local Environment
*Due to AWS account verification holds during the hackathon, this project currently runs using a robust local simulation of the AWS Cloud environment.*

All AWS services have been meticulously mocked in the `services/` directory to demonstrate full functional logic without requiring active cloud credentials:

1. **`MockCognito.js`**: Simulates AWS Cognito by handling JWT-style session states and user registration using React Native's `AsyncStorage`.
2. **`MockApi.js` (API Gateway + Lambda)**: Intercepts API calls, simulates network latency, and executes the heavy-lifting logic (like sorting route arrays based on preference).
3. **`AsyncStorage` (DynamoDB)**: Acts as the NoSQL database for persisting user settings, emergency contacts, and crowdsourced reports.
4. **`preprocess.js` (S3 + SageMaker)**: A Node.js data pipeline that ingests raw JSON datasets and outputs normalized safety densities.
5. **Console Logging (EventBridge + SNS)**: When an SOS is triggered, the event routing and SMS delivery receipts are logged directly to the local terminal to prove decoupled execution.

---

## 💻 How to Run Locally

### Prerequisites
* Node.js (v18+)
* Expo CLI

### Setup Instructions
1. Clone the repository.
2. Install dependencies:
   ```bash
   npm install
   ```
3. (Optional) Run the mock data pipeline to generate safety scores:
   ```bash
   node scripts/preprocess.js
   ```
4. Start the application:
   ```bash
   npx expo start
   ```
5. Press `w` to open in a web browser, or scan the QR code using the Expo Go app on your iOS/Android device.

---
*Built with ❤️ for the Hackathon.*
