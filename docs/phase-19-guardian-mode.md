# Phase 19: Guardian Mode

## Overview
Guardian Mode is an explicit, permission-based safety feature designed for families and guardians. It allows a designated guardian to actively monitor a specific journey and receive instant alerts if the user deviates from the safe path or fails to arrive on time.

## Architecture

1. **Guardian Setup (`screens/GuardianScreen.js`)**: 
   - A dedicated dashboard where the Guardian can configure a child's journey, setting the expected destination and ETA.
   - When initiated, it sends a monitoring request. Once accepted (mocked automatically), the journey becomes `ACTIVE`.
2. **Privacy Banner (`screens/MapScreen.js`)**:
   - Location sharing is NOT hidden. The user is presented with a persistent black banner across the top of their screen reminding them that Guardian Mode is active and exactly who has access to their location.
   - They can instantly **REVOKE** this access at any time using a button on the banner.
3. **Deviation Polling**:
   - When the user deviates (`SIGNIFICANT`), `MockApi.updateGuardianStatus` pushes the `DEVIATED` state to the backend. The Guardian Dashboard receives this state change almost instantly.
4. **Mock EventBridge Check-in**:
   - The Phase 18 check-in logic has been repurposed exclusively for Guardian Mode. If the ETA timer expires, the backend automatically transitions the journey to `MISSED_CHECKIN`.
   - The Guardian Dashboard lights up RED.
   - The User's Map Screen pops up the "Are you safe?" dead-man's switch.

## Testing Conducted
- **Guardian Setup**: Verified the guardian can set up a journey to "School". (Status: PASS)
- **Monitoring & Privacy**: Started a route on the User side and confirmed the explicit Privacy Banner appears. (Status: PASS)
- **Deviation**: Clicked "Big Dev" and confirmed the Guardian Dashboard correctly flips to ORANGE with a Deviation warning. (Status: PASS)
- **Missed Check-in**: Waited for the ETA timer to expire and confirmed the Guardian Dashboard flips to RED, and the User gets prompted to confirm safety. (Status: PASS)
- **SOS**: Simulated SOS dispatch and verified Guardian Dashboard turns BLACK indicating an emergency. (Status: PASS)
- **Permission Removal**: Clicked REVOKE on the user's banner. Verified Guardian tracking is cancelled and the banner disappears. (Status: PASS)

## Limitations
- In a true multi-device environment, Guardian and User would be on entirely different phones, relying on AWS API Gateway WebSockets, AWS IoT Core, or SNS push notifications to stream the location and alerts in real time. Our mock uses `setInterval` over `AsyncStorage` to simulate real-time syncing on the same device.
