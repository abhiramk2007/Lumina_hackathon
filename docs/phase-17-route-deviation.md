# Phase 17: Route Deviation Detection

## Overview
During active navigation, if a user strays significantly off their pre-planned path, they might have entered an unverified or high-risk zone. Phase 17 introduces real-time deviation monitoring.

## 1. Deviation Algorithm
The system continuously tracks the user's GPS location against the polyline geometry of the selected route. 
It uses a geometric function `distanceToSegment(point, segmentStart, segmentEnd)` to find the absolute shortest perpendicular distance from the user to the nearest road segment on the path.

### 2. Transport-Specific Thresholds
Not all deviations are equal. The thresholds are dynamically scaled based on the user's `transportMode`:
- **Walk**: Threshold is extremely tight (`0.0005` degrees, roughly 50 meters). Pedestrians shouldn't veer far off the sidewalk without intent.
- **Car / 2-Wheeler**: Threshold is looser (`0.0015` degrees). This accounts for parking, detours around traffic, or driving to the opposite side of a wide highway.

### 3. False-Positive Handling
To prevent spamming the user on tiny GPS inaccuracies (drift):
- If the deviation is within the strict threshold, the state remains **NORMAL**.
- If it slightly exceeds it, it triggers a **MINOR DEVIATION** (non-intrusive UI text, no modal).
- Only when it crosses `strictness * 2` does it trigger the full **SIGNIFICANT DEVIATION** Modal.

## 4. Modal Fallbacks & SOS Integration
When a significant deviation is detected, the user is presented with a critical modal:
- **CONTINUE (I'M SAFE)**: Dismisses the modal if the user knows where they are going.
- **FIND A SAFER ROUTE**: Automatically calls the Route Optimization Lambda (`getRoutes`) using their *new* off-grid location as the origin, forcing a strict `safetyPreference=1.0` to get them back to safety.
- **SOS**: Instantly hooks into the Phase 14 EventBridge SOS workflow. It does *not* create a secondary SOS system; it reuses the battle-tested infrastructure.

## Testing Conducted
- **Mock GPS Spoofer**: Injected `[DEV]` buttons to teleport the GPS coordinate.
- **Normal**: GPS matches the route. (Status: PASS)
- **Minor Dev**: GPS shifts by 0.0008. UI shows a yellow text warning. (Status: PASS)
- **Significant Dev**: GPS shifts by 0.004. Modal appears. (Status: PASS)
- **Safer Reroute**: Clicking "Find Safer Route" cleared the modal, reset the navigation state, and successfully downloaded a new safe route from the API using the deviated location as the new origin. (Status: PASS)
