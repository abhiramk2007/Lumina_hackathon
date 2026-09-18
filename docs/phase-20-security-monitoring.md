# Phase 20: Security, Monitoring & Hardening

## Overview
This phase hardened the AWS Serverless architecture deployed in Milestones 1 and 2 by implementing least privilege IAM roles, API Gateway Authorization, CloudWatch monitoring (X-Ray), and structured logging.

## Implementation Details

### 1. IAM Architecture
- **Least Privilege Principle**: All AWS Lambda functions are assigned execution roles tailored strictly to their requirements via AWS CDK.
- `profileLambda`: Granted `grantReadWriteData` exclusively to the `UsersTable`.
- `routingLambda`: Granted `grantReadData` exclusively to `UsersTable` and `ReportsTable`.
- `reportsLambda`: Granted `grantReadWriteData` exclusively to the `ReportsTable`.
- `sosLambda`: Granted `grantReadData` exclusively to the `UsersTable`.

### 2. Authentication & Authorization
- **Cognito User Pools Authorizer**: A Cognito Authorizer was attached to the API Gateway. All incoming HTTP requests to `/profile`, `/routes`, `/reports`, and `/sos` now strictly require a valid JSON Web Token (JWT) from Cognito in the `Authorization` header.
- **Frontend App**: `MockApi.js` was updated to securely fetch the current user's session token using `aws-amplify` and append it to all outbound `fetch()` requests.

### 3. Logging & Monitoring
- **CloudWatch X-Ray**: Tracing has been enabled on the API Gateway and all Lambda functions (`tracing: lambda.Tracing.ACTIVE`). This provides detailed trace maps, error rates, and duration metrics.
- **Structured JSON Logging**: All `console.log` and `console.error` calls inside the Node.js Lambdas were rewritten to output structured JSON objects (`{ level: 'INFO', message: ... }`). This allows CloudWatch Logs Insights to query and parse logs automatically.

### 4. Privacy & Data Security
- **SOS PII Removal**: `sos.js` was rewritten to remove exact coordinates and user emails from CloudWatch logs. Logs now only contain approximate location grids and boolean flags for dispatch success.
- **Input Validation**: All lambda functions validate incoming `event.body` schemas to prevent malformed data injection.

### 5. Known Limitations & Mocks (Bedrock / Step Functions / S3)
- The Phase 20 requirements mentioned Bedrock, Step Functions, and S3. Because this project used a mock machine-learning module integrated directly into the `routingLambda` (rather than a live SageMaker/Bedrock endpoint) and a mock event-bus inside `sosLambda`, those specific services did not require IAM hardening. If transitioned to true ML infrastructure later, identical least-privilege principles must be applied to `s3:GetObject` and `bedrock:InvokeModel`.

## Test Results
- **Unauthorized API Access**: Rejected by API Gateway with `401 Unauthorized`.
- **Authorized Access**: Successfully authenticated and processed by Lambda.
- **Malformed Input**: Handled gracefully by Lambda try/catch blocks returning `400 Bad Request`.
- **Secret Exposure**: Zero secrets exist in the codebase. All access uses IAM Roles/Policies generated at deploy-time by AWS CDK.
