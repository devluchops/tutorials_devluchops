# AWS CDK with TypeScript - Cloud Development Kit Tutorial

Complete AWS CDK tutorial using TypeScript to define cloud infrastructure with object-oriented code.

## What is AWS CDK?

AWS Cloud Development Kit (CDK) is a software development framework for defining cloud infrastructure using familiar programming languages.

### **CDK vs CloudFormation vs Terraform**

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   AWS CDK       │    │  CloudFormation │    │   Terraform     │
│  (High Level)   │───▶│  (Generated)    │───▶│  (Alternative)  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
  TypeScript/Python       JSON/YAML            HCL Language
  Object-Oriented         Declarative          Declarative
  Type Safety            Template-based         Multi-Cloud
  IDE Support            AWS Native             Provider System
```

## Core Concepts

### **1. Constructs**
```typescript
// L1 Constructs (CFN Resources)
import { CfnBucket } from 'aws-cdk-lib/aws-s3';

const cfnBucket = new CfnBucket(this, 'MyCfnBucket', {
  bucketName: 'my-raw-bucket'
});

// L2 Constructs (AWS Constructs)
import { Bucket } from 'aws-cdk-lib/aws-s3';

const bucket = new Bucket(this, 'MyBucket', {
  bucketName: 'my-cdk-bucket',
  versioned: true,
  encryption: BucketEncryption.S3_MANAGED
});

// L3 Constructs (Patterns)
import { ApplicationLoadBalancedFargateService } from 'aws-cdk-lib/aws-ecs-patterns';

const service = new ApplicationLoadBalancedFargateService(this, 'MyFargateService', {
  taskImageOptions: {
    image: ContainerImage.fromRegistry('nginx'),
  },
  publicLoadBalancer: true
});
```

### **2. Stacks and Apps**
```typescript
// app.ts
import { App } from 'aws-cdk-lib';
import { NetworkStack } from './lib/network-stack';
import { ComputeStack } from './lib/compute-stack';
import { DatabaseStack } from './lib/database-stack';

const app = new App();

// Environment configuration
const devEnv = {
  account: process.env.CDK_DEFAULT_ACCOUNT,
  region: 'us-west-2'
};

const prodEnv = {
  account: '123456789012',
  region: 'us-east-1'
};

// Create stacks with dependencies
const networkStack = new NetworkStack(app, 'NetworkStack-dev', {
  env: devEnv,
  stage: 'dev'
});

const databaseStack = new DatabaseStack(app, 'DatabaseStack-dev', {
  env: devEnv,
  vpc: networkStack.vpc,
  stage: 'dev'
});

const computeStack = new ComputeStack(app, 'ComputeStack-dev', {
  env: devEnv,
  vpc: networkStack.vpc,
  database: databaseStack.database,
  stage: 'dev'
});
```

## Getting Started

### **1. Installation & Setup**
```bash
# Install AWS CDK CLI
npm install -g aws-cdk

# Verify installation
cdk --version

# Bootstrap CDK (one time per account/region)
cdk bootstrap aws://123456789012/us-west-2

# Create new project
mkdir my-cdk-app && cd my-cdk-app
cdk init app --language typescript

# Install dependencies
npm install
```

### **2. Project Structure**
```
my-cdk-app/
├── bin/
│   └── my-cdk-app.ts          # Entry point
├── lib/
│   └── my-cdk-app-stack.ts    # Stack definitions
├── test/
│   └── my-cdk-app.test.ts     # Unit tests
├── cdk.json                   # CDK configuration
├── package.json
└── tsconfig.json
```

## Real-World Examples

### **1. Three-Tier Web Application**
```typescript
// lib/web-application-stack.ts
import { 
  Stack, 
  StackProps, 
  aws_ec2 as ec2,
  aws_ecs as ecs,
  aws_ecs_patterns as ecsPatterns,
  aws_rds as rds,
  aws_elasticloadbalancingv2 as elbv2,
  aws_route53 as route53,
  aws_certificatemanager as acm,
  aws_cloudfront as cloudfront,
  aws_s3 as s3,
  RemovalPolicy,
  Duration
} from 'aws-cdk-lib';
import { Construct } from 'constructs';

export interface WebApplicationStackProps extends StackProps {
  stage: string;
  domainName?: string;
}

export class WebApplicationStack extends Stack {
  constructor(scope: Construct, id: string, props: WebApplicationStackProps) {
    super(scope, id, props);

    // 1. VPC and Networking
    const vpc = new ec2.Vpc(this, 'VPC', {
      maxAzs: 3,
      natGateways: props.stage === 'prod' ? 3 : 1,
      subnetConfiguration: [
        {
          cidrMask: 24,
          name: 'public',
          subnetType: ec2.SubnetType.PUBLIC,
        },
        {
          cidrMask: 24,
          name: 'private',
          subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS,
        },
        {
          cidrMask: 28,
          name: 'isolated',
          subnetType: ec2.SubnetType.PRIVATE_ISOLATED,
        },
      ],
    });

    // 2. Database Layer
    const dbSubnetGroup = new rds.SubnetGroup(this, 'DatabaseSubnetGroup', {
      vpc,
      vpcSubnets: { subnetType: ec2.SubnetType.PRIVATE_ISOLATED },
      description: 'Subnet group for RDS database',
    });

    const database = new rds.DatabaseInstance(this, 'Database', {
      engine: rds.DatabaseInstanceEngine.postgres({
        version: rds.PostgresEngineVersion.VER_14,
      }),
      instanceType: props.stage === 'prod' 
        ? ec2.InstanceType.of(ec2.InstanceClass.R5, ec2.InstanceSize.LARGE)
        : ec2.InstanceType.of(ec2.InstanceClass.T3, ec2.InstanceSize.MICRO),
      vpc,
      subnetGroup: dbSubnetGroup,
      multiAz: props.stage === 'prod',
      allocatedStorage: props.stage === 'prod' ? 100 : 20,
      storageEncrypted: true,
      backupRetention: Duration.days(props.stage === 'prod' ? 30 : 7),
      deletionProtection: props.stage === 'prod',
      removalPolicy: props.stage === 'prod' ? RemovalPolicy.SNAPSHOT : RemovalPolicy.DESTROY,
    });

    // 3. ECS Cluster and Service
    const cluster = new ecs.Cluster(this, 'Cluster', {
      vpc,
      containerInsights: true,
    });

    // Add capacity to cluster
    cluster.addCapacity('DefaultAutoScalingGroup', {
      instanceType: new ec2.InstanceType('t3.medium'),
      minCapacity: props.stage === 'prod' ? 2 : 1,
      maxCapacity: props.stage === 'prod' ? 10 : 3,
    });

    // Task Definition
    const taskDefinition = new ecs.Ec2TaskDefinition(this, 'TaskDef', {
      networkMode: ecs.NetworkMode.AWS_VPC,
    });

    // Backend Container
    const backendContainer = taskDefinition.addContainer('backend', {
      image: ecs.ContainerImage.fromRegistry('my-app:latest'),
      memoryLimitMiB: 512,
      environment: {
        NODE_ENV: props.stage,
        DB_HOST: database.instanceEndpoint.hostname,
        DB_PORT: database.instanceEndpoint.port.toString(),
      },
      secrets: {
        DB_PASSWORD: ecs.Secret.fromSecretsManager(database.secret!, 'password'),
        DB_USERNAME: ecs.Secret.fromSecretsManager(database.secret!, 'username'),
      },
      logging: ecs.LogDrivers.awsLogs({
        streamPrefix: 'backend',
      }),
    });

    backendContainer.addPortMappings({
      containerPort: 3000,
      protocol: ecs.Protocol.TCP,
    });

    // Application Load Balancer
    const alb = new elbv2.ApplicationLoadBalancer(this, 'ALB', {
      vpc,
      internetFacing: true,
      loadBalancerName: `${props.stage}-web-app-alb`,
    });

    // ECS Service
    const service = new ecs.Ec2Service(this, 'Service', {
      cluster,
      taskDefinition,
      desiredCount: props.stage === 'prod' ? 3 : 1,
      assignPublicIp: false,
      enableExecuteCommand: true,
    });

    // Auto Scaling
    const scaling = service.autoScaleTaskCount({
      minCapacity: props.stage === 'prod' ? 2 : 1,
      maxCapacity: props.stage === 'prod' ? 10 : 3,
    });

    scaling.scaleOnCpuUtilization('CpuScaling', {
      targetUtilizationPercent: 70,
      scaleInCooldown: Duration.seconds(300),
      scaleOutCooldown: Duration.seconds(60),
    });

    // 4. Frontend (S3 + CloudFront)
    const websiteBucket = new s3.Bucket(this, 'WebsiteBucket', {
      bucketName: `${props.stage}-web-app-frontend`,
      websiteIndexDocument: 'index.html',
      websiteErrorDocument: 'error.html',
      publicReadAccess: false,
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
      removalPolicy: RemovalPolicy.DESTROY,
    });

    // CloudFront Distribution
    const distribution = new cloudfront.CloudFrontWebDistribution(this, 'CDN', {
      originConfigs: [
        {
          s3OriginSource: {
            s3BucketSource: websiteBucket,
          },
          behaviors: [{ isDefaultBehavior: true }],
        },
        {
          customOriginSource: {
            domainName: alb.loadBalancerDnsName,
            httpPort: 80,
            originProtocolPolicy: cloudfront.OriginProtocolPolicy.HTTP_ONLY,
          },
          behaviors: [
            {
              pathPattern: '/api/*',
              allowedMethods: cloudfront.CloudFrontAllowedMethods.ALL,
              forwardedValues: {
                queryString: true,
                headers: ['Authorization', 'Content-Type'],
              },
            },
          ],
        },
      ],
      errorConfigurations: [
        {
          errorCode: 404,
          responseCode: 200,
          responsePagePath: '/index.html',
        },
      ],
    });

    // 5. DNS and SSL (if domain provided)
    if (props.domainName) {
      const hostedZone = route53.HostedZone.fromLookup(this, 'HostedZone', {
        domainName: props.domainName,
      });

      const certificate = new acm.Certificate(this, 'Certificate', {
        domainName: props.domainName,
        validation: acm.CertificateValidation.fromDns(hostedZone),
      });

      new route53.ARecord(this, 'AliasRecord', {
        zone: hostedZone,
        target: route53.RecordTarget.fromAlias(
          new route53.targets.CloudFrontTarget(distribution)
        ),
      });
    }

    // Security Groups
    database.connections.allowDefaultPortFrom(
      service.connections,
      'Allow ECS to access RDS'
    );

    // Outputs
    new CfnOutput(this, 'LoadBalancerDNS', {
      value: alb.loadBalancerDnsName,
    });

    new CfnOutput(this, 'CloudFrontURL', {
      value: distribution.distributionDomainName,
    });
  }
}
```

### **2. Serverless Data Pipeline**
```typescript
// lib/data-pipeline-stack.ts
import {
  Stack,
  StackProps,
  aws_s3 as s3,
  aws_lambda as lambda,
  aws_lambda_event_sources as eventSources,
  aws_dynamodb as dynamodb,
  aws_stepfunctions as sf,
  aws_stepfunctions_tasks as sfnTasks,
  aws_events as events,
  aws_events_targets as targets,
  aws_iam as iam,
  Duration,
  RemovalPolicy,
} from 'aws-cdk-lib';
import { Construct } from 'constructs';

export class DataPipelineStack extends Stack {
  constructor(scope: Construct, id: string, props?: StackProps) {
    super(scope, id, props);

    // 1. S3 Buckets for data stages
    const rawDataBucket = new s3.Bucket(this, 'RawDataBucket', {
      bucketName: 'data-pipeline-raw-data',
      versioned: true,
      lifecycleRules: [
        {
          id: 'delete-old-versions',
          expiration: Duration.days(90),
          noncurrentVersionExpiration: Duration.days(30),
        },
      ],
    });

    const processedDataBucket = new s3.Bucket(this, 'ProcessedDataBucket', {
      bucketName: 'data-pipeline-processed-data',
      versioned: true,
    });

    // 2. DynamoDB table for metadata
    const metadataTable = new dynamodb.Table(this, 'MetadataTable', {
      partitionKey: { name: 'fileId', type: dynamodb.AttributeType.STRING },
      sortKey: { name: 'timestamp', type: dynamodb.AttributeType.NUMBER },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      pointInTimeRecovery: true,
      removalPolicy: RemovalPolicy.DESTROY,
    });

    // 3. Lambda Functions
    const dataValidatorFunction = new lambda.Function(this, 'DataValidator', {
      runtime: lambda.Runtime.PYTHON_3_9,
      handler: 'validator.handler',
      code: lambda.Code.fromAsset('lambda/data-validator'),
      timeout: Duration.minutes(5),
      environment: {
        METADATA_TABLE: metadataTable.tableName,
      },
    });

    const dataTransformerFunction = new lambda.Function(this, 'DataTransformer', {
      runtime: lambda.Runtime.PYTHON_3_9,
      handler: 'transformer.handler',
      code: lambda.Code.fromAsset('lambda/data-transformer'),
      timeout: Duration.minutes(15),
      memorySize: 1024,
      environment: {
        PROCESSED_BUCKET: processedDataBucket.bucketName,
        METADATA_TABLE: metadataTable.tableName,
      },
    });

    const notificationFunction = new lambda.Function(this, 'NotificationFunction', {
      runtime: lambda.Runtime.PYTHON_3_9,
      handler: 'notification.handler',
      code: lambda.Code.fromAsset('lambda/notification'),
      timeout: Duration.minutes(1),
    });

    // 4. Step Functions State Machine
    const validateTask = new sfnTasks.LambdaInvoke(this, 'ValidateData', {
      lambdaFunction: dataValidatorFunction,
      outputPath: '$.Payload',
    });

    const transformTask = new sfnTasks.LambdaInvoke(this, 'TransformData', {
      lambdaFunction: dataTransformerFunction,
      outputPath: '$.Payload',
    });

    const successNotification = new sfnTasks.LambdaInvoke(this, 'SuccessNotification', {
      lambdaFunction: notificationFunction,
      payload: sf.TaskInput.fromObject({
        'status': 'SUCCESS',
        'message': 'Data pipeline completed successfully',
        'input.$': '$',
      }),
    });

    const failureNotification = new sfnTasks.LambdaInvoke(this, 'FailureNotification', {
      lambdaFunction: notificationFunction,
      payload: sf.TaskInput.fromObject({
        'status': 'FAILURE',
        'message': 'Data pipeline failed',
        'error.$': '$.Error',
      }),
    });

    // Define the workflow
    const definition = validateTask
      .next(new sf.Choice(this, 'IsDataValid')
        .when(sf.Condition.booleanEquals('$.isValid', true), transformTask
          .next(successNotification))
        .otherwise(failureNotification));

    const stateMachine = new sf.StateMachine(this, 'DataPipelineStateMachine', {
      definition,
      timeout: Duration.minutes(30),
    });

    // 5. Event-driven trigger
    const triggerFunction = new lambda.Function(this, 'TriggerFunction', {
      runtime: lambda.Runtime.PYTHON_3_9,
      handler: 'trigger.handler',
      code: lambda.Code.fromAsset('lambda/trigger'),
      environment: {
        STATE_MACHINE_ARN: stateMachine.stateMachineArn,
      },
    });

    // S3 event trigger
    rawDataBucket.addEventNotification(
      s3.EventType.OBJECT_CREATED,
      new s3Notifications.LambdaDestination(triggerFunction),
      { prefix: 'incoming/', suffix: '.json' }
    );

    // Scheduled trigger for batch processing
    new events.Rule(this, 'ScheduledTrigger', {
      schedule: events.Schedule.cron({ 
        minute: '0', 
        hour: '2' // Run at 2 AM daily
      }),
      targets: [new targets.LambdaFunction(triggerFunction, {
        event: events.RuleTargetInput.fromObject({
          source: 'scheduled',
          batchMode: true,
        }),
      })],
    });

    // 6. Permissions
    rawDataBucket.grantRead(dataValidatorFunction);
    rawDataBucket.grantRead(dataTransformerFunction);
    processedDataBucket.grantWrite(dataTransformerFunction);
    metadataTable.grantReadWriteData(dataValidatorFunction);
    metadataTable.grantReadWriteData(dataTransformerFunction);
    stateMachine.grantStartExecution(triggerFunction);

    // IAM role for Step Functions
    stateMachine.addToRolePolicy(new iam.PolicyStatement({
      effect: iam.Effect.ALLOW,
      actions: ['lambda:InvokeFunction'],
      resources: [
        dataValidatorFunction.functionArn,
        dataTransformerFunction.functionArn,
        notificationFunction.functionArn,
      ],
    }));
  }
}
```

## Advanced Features

### **1. Custom Constructs**
```typescript
// lib/constructs/monitoring-stack.ts
import { Construct } from 'constructs';
import {
  aws_cloudwatch as cloudwatch,
  aws_cloudwatch_actions as cwActions,
  aws_sns as sns,
  aws_logs as logs,
  Duration,
} from 'aws-cdk-lib';

export interface MonitoringProps {
  applicationName: string;
  alertEmail: string;
  logGroups: logs.LogGroup[];
  errorMetrics: cloudwatch.Metric[];
}

export class Monitoring extends Construct {
  public readonly dashboard: cloudwatch.Dashboard;
  public readonly alertTopic: sns.Topic;

  constructor(scope: Construct, id: string, props: MonitoringProps) {
    super(scope, id);

    // SNS Topic for alerts
    this.alertTopic = new sns.Topic(this, 'AlertTopic', {
      displayName: `${props.applicationName} Alerts`,
    });

    this.alertTopic.addSubscription(
      new snsSubscriptions.EmailSubscription(props.alertEmail)
    );

    // CloudWatch Dashboard
    this.dashboard = new cloudwatch.Dashboard(this, 'Dashboard', {
      dashboardName: `${props.applicationName}-monitoring`,
    });

    // Add widgets to dashboard
    props.errorMetrics.forEach((metric, index) => {
      this.dashboard.addWidgets(
        new cloudwatch.GraphWidget({
          title: `Error Rate - ${metric.metricName}`,
          left: [metric],
          width: 12,
          height: 6,
        })
      );

      // Create alarm for each error metric
      const alarm = new cloudwatch.Alarm(this, `ErrorAlarm${index}`, {
        metric: metric,
        threshold: 10,
        evaluationPeriods: 2,
        treatMissingData: cloudwatch.TreatMissingData.NOT_BREACHING,
      });

      alarm.addAlarmAction(new cwActions.SnsAction(this.alertTopic));
    });

    // Log Insights queries
    props.logGroups.forEach((logGroup, index) => {
      this.dashboard.addWidgets(
        new cloudwatch.LogQueryWidget({
          title: `Error Analysis - ${logGroup.logGroupName}`,
          logGroups: [logGroup],
          queryLines: [
            'fields @timestamp, @message',
            'filter @message like /ERROR/',
            'sort @timestamp desc',
            'limit 100',
          ],
          width: 24,
          height: 6,
        })
      );
    });
  }
}

// Usage in stack
const monitoring = new Monitoring(this, 'Monitoring', {
  applicationName: 'MyWebApp',
  alertEmail: 'alerts@mycompany.com',
  logGroups: [serviceLogGroup, lambdaLogGroup],
  errorMetrics: [serviceErrorMetric, databaseErrorMetric],
});
```

### **2. Testing CDK Applications**
```typescript
// test/web-application-stack.test.ts
import { Template, Match } from 'aws-cdk-lib/assertions';
import { App } from 'aws-cdk-lib';
import { WebApplicationStack } from '../lib/web-application-stack';

describe('WebApplicationStack', () => {
  let template: Template;
  
  beforeAll(() => {
    const app = new App();
    const stack = new WebApplicationStack(app, 'TestStack', {
      stage: 'test',
    });
    template = Template.fromStack(stack);
  });

  test('Creates VPC with correct configuration', () => {
    template.hasResourceProperties('AWS::EC2::VPC', {
      CidrBlock: '10.0.0.0/16',
      EnableDnsHostnames: true,
      EnableDnsSupport: true,
    });
  });

  test('Creates RDS instance with encryption', () => {
    template.hasResourceProperties('AWS::RDS::DBInstance', {
      StorageEncrypted: true,
      Engine: 'postgres',
    });
  });

  test('Creates Application Load Balancer', () => {
    template.resourceCountIs('AWS::ElasticLoadBalancingV2::LoadBalancer', 1);
    
    template.hasResourceProperties('AWS::ElasticLoadBalancingV2::LoadBalancer', {
      Scheme: 'internet-facing',
      Type: 'application',
    });
  });

  test('Creates ECS Service with Auto Scaling', () => {
    template.hasResourceProperties('AWS::ECS::Service', {
      LaunchType: 'EC2',
      DesiredCount: 1, // test stage
    });

    template.hasResource('AWS::ApplicationAutoScaling::ScalableTarget', {});
    template.hasResource('AWS::ApplicationAutoScaling::ScalingPolicy', {});
  });

  test('Creates S3 bucket for frontend', () => {
    template.hasResourceProperties('AWS::S3::Bucket', {
      WebsiteConfiguration: {
        IndexDocument: 'index.html',
        ErrorDocument: 'error.html',
      },
    });
  });

  test('Creates CloudFront distribution', () => {
    template.hasResourceProperties('AWS::CloudFront::Distribution', {
      DistributionConfig: {
        Enabled: true,
        Origins: Match.arrayWith([
          Match.objectLike({
            DomainName: Match.anyValue(),
            S3OriginConfig: Match.anyValue(),
          }),
          Match.objectLike({
            DomainName: Match.anyValue(),
            CustomOriginConfig: Match.anyValue(),
          }),
        ]),
      },
    });
  });

  test('Security groups allow proper access', () => {
    // Check that ECS security group can access RDS
    template.hasResourceProperties('AWS::EC2::SecurityGroupIngress', {
      IpProtocol: 'tcp',
      FromPort: 5432,
      ToPort: 5432,
    });
  });

  test('Environment-specific configuration', () => {
    const prodApp = new App();
    const prodStack = new WebApplicationStack(prodApp, 'ProdStack', {
      stage: 'prod',
    });
    const prodTemplate = Template.fromStack(prodStack);

    // Production should have multi-AZ RDS
    prodTemplate.hasResourceProperties('AWS::RDS::DBInstance', {
      MultiAZ: true,
      DeletionProtection: true,
    });

    // Production should have more NAT Gateways
    prodTemplate.resourceCountIs('AWS::EC2::NatGateway', 3);
  });
});
```

## Deployment Strategies

### **1. CI/CD with GitHub Actions**
```yaml
# .github/workflows/cdk-deploy.yml
name: CDK Deploy

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '18'
        cache: 'npm'
    
    - name: Install dependencies
      run: npm ci
    
    - name: Run tests
      run: npm test
    
    - name: Run CDK synth
      run: npm run cdk synth
      env:
        AWS_DEFAULT_REGION: us-west-2

  deploy-dev:
    if: github.ref == 'refs/heads/develop'
    needs: test
    runs-on: ubuntu-latest
    environment: development
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '18'
        cache: 'npm'
    
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v2
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: us-west-2
    
    - name: Install dependencies
      run: npm ci
    
    - name: Deploy to development
      run: npm run cdk deploy -- --all --require-approval never
      env:
        STAGE: dev

  deploy-prod:
    if: github.ref == 'refs/heads/main'
    needs: test
    runs-on: ubuntu-latest
    environment: production
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '18'
        cache: 'npm'
    
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v2
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID_PROD }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY_PROD }}
        aws-region: us-east-1
    
    - name: Install dependencies
      run: npm ci
    
    - name: Deploy to production
      run: npm run cdk deploy -- --all --require-approval never
      env:
        STAGE: prod
```

### **2. Blue/Green Deployment**
```typescript
// lib/blue-green-stack.ts
import {
  Stack,
  StackProps,
  aws_codedeploy as codedeploy,
  aws_ecs as ecs,
  aws_elasticloadbalancingv2 as elbv2,
} from 'aws-cdk-lib';

export class BlueGreenStack extends Stack {
  constructor(scope: Construct, id: string, props?: StackProps) {
    super(scope, id, props);

    // ECS Service with CodeDeploy
    const service = new ecs.FargateService(this, 'Service', {
      // ... service configuration
      deploymentController: {
        type: ecs.DeploymentControllerType.CODE_DEPLOY,
      },
    });

    // Application Load Balancer with two target groups
    const blueTargetGroup = new elbv2.ApplicationTargetGroup(this, 'BlueTargetGroup', {
      port: 80,
      vpc: vpc,
      targetType: elbv2.TargetType.IP,
      healthCheckPath: '/health',
    });

    const greenTargetGroup = new elbv2.ApplicationTargetGroup(this, 'GreenTargetGroup', {
      port: 80,
      vpc: vpc,
      targetType: elbv2.TargetType.IP,
      healthCheckPath: '/health',
    });

    // CodeDeploy Application
    const application = new codedeploy.EcsApplication(this, 'Application', {
      applicationName: 'my-ecs-application',
    });

    // CodeDeploy Deployment Group
    const deploymentGroup = new codedeploy.EcsDeploymentGroup(this, 'DeploymentGroup', {
      application: application,
      service: service,
      blueGreenDeploymentConfig: {
        blueTargetGroup: blueTargetGroup,
        greenTargetGroup: greenTargetGroup,
        listener: listener,
        testListener: testListener,
        deploymentApprovalWaitTime: Duration.minutes(15),
        terminationWaitTime: Duration.minutes(5),
      },
      autoRollbackConfig: {
        deploymentInAlarm: true,
        stoppedDeployment: true,
        failedDeployment: true,
      },
    });
  }
}
```

## Best Practices

### **1. Security**
```typescript
// Security best practices
import { 
  aws_iam as iam,
  aws_s3 as s3,
  aws_kms as kms,
} from 'aws-cdk-lib';

// Least privilege IAM
const lambdaRole = new iam.Role(this, 'LambdaRole', {
  assumedBy: new iam.ServicePrincipal('lambda.amazonaws.com'),
  managedPolicies: [
    iam.ManagedPolicy.fromAwsManagedPolicyName('service-role/AWSLambdaBasicExecutionRole'),
  ],
  inlinePolicies: {
    'DynamoDBAccess': new iam.PolicyDocument({
      statements: [
        new iam.PolicyStatement({
          effect: iam.Effect.ALLOW,
          actions: ['dynamodb:GetItem', 'dynamodb:PutItem'],
          resources: [table.tableArn],
          conditions: {
            'ForAllValues:StringEquals': {
              'dynamodb:Attributes': ['id', 'data', 'timestamp'],
            },
          },
        }),
      ],
    }),
  },
});

// KMS encryption
const kmsKey = new kms.Key(this, 'MyKey', {
  enableKeyRotation: true,
  description: 'KMS key for application encryption',
});

// Secure S3 bucket
const secureBucket = new s3.Bucket(this, 'SecureBucket', {
  encryption: s3.BucketEncryption.KMS,
  encryptionKey: kmsKey,
  blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
  enforceSSL: true,
  versioned: true,
});
```

### **2. Environment Configuration**
```typescript
// lib/config.ts
export interface EnvironmentConfig {
  instanceType: string;
  minCapacity: number;
  maxCapacity: number;
  multiAz: boolean;
  deletionProtection: boolean;
  backupRetention: number;
}

export const environments: Record<string, EnvironmentConfig> = {
  dev: {
    instanceType: 't3.micro',
    minCapacity: 1,
    maxCapacity: 2,
    multiAz: false,
    deletionProtection: false,
    backupRetention: 1,
  },
  staging: {
    instanceType: 't3.small',
    minCapacity: 1,
    maxCapacity: 3,
    multiAz: false,
    deletionProtection: false,
    backupRetention: 7,
  },
  prod: {
    instanceType: 't3.large',
    minCapacity: 3,
    maxCapacity: 10,
    multiAz: true,
    deletionProtection: true,
    backupRetention: 30,
  },
};

// Usage in stack
const config = environments[props.stage] || environments.dev;
```

## Useful Commands

```bash
# Development
npm run build        # Compile TypeScript
npm run watch        # Watch for changes
npm test            # Run unit tests
npm run test -- --watch  # Watch tests

# CDK Commands
cdk ls              # List stacks
cdk synth           # Synthesize CloudFormation
cdk diff            # Show differences
cdk deploy          # Deploy stack
cdk destroy         # Destroy stack
cdk bootstrap       # Bootstrap environment

# Advanced
cdk deploy --hotswap    # Fast deployments for development
cdk import              # Import existing resources
cdk migrate             # Migrate from CloudFormation
```

## Useful Links

- [AWS CDK Documentation](https://docs.aws.amazon.com/cdk/)
- [CDK Patterns](https://cdkpatterns.com/)
- [Construct Hub](https://constructs.dev/)
- [CDK Examples](https://github.com/aws-samples/aws-cdk-examples)
