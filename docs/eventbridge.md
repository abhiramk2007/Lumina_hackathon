# EventBridge SOS Routing Architecture (Amazon SNS)

For the hackathon, the SOS distress signal must reliably reach emergency contacts. We use **Amazon EventBridge** and **Amazon SNS** to decouple the event ingestion from the notification delivery.

## Architecture Flow

1. **Mobile App**: User triggers the SOS countdown.
2. **Amazon API Gateway**: Receives the `POST /sos` request.
3. **AWS Lambda (Ingestion)**: Formats the payload and puts an event onto the EventBridge default event bus.
4. **Amazon EventBridge**: 
   - **Rule Name**: `SafetyNav_RouteSOS`
   - **Event Pattern**:
     ```json
     {
       "source": ["com.safetynav.mobile"],
       "detail-type": ["Emergency SOS Triggered"]
     }
     ```
   - **Target**: Amazon SNS Topic (`SafetyNav_EmergencyAlerts`)
5. **Amazon SNS**: Broadcasts the message to all subscribed endpoints (SMS for phone numbers, Email for verified addresses).

## Mock Implementation Details

Since the AWS account is locked in verification, this entire flow is simulated locally inside `MockApi.js`. 
When the `triggerSOS` function is called, it directly mimics the EventBridge routing by executing `console.log()` statements that represent the Amazon SNS delivery payload.

*Example Mock SNS Payload:*
```json
{
  "Message": "EMERGENCY: SOS Triggered by user@example.com at [37.788, -122.432]",
  "Subject": "Safety Navigation SOS",
  "TopicArn": "arn:aws:sns:REGION:ACCOUNT:SafetyNav_EmergencyAlerts"
}
```
