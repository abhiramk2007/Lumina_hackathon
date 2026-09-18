# Phase 16: Automatic Disturbance Detection

## Overview
Phase 16 introduces **Automatic Disturbance Detection** using the mobile device's built-in Accelerometer. It is designed to act as a fail-safe SOS trigger if the user experiences sudden physical disturbance (e.g., dropping the phone during a sprint, the phone being thrown, or sudden intense struggle).

**DISCLAIMER**: This system only detects unusual physical movement. It does *not* reliably determine if a person is being attacked, kidnapped, or in danger.

## Architecture & Data Flow

### 1. Local Processing (Privacy First)
The app uses `expo-sensors` to sample the Accelerometer at 2Hz (every 500ms).
**Crucially, all raw sensor data is processed entirely on the local device.** No raw accelerometer data is ever uploaded to AWS or any cloud service, preserving battery life and user privacy.

### 2. Detection Algorithm
The `SensorMonitor.js` component calculates the total G-Force vector magnitude:
`gForce = sqrt(x² + y² + z²)`

Standard gravity at rest is ~1.0G. The threshold for "Disturbance" is set to **2.5G**.
If the vector crosses this threshold, it assumes a sudden spike in acceleration (throwing, intense shaking, sudden braking).

### 3. False-Positive Protection
To prevent accidental triggers (e.g., tossing the phone onto a bed):
- A full-screen Modal overlay appears saying "Unusual movement detected."
- A 10-second countdown begins.
- The user can press **"I'M SAFE"** to cancel the countdown. This immediately resumes standard operation without logging an SOS event.
- If the countdown reaches 0 (or the user explicitly presses **"SEND SOS NOW"**), the system triggers the standard Phase 14 EventBridge SOS workflow.

## User Settings & Permissions
- The feature can be toggled on/off in the **Settings** screen via the "Automatic Disturbance Detection" switch. It defaults to `true`.
- The `SensorMonitor` component gracefully handles missing sensors (e.g., on Web platforms) by bypassing the sensor subscription without crashing. For development and testing on the web, a `[DEV] Simulate Shake` button is injected to test the UI flow.

## Testing Strategy Performed
1. **Normal Movement**: Accelerometer data remains around 1.0G; no alert is triggered.
2. **False Alert Prevention**: Triggered the simulated shake, pressed "I'M SAFE". The UI immediately dismissed, and no SOS was fired.
3. **Emergency Dispatch**: Let the countdown expire from 10 to 0. Verified the `MockApi.triggerSOS()` was invoked and the "SOS DISPATCHED" screen appeared.
4. **Settings Toggle**: Disabled the feature in Settings. Verified that the `[DEV] Simulate Shake` button disappeared (sensor unsubscribed).
5. **Web Graceful Fallback**: Verified the app does not crash when `Accelerometer` natively fails to load on the Web browser.
