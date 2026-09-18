# Phase 18: Safety Check-in System

## Overview
The Safety Check-in system (also known as a "dead-man's switch") ensures that if a user does not arrive at their destination by their expected arrival time, the app proactively checks on their safety and escalates if necessary.

## Architecture & AWS Integration

### 1. Journey Registration
When the user enables "Safety Check-in" and starts navigation, the frontend sends a request to the backend with their `email`, `destination`, and `etaMinutes`. 
In a production AWS environment, this would hit API Gateway -> Lambda, which would register an **AWS EventBridge Scheduler** payload configured to trigger at `Date.now() + etaMinutes`.

*(In our mock environment, `MockApi.startJourney` uses `AsyncStorage` to store the active journey and a local `setTimeout` to mimic the EventBridge Scheduler).*

### 2. Arrival / Safe Completion
If the user arrives at their destination, they press `Arrive` (or the GPS fence triggers). The frontend calls `MockApi.completeJourney()`.
In AWS, this would invoke a Lambda that **cancels/deletes** the EventBridge schedule before it can fire, marking the journey safely closed.

### 3. Missed Check-in Escalation
If the user does *not* arrive in time, the EventBridge schedule fires.
1. The Lambda updates the journey status in DynamoDB to `MISSED_CHECKIN`.
2. The frontend (which polls for journey status) detects the change and throws a full-screen, highly disruptive Modal asking **"Are you safe?"**.
3. **I'M SAFE**: The user marks themselves safe. The journey completes.
4. **NEED HELP**: The user clicks the button (or ignores it). The app re-uses the existing Phase 14 **EventBridge SOS Workflow** to instantly broadcast their last known location to emergency contacts.

## Testing Conducted
- **Normal Journey / Early Arrival**: The journey was started with a 1-minute timer. The user arrived early and the journey was completed. The timer was successfully cleared and no alarm was raised. (Status: PASS)
- **Missed Check-in**: The journey was started with a `0.1` minute (6-second) timer for testing. The user did not arrive. After 6 seconds, the "Are you safe?" modal appeared with heavy haptic vibrations. (Status: PASS)
- **I'm Safe Workflow**: Clicked "I'M SAFE" on the modal. The modal dismissed and the journey concluded gracefully without SOS dispatch. (Status: PASS)
- **Need Help Workflow**: Clicked "NEED HELP" on the modal. The existing EventBridge SOS flow successfully triggered and dispatched an alert. (Status: PASS)

## Limitations
- **Background Execution**: On iOS/Android, if the app is hard-closed or deeply suspended, the frontend cannot poll. In a full AWS deployment, the EventBridge Lambda would instead send a **Push Notification** via SNS/FCM to wake the device, which clicking would open the "Are you safe?" modal.
