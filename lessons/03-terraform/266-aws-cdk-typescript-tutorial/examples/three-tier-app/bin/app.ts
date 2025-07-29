#!/usr/bin/env node
import * as cdk from 'aws-cdk-lib';
import { WebApplicationStack } from '../lib/web-application-stack';
import { DataPipelineStack } from '../lib/data-pipeline-stack';
import { MonitoringStack } from '../lib/monitoring-stack';

const app = new cdk.App();

// Get environment configuration
const environment = app.node.tryGetContext('environment') || 'dev';
const domainName = app.node.tryGetContext('domainName');

// Environment configuration
const envConfig = {
  dev: {
    account: process.env.CDK_DEFAULT_ACCOUNT,
    region: 'us-west-2'
  },
  staging: {
    account: process.env.CDK_DEFAULT_ACCOUNT,
    region: 'us-west-2'
  },
  prod: {
    account: process.env.CDK_PROD_ACCOUNT || process.env.CDK_DEFAULT_ACCOUNT,
    region: 'us-east-1'
  }
};

const env = envConfig[environment as keyof typeof envConfig];

// Create stacks with dependencies
const webAppStack = new WebApplicationStack(app, `WebApp-${environment}`, {
  env,
  stage: environment,
  domainName: domainName,
  stackName: `web-application-${environment}`,
  description: `Web application infrastructure for ${environment} environment`,
});

const dataPipelineStack = new DataPipelineStack(app, `DataPipeline-${environment}`, {
  env,
  stage: environment,
  stackName: `data-pipeline-${environment}`,
  description: `Data processing pipeline for ${environment} environment`,
});

const monitoringStack = new MonitoringStack(app, `Monitoring-${environment}`, {
  env,
  stage: environment,
  webAppStack: webAppStack,
  dataPipelineStack: dataPipelineStack,
  stackName: `monitoring-${environment}`,
  description: `Monitoring and observability for ${environment} environment`,
});

// Add tags to all stacks
const tags = {
  Environment: environment,
  Project: 'WebApplication',
  ManagedBy: 'CDK',
  Owner: 'DevOps Team'
};

Object.entries(tags).forEach(([key, value]) => {
  cdk.Tags.of(app).add(key, value);
});

// Add environment-specific tags
if (environment === 'prod') {
  cdk.Tags.of(app).add('BackupRequired', 'true');
  cdk.Tags.of(app).add('MonitoringLevel', 'enhanced');
} else {
  cdk.Tags.of(app).add('BackupRequired', 'false');
  cdk.Tags.of(app).add('MonitoringLevel', 'basic');
}
