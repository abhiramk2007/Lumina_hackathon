<div align="center">
  <h1>🌟 Lumina: Intelligent Safety Navigation</h1>
  <p><strong>Navigate with confidence. Reach your destination safely.</strong></p>

  <!-- Badges -->
  <img src="https://img.shields.io/badge/React_Native-20232A?style=for-the-badge&logo=react&logoColor=61DAFB" alt="React Native" />
  <img src="https://img.shields.io/badge/Expo-1B1F23?style=for-the-badge&logo=expo&logoColor=white" alt="Expo" />
  <img src="https://img.shields.io/badge/AWS-232F3E?style=for-the-badge&logo=amazon-aws&logoColor=white" alt="AWS" />
  <img src="https://img.shields.io/badge/Node.js-43853D?style=for-the-badge&logo=node.js&logoColor=white" alt="Node.js" />
</div>

<br />

**Lumina** is a crowdsourced, ML-powered safety navigation app designed to ensure pedestrians and commuters can find the absolute safest routes to their destinations, especially at night or in unfamiliar areas.

## 🏆 The Problem

Standard navigation apps prioritize speed and distance. They do not account for environmental safety factors like poor street lighting, historical crime rates, or isolation. Lumina changes the paradigm by introducing **Safety First Routing**, crowdsourced hazard reporting, and instant SOS dispatching.

## 🚀 Key Features

* **🧠 ML Safety Scoring Model**: Analyzes route segments based on historical crime data, lighting density, and crowd activity levels to assign a 0-100 Safety Score to every path.
* **🗺️ Dynamic Rerouting**: Actively scans for crowdsourced hazards (e.g., suspicious activity, broken streetlights) and dynamically penalizes dangerous routes, instantly offering a safe alternative.
* **🚧 Real-Time Route Deviation Detection**: Continuously monitors your GPS path. If you stray into an unverified or high-risk zone, the app triggers strict warnings and can instantly reroute you to safety or activate SOS.
* **🚨 EventBridge SOS Dispatch**: A 3-second countdown SOS button that instantly routes your live GPS coordinates to your emergency contacts via SMS and Email.
* **🏥 Safe Haven Tracking**: Automatically scans your route for verified 24/7 safe havens (Hospitals, Police Stations, 24/7 Stores) and drops distinct markers on your map.
* **🗣️ Community Reporting**: Keep your neighborhood safe by submitting real-time reports of road hazards or suspicious activities.

---

## 📊 Datasets Used for Training (ML Model)

The Safety Scoring Model leverages extensive geographic, crime, and infrastructure datasets (specifically from Bengaluru) to train the predictive models. The raw data files used include:

* **Crime Data**: `crime_karnataka_2023.json`, `crime_karnataka_2024.json`, `crime_karnataka_2025.json`, `crime_women_datagovin.json`
* **Infrastructure & Lighting**: `streetlights_2018_sample.json`, `streetlights_zonewise.json`
* **Road Networks**: `osm_roads_urban.json`, `osm_roads_rural.json`
* **Processed Inputs**: `crime/raw.json`, `lighting/raw.json`

---

## 🛠️ Tech Stack

- **Frontend:** React Native, Expo, React Navigation, React Native Maps
- **State Management & Storage:** AsyncStorage, AWS Amplify
- **Backend (Architecture):** AWS Lambda, Amazon API Gateway
- **Database:** Amazon DynamoDB, Amazon S3
- **Authentication:** Amazon Cognito
- **Event Driven Services:** Amazon EventBridge, Amazon SNS
- **Machine Learning:** Amazon SageMaker / Bedrock

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

## 💻 The "Mock-AWS" Local Environment

*Due to AWS account verification holds during the hackathon, this project currently runs using a robust local simulation of the AWS Cloud environment.*

All AWS services have been meticulously mocked in the `services/` directory to demonstrate full functional logic without requiring active cloud credentials:

1. **`MockCognito.js`**: Simulates AWS Cognito by handling JWT-style session states and user registration using React Native's `AsyncStorage`.
2. **`MockApi.js` (API Gateway + Lambda)**: Intercepts API calls, simulates network latency, and executes the heavy-lifting logic (like sorting route arrays based on preference).
3. **`AsyncStorage` (DynamoDB)**: Acts as the NoSQL database for persisting user settings, emergency contacts, and crowdsourced reports.
4. **`preprocess.js` (S3 + SageMaker)**: A Node.js data pipeline that ingests raw JSON datasets and outputs normalized safety densities.
5. **Console Logging (EventBridge + SNS)**: When an SOS is triggered, the event routing and SMS delivery receipts are logged directly to the local terminal to prove decoupled execution.

---

## 🚀 Getting Started

### Prerequisites
* Node.js (v18+)
* Expo CLI (`npm install -g expo-cli`)

### Setup Instructions

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/lumina_hackathon.git
   cd lumina_hackathon
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```

3. **(Optional) Run the mock data pipeline:**
   Generate safety scores using the mock SageMaker script:
   ```bash
   node scripts/preprocess.js
   ```

4. **Start the application:**
   ```bash
   npx expo start
   ```

5. **Run on Device / Emulator:**
   - Press `w` to open in a web browser.
   - Press `a` to open in an Android emulator.
   - Press `i` to open in an iOS simulator.
   - Scan the QR code using the **Expo Go** app on your physical iOS/Android device.

---

<div align="center">
  <p><i>Built with ❤️ for the Hackathon.</i></p>
</div>
