import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as cognito from 'aws-cdk-lib/aws-cognito';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as dynamodb from 'aws-cdk-lib/aws-dynamodb';
import * as apigateway from 'aws-cdk-lib/aws-apigateway';

export class BackendStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // Pre-SignUp Lambda to auto-confirm users (Hackathon shortcut)
    const autoConfirmLambda = new lambda.Function(this, 'AutoConfirmUser', {
      runtime: lambda.Runtime.NODEJS_20_X,
      handler: 'index.handler',
      code: lambda.Code.fromInline(`
        exports.handler = async (event) => {
          event.response.autoConfirmUser = true;
          event.response.autoVerifyEmail = true;
          return event;
        };
      `),
    });

    // ==========================================
    // 1. COGNITO USER POOL (Authentication)
    // ==========================================
    const userPool = new cognito.UserPool(this, 'LuminaUserPool', {
      userPoolName: 'LuminaUsers',
      selfSignUpEnabled: true,
      signInAliases: { email: true },
      autoVerify: { email: true },
      passwordPolicy: {
        minLength: 8,
        requireLowercase: true,
        requireUppercase: true,
        requireDigits: true,
        requireSymbols: false,
      },
      accountRecovery: cognito.AccountRecovery.EMAIL_ONLY,
      removalPolicy: cdk.RemovalPolicy.DESTROY, // For hackathon cleanup
      lambdaTriggers: {
        preSignUp: autoConfirmLambda
      }
    });

    // 2. USER POOL CLIENT (App Integration)
    const userPoolClient = new cognito.UserPoolClient(this, 'LuminaUserPoolClient', {
      userPool,
      generateSecret: false, // React Native does not support secrets
      authFlows: {
        userSrp: true, // Secure Remote Password
      },
    });

    // 3. IDENTITY POOL (Authorization for AWS Services like DynamoDB, IoT, etc.)
    const identityPool = new cognito.CfnIdentityPool(this, 'LuminaIdentityPool', {
      identityPoolName: 'LuminaIdentities',
      allowUnauthenticatedIdentities: true, // Allow guest users (e.g. anonymous SOS)
      cognitoIdentityProviders: [{
        clientId: userPoolClient.userPoolClientId,
        providerName: userPool.userPoolProviderName,
      }],
    });

    // ==========================================
    // 3. DYNAMODB TABLES
    // ==========================================
    const usersTable = new dynamodb.Table(this, 'UsersTable', {
      partitionKey: { name: 'email', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
    });

    const reportsTable = new dynamodb.Table(this, 'ReportsTable', {
      partitionKey: { name: 'id', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
    });

    // ==========================================
    // 4. LAMBDA FUNCTIONS
    // ==========================================
    const profileLambda = new lambda.Function(this, 'ProfileLambda', {
      runtime: lambda.Runtime.NODEJS_20_X,
      handler: 'profile.handler',
      code: lambda.Code.fromAsset('lambda'),
      tracing: lambda.Tracing.ACTIVE,
      environment: { USERS_TABLE: usersTable.tableName }
    });
    usersTable.grantReadWriteData(profileLambda);

    const routingLambda = new lambda.Function(this, 'RoutingLambda', {
      runtime: lambda.Runtime.NODEJS_20_X,
      handler: 'routing.handler',
      code: lambda.Code.fromAsset('lambda'),
      tracing: lambda.Tracing.ACTIVE,
      environment: {
        USERS_TABLE: usersTable.tableName,
        REPORTS_TABLE: reportsTable.tableName,
        GOOGLE_MAPS_API_KEY: process.env.GOOGLE_MAPS_API_KEY || 'AIzaSyAC39nIG3SM0ZbIBigHA59YAHfRAIVLyKA'
      },
    });
    reportsTable.grantReadData(routingLambda);
    usersTable.grantReadData(routingLambda);

    const reportsLambda = new lambda.Function(this, 'ReportsLambda', {
      runtime: lambda.Runtime.NODEJS_20_X,
      handler: 'reports.handler',
      code: lambda.Code.fromAsset('lambda'),
      tracing: lambda.Tracing.ACTIVE,
      environment: { REPORTS_TABLE: reportsTable.tableName }
    });
    reportsTable.grantReadWriteData(reportsLambda);

    const sosLambda = new lambda.Function(this, 'SOSLambda', {
      runtime: lambda.Runtime.NODEJS_20_X,
      handler: 'sos.handler',
      code: lambda.Code.fromAsset('lambda'),
      tracing: lambda.Tracing.ACTIVE,
      environment: { USERS_TABLE: usersTable.tableName }
    });
    usersTable.grantReadData(sosLambda);

    // ==========================================
    // 5. API GATEWAY
    // ==========================================
    const api = new apigateway.RestApi(this, 'LuminaApi', {
      restApiName: 'Lumina Service',
      deployOptions: {
        tracingEnabled: true,
      },
      defaultCorsPreflightOptions: {
        allowOrigins: apigateway.Cors.ALL_ORIGINS,
        allowMethods: apigateway.Cors.ALL_METHODS,
        allowHeaders: ['Content-Type', 'X-Amz-Date', 'Authorization', 'X-Api-Key', 'X-Amz-Security-Token'],
      }
    });

    // Fix CORS for 4xx/5xx responses (especially 401 Unauthorized from Cognito)
    api.addGatewayResponse('UnauthorizedResponse', {
      type: apigateway.ResponseType.UNAUTHORIZED,
      responseHeaders: { 'Access-Control-Allow-Origin': "'*'" }
    });
    api.addGatewayResponse('AccessDeniedResponse', {
      type: apigateway.ResponseType.ACCESS_DENIED,
      responseHeaders: { 'Access-Control-Allow-Origin': "'*'" }
    });
    api.addGatewayResponse('Default5XXResponse', {
      type: apigateway.ResponseType.DEFAULT_5XX,
      responseHeaders: { 'Access-Control-Allow-Origin': "'*'" }
    });

    // Create Cognito Authorizer
    const auth = new apigateway.CognitoUserPoolsAuthorizer(this, 'LuminaAuthorizer', {
      cognitoUserPools: [userPool]
    });

    const authOptions = {
      authorizer: auth,
      authorizationType: apigateway.AuthorizationType.COGNITO
    };

    // Profile Endpoints
    const profileResource = api.root.addResource('profile');
    profileResource.addMethod('GET', new apigateway.LambdaIntegration(profileLambda), authOptions);
    profileResource.addMethod('PUT', new apigateway.LambdaIntegration(profileLambda), authOptions);

    // Routing Endpoint
    const routingResource = api.root.addResource('routes');
    routingResource.addMethod('GET', new apigateway.LambdaIntegration(routingLambda), authOptions);

    // Reports Endpoints
    const reportsResource = api.root.addResource('reports');
    reportsResource.addMethod('POST', new apigateway.LambdaIntegration(reportsLambda), authOptions);

    // SOS Endpoint
    const sosResource = api.root.addResource('sos');
    sosResource.addMethod('POST', new apigateway.LambdaIntegration(sosLambda), authOptions);


    // ==========================================
    // OUTPUTS (Required for frontend config)
    // ==========================================
    new cdk.CfnOutput(this, 'ApiEndpoint', {
      value: api.url,
      description: 'API Gateway Endpoint URL',
    });
    new cdk.CfnOutput(this, 'UserPoolId', {
      value: userPool.userPoolId,
      description: 'The ID of the Cognito User Pool',
    });

    new cdk.CfnOutput(this, 'UserPoolClientId', {
      value: userPoolClient.userPoolClientId,
      description: 'The ID of the Cognito User Pool Client',
    });

    new cdk.CfnOutput(this, 'IdentityPoolId', {
      value: identityPool.ref,
      description: 'The ID of the Cognito Identity Pool',
    });
    
    new cdk.CfnOutput(this, 'Region', {
      value: this.region,
      description: 'The region of the deployment',
    });
  }
}
