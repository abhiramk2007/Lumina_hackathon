# Environment Inspection

## Detected Environment
* **Operating System**: Windows
* **Node.js**: v24.18.0
* **npm**: 11.16.0
* **Python**: 3.13.14
* **Git**: 2.55.0.windows.2
* **AWS CLI**: Not installed
* **AWS Credentials**: Not configured
* **Flutter**: Not installed
* **Existing project files/frameworks**: Empty directory (only `.git` present)

## Selected Technology Stack
**React Native + Expo** is the most practical choice.
*Reasoning*: Node.js and npm are already installed in the current environment and ready to use, whereas Flutter is missing. Expo can easily bootstrap the mobile app using `npx`.

## Required Tools
* Node.js & npm (Present)
* Git (Present)
* AWS CLI (Missing)
* Expo CLI (Via npx)

## Missing Dependencies
1. **AWS CLI v2**: Required for deploying AWS backend resources (Lambda, API Gateway, DynamoDB, Bedrock integrations, EventBridge).
2. **AWS Credentials**: Need an IAM user or role configured with `aws configure` to allow provisioning of resources.

## AWS Requirements
* Target AWS services: Amazon API Gateway, AWS Lambda, Amazon DynamoDB, Amazon S3, Amazon Bedrock, Amazon Cognito, Amazon EventBridge, AWS Step Functions, Amazon SNS, Amazon CloudWatch.
* Configuration: Must use environment variables for keys/secrets. No hard-coded AWS credentials.
