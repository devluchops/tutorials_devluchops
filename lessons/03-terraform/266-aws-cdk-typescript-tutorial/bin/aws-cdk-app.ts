#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import { VpcStack } from '../lib/vpc-stack';
import { WebApplicationStack } from '../lib/web-application-stack';
import { DatabaseStack } from '../lib/database-stack';
import { MonitoringStack } from '../lib/monitoring-stack';
import { LambdaApiStack } from '../lib/lambda-api-stack';

const app = new cdk.App();

// Get environment configuration
const environment = app.node.tryGetContext('environment') || 'dev';
const config = app.node.tryGetContext(environment) || {};

// Common environment configuration
const env = {
  account: process.env.CDK_DEFAULT_ACCOUNT,
  region: process.env.CDK_DEFAULT_REGION || 'us-west-2',
};

// Environment-specific tags
const commonTags = {
  Environment: environment,
  Project: 'aws-cdk-tutorial',
  ManagedBy: 'CDK',
  Owner: 'DevOps Team',
  CreatedBy: 'AWS CDK Tutorial',
};

// VPC Stack - Foundation infrastructure
const vpcStack = new VpcStack(app, `VpcStack-${environment}`, {
  env,
  description: `VPC infrastructure for ${environment} environment`,
  tags: commonTags,
  stackName: `cdk-tutorial-vpc-${environment}`,
  vpcConfig: {
    cidr: config.vpcCidr || '10.0.0.0/16',
    maxAzs: config.maxAzs || 2,
    enableNatGateway: config.enableNatGateway !== false,
    enableVpnGateway: config.enableVpnGateway || false,
    createFlowLogs: config.createFlowLogs !== false,
  },
});

// Database Stack - RDS infrastructure
const databaseStack = new DatabaseStack(app, `DatabaseStack-${environment}`, {
  env,
  description: `Database infrastructure for ${environment} environment`,
  tags: commonTags,
  stackName: `cdk-tutorial-database-${environment}`,
  vpc: vpcStack.vpc,
  databaseConfig: {
    engine: config.dbEngine || 'postgres',
    instanceClass: config.dbInstanceClass || 'db.t3.micro',
    allocatedStorage: config.dbAllocatedStorage || 20,
    multiAz: config.dbMultiAz || false,
    backupRetention: config.dbBackupRetention || 7,
    deletionProtection: config.dbDeletionProtection || (environment === 'prod'),
  },
});

// Web Application Stack - EC2 with Auto Scaling
const webApplicationStack = new WebApplicationStack(app, `WebApplicationStack-${environment}`, {
  env,
  description: `Web application infrastructure for ${environment} environment`,
  tags: commonTags,
  stackName: `cdk-tutorial-web-app-${environment}`,
  vpc: vpcStack.vpc,
  database: databaseStack.database,
  webConfig: {
    instanceType: config.webInstanceType || 't3.micro',
    minCapacity: config.webMinCapacity || 1,
    maxCapacity: config.webMaxCapacity || 3,
    desiredCapacity: config.webDesiredCapacity || 2,
    keyPairName: config.keyPairName,
    enableSsl: config.enableSsl !== false,
    domainName: config.domainName,
  },
});

// Lambda API Stack - Serverless API
const lambdaApiStack = new LambdaApiStack(app, `LambdaApiStack-${environment}`, {
  env,
  description: `Lambda API infrastructure for ${environment} environment`,
  tags: commonTags,
  stackName: `cdk-tutorial-lambda-api-${environment}`,
  vpc: vpcStack.vpc,
  database: databaseStack.database,
  apiConfig: {
    stageName: environment,
    throttleRateLimit: config.apiThrottleRateLimit || 1000,
    throttleBurstLimit: config.apiThrottleBurstLimit || 2000,
    enableApiKey: config.enableApiKey || false,
    enableCors: config.enableCors !== false,
  },
});

// Monitoring Stack - CloudWatch dashboards and alarms
const monitoringStack = new MonitoringStack(app, `MonitoringStack-${environment}`, {
  env,
  description: `Monitoring infrastructure for ${environment} environment`,
  tags: commonTags,
  stackName: `cdk-tutorial-monitoring-${environment}`,
  vpc: vpcStack.vpc,
  webApplication: webApplicationStack,
  lambdaApi: lambdaApiStack,
  database: databaseStack.database,
  monitoringConfig: {
    enableDetailedMonitoring: config.enableDetailedMonitoring !== false,
    alarmEmail: config.alarmEmail || 'admin@company.com',
    enableSlackNotifications: config.enableSlackNotifications || false,
    slackWebhookUrl: config.slackWebhookUrl,
    createDashboard: config.createDashboard !== false,
  },
});

// Add dependencies
databaseStack.addDependency(vpcStack);
webApplicationStack.addDependency(vpcStack);
webApplicationStack.addDependency(databaseStack);
lambdaApiStack.addDependency(vpcStack);
lambdaApiStack.addDependency(databaseStack);
monitoringStack.addDependency(vpcStack);
monitoringStack.addDependency(webApplicationStack);
monitoringStack.addDependency(lambdaApiStack);
monitoringStack.addDependency(databaseStack);

// Output important information
new cdk.CfnOutput(vpcStack, 'VpcId', {
  value: vpcStack.vpc.vpcId,
  description: 'VPC ID',
  exportName: `${environment}-vpc-id`,
});

new cdk.CfnOutput(databaseStack, 'DatabaseEndpoint', {
  value: databaseStack.database.instanceEndpoint.hostname,
  description: 'Database endpoint',
  exportName: `${environment}-database-endpoint`,
});

new cdk.CfnOutput(webApplicationStack, 'LoadBalancerDnsName', {
  value: webApplicationStack.loadBalancer.loadBalancerDnsName,
  description: 'Load balancer DNS name',
  exportName: `${environment}-alb-dns-name`,
});

new cdk.CfnOutput(lambdaApiStack, 'ApiGatewayUrl', {
  value: lambdaApiStack.api.url,
  description: 'API Gateway URL',
  exportName: `${environment}-api-gateway-url`,
});

// Add environment-specific configurations
if (environment === 'prod') {
  // Production-specific configurations
  cdk.Tags.of(app).add('BackupRequired', 'true');
  cdk.Tags.of(app).add('Compliance', 'required');
  cdk.Tags.of(app).add('DataClassification', 'confidential');
}

if (environment === 'dev') {
  // Development-specific configurations
  cdk.Tags.of(app).add('AutoShutdown', 'true');
  cdk.Tags.of(app).add('DataClassification', 'internal');
}

// Apply common tags to all resources
Object.entries(commonTags).forEach(([key, value]) => {
  cdk.Tags.of(app).add(key, value);
});

// Synthesis
app.synth();
