import * as cdk from 'aws-cdk-lib';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as logs from 'aws-cdk-lib/aws-logs';
import { Construct } from 'constructs';

export interface VpcStackProps extends cdk.StackProps {
  vpcConfig: {
    cidr: string;
    maxAzs: number;
    enableNatGateway: boolean;
    enableVpnGateway: boolean;
    createFlowLogs: boolean;
  };
}

export class VpcStack extends cdk.Stack {
  public readonly vpc: ec2.Vpc;
  public readonly publicSubnets: ec2.ISubnet[];
  public readonly privateSubnets: ec2.ISubnet[];
  public readonly isolatedSubnets: ec2.ISubnet[];

  constructor(scope: Construct, id: string, props: VpcStackProps) {
    super(scope, id, props);

    // Create VPC
    this.vpc = new ec2.Vpc(this, 'VPC', {
      ipAddresses: ec2.IpAddresses.cidr(props.vpcConfig.cidr),
      maxAzs: props.vpcConfig.maxAzs,
      enableDnsHostnames: true,
      enableDnsSupport: true,
      subnetConfiguration: [
        {
          cidrMask: 24,
          name: 'Public',
          subnetType: ec2.SubnetType.PUBLIC,
        },
        {
          cidrMask: 24,
          name: 'Private',
          subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS,
        },
        {
          cidrMask: 28,
          name: 'Isolated',
          subnetType: ec2.SubnetType.PRIVATE_ISOLATED,
        },
      ],
      natGateways: props.vpcConfig.enableNatGateway ? props.vpcConfig.maxAzs : 0,
      vpnGateway: props.vpcConfig.enableVpnGateway,
    });

    // Store subnet references
    this.publicSubnets = this.vpc.publicSubnets;
    this.privateSubnets = this.vpc.privateSubnets;
    this.isolatedSubnets = this.vpc.isolatedSubnets;

    // Create VPC Flow Logs if enabled
    if (props.vpcConfig.createFlowLogs) {
      const flowLogsRole = new cdk.aws_iam.Role(this, 'FlowLogsRole', {
        assumedBy: new cdk.aws_iam.ServicePrincipal('vpc-flow-logs.amazonaws.com'),
        managedPolicies: [
          cdk.aws_iam.ManagedPolicy.fromAwsManagedPolicyName('service-role/VPCFlowLogsDeliveryRolePolicy'),
        ],
      });

      const flowLogsGroup = new logs.LogGroup(this, 'VpcFlowLogsGroup', {
        logGroupName: `/aws/vpc/flowlogs/${this.stackName}`,
        retention: logs.RetentionDays.ONE_WEEK,
        removalPolicy: cdk.RemovalPolicy.DESTROY,
      });

      new ec2.FlowLog(this, 'VpcFlowLogs', {
        resourceType: ec2.FlowLogResourceType.fromVpc(this.vpc),
        destination: ec2.FlowLogDestination.toCloudWatchLogs(flowLogsGroup, flowLogsRole),
        trafficType: ec2.FlowLogTrafficType.ALL,
      });
    }

    // Create Security Groups
    this.createSecurityGroups();

    // Create VPC Endpoints for cost optimization
    this.createVpcEndpoints();

    // Add tags
    cdk.Tags.of(this.vpc).add('Name', `${this.stackName}-vpc`);
    cdk.Tags.of(this).add('Component', 'Networking');
  }

  private createSecurityGroups(): void {
    // Web tier security group
    const webSecurityGroup = new ec2.SecurityGroup(this, 'WebSecurityGroup', {
      vpc: this.vpc,
      description: 'Security group for web tier',
      allowAllOutbound: true,
    });

    webSecurityGroup.addIngressRule(
      ec2.Peer.anyIpv4(),
      ec2.Port.tcp(80),
      'Allow HTTP traffic from anywhere'
    );

    webSecurityGroup.addIngressRule(
      ec2.Peer.anyIpv4(),
      ec2.Port.tcp(443),
      'Allow HTTPS traffic from anywhere'
    );

    webSecurityGroup.addIngressRule(
      ec2.Peer.ipv4(this.vpc.vpcCidrBlock),
      ec2.Port.tcp(22),
      'Allow SSH from VPC'
    );

    // Application tier security group
    const appSecurityGroup = new ec2.SecurityGroup(this, 'AppSecurityGroup', {
      vpc: this.vpc,
      description: 'Security group for application tier',
      allowAllOutbound: true,
    });

    appSecurityGroup.addIngressRule(
      webSecurityGroup,
      ec2.Port.tcp(8080),
      'Allow traffic from web tier'
    );

    appSecurityGroup.addIngressRule(
      ec2.Peer.ipv4(this.vpc.vpcCidrBlock),
      ec2.Port.tcp(22),
      'Allow SSH from VPC'
    );

    // Database tier security group
    const dbSecurityGroup = new ec2.SecurityGroup(this, 'DatabaseSecurityGroup', {
      vpc: this.vpc,
      description: 'Security group for database tier',
      allowAllOutbound: false,
    });

    dbSecurityGroup.addIngressRule(
      appSecurityGroup,
      ec2.Port.tcp(5432),
      'Allow PostgreSQL from application tier'
    );

    dbSecurityGroup.addIngressRule(
      appSecurityGroup,
      ec2.Port.tcp(3306),
      'Allow MySQL from application tier'
    );

    // Lambda security group
    const lambdaSecurityGroup = new ec2.SecurityGroup(this, 'LambdaSecurityGroup', {
      vpc: this.vpc,
      description: 'Security group for Lambda functions',
      allowAllOutbound: true,
    });

    // Export security groups for use in other stacks
    new cdk.CfnOutput(this, 'WebSecurityGroupId', {
      value: webSecurityGroup.securityGroupId,
      exportName: `${this.stackName}-web-sg-id`,
    });

    new cdk.CfnOutput(this, 'AppSecurityGroupId', {
      value: appSecurityGroup.securityGroupId,
      exportName: `${this.stackName}-app-sg-id`,
    });

    new cdk.CfnOutput(this, 'DatabaseSecurityGroupId', {
      value: dbSecurityGroup.securityGroupId,
      exportName: `${this.stackName}-db-sg-id`,
    });

    new cdk.CfnOutput(this, 'LambdaSecurityGroupId', {
      value: lambdaSecurityGroup.securityGroupId,
      exportName: `${this.stackName}-lambda-sg-id`,
    });
  }

  private createVpcEndpoints(): void {
    // S3 Gateway Endpoint (free)
    this.vpc.addGatewayEndpoint('S3Endpoint', {
      service: ec2.GatewayVpcEndpointAwsService.S3,
      subnets: [
        {
          subnets: this.privateSubnets,
        },
      ],
    });

    // DynamoDB Gateway Endpoint (free)
    this.vpc.addGatewayEndpoint('DynamoDBEndpoint', {
      service: ec2.GatewayVpcEndpointAwsService.DYNAMODB,
      subnets: [
        {
          subnets: this.privateSubnets,
        },
      ],
    });

    // Interface endpoints (cost money but provide better security)
    const interfaceEndpoints = [
      {
        service: ec2.InterfaceVpcEndpointAwsService.EC2,
        name: 'EC2Endpoint',
      },
      {
        service: ec2.InterfaceVpcEndpointAwsService.ECR,
        name: 'ECREndpoint',
      },
      {
        service: ec2.InterfaceVpcEndpointAwsService.ECR_DOCKER,
        name: 'ECRDockerEndpoint',
      },
      {
        service: ec2.InterfaceVpcEndpointAwsService.CLOUDWATCH,
        name: 'CloudWatchEndpoint',
      },
      {
        service: ec2.InterfaceVpcEndpointAwsService.CLOUDWATCH_LOGS,
        name: 'CloudWatchLogsEndpoint',
      },
    ];

    interfaceEndpoints.forEach(endpoint => {
      this.vpc.addInterfaceEndpoint(endpoint.name, {
        service: endpoint.service,
        subnets: {
          subnets: this.privateSubnets,
        },
        privateDnsEnabled: true,
      });
    });
  }

  public getSecurityGroupById(id: string): ec2.ISecurityGroup {
    return ec2.SecurityGroup.fromSecurityGroupId(this, `ImportedSG-${id}`, id);
  }

  public createCustomSecurityGroup(
    id: string,
    description: string,
    rules: Array<{
      type: 'ingress' | 'egress';
      peer: ec2.IPeer;
      port: ec2.Port;
      description: string;
    }>
  ): ec2.SecurityGroup {
    const sg = new ec2.SecurityGroup(this, id, {
      vpc: this.vpc,
      description,
      allowAllOutbound: false,
    });

    rules.forEach(rule => {
      if (rule.type === 'ingress') {
        sg.addIngressRule(rule.peer, rule.port, rule.description);
      } else {
        sg.addEgressRule(rule.peer, rule.port, rule.description);
      }
    });

    return sg;
  }
}
