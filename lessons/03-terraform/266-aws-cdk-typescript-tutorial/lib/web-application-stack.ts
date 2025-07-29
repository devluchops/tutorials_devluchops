import * as cdk from 'aws-cdk-lib';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as elbv2 from 'aws-cdk-lib/aws-elasticloadbalancingv2';
import * as autoscaling from 'aws-cdk-lib/aws-autoscaling';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as rds from 'aws-cdk-lib/aws-rds';
import * as cloudwatch from 'aws-cdk-lib/aws-cloudwatch';
import * as route53 from 'aws-cdk-lib/aws-route53';
import * as acm from 'aws-cdk-lib/aws-certificatemanager';
import * as route53Targets from 'aws-cdk-lib/aws-route53-targets';
import { Construct } from 'constructs';

export interface WebApplicationStackProps extends cdk.StackProps {
  vpc: ec2.IVpc;
  database: rds.IDatabaseInstance;
  webConfig: {
    instanceType: string;
    minCapacity: number;
    maxCapacity: number;
    desiredCapacity: number;
    keyPairName?: string;
    enableSsl: boolean;
    domainName?: string;
  };
}

export class WebApplicationStack extends cdk.Stack {
  public readonly loadBalancer: elbv2.ApplicationLoadBalancer;
  public readonly autoScalingGroup: autoscaling.AutoScalingGroup;
  public readonly targetGroup: elbv2.ApplicationTargetGroup;

  constructor(scope: Construct, id: string, props: WebApplicationStackProps) {
    super(scope, id, props);

    // Create security group for web servers
    const webSecurityGroup = new ec2.SecurityGroup(this, 'WebSecurityGroup', {
      vpc: props.vpc,
      description: 'Security group for web servers',
      allowAllOutbound: true,
    });

    webSecurityGroup.addIngressRule(
      ec2.Peer.anyIpv4(),
      ec2.Port.tcp(80),
      'Allow HTTP traffic'
    );

    webSecurityGroup.addIngressRule(
      ec2.Peer.anyIpv4(),
      ec2.Port.tcp(443),
      'Allow HTTPS traffic'
    );

    if (props.webConfig.keyPairName) {
      webSecurityGroup.addIngressRule(
        ec2.Peer.ipv4(props.vpc.vpcCidrBlock),
        ec2.Port.tcp(22),
        'Allow SSH from VPC'
      );
    }

    // Create IAM role for EC2 instances
    const webServerRole = new iam.Role(this, 'WebServerRole', {
      assumedBy: new iam.ServicePrincipal('ec2.amazonaws.com'),
      managedPolicies: [
        iam.ManagedPolicy.fromAwsManagedPolicyName('CloudWatchAgentServerPolicy'),
        iam.ManagedPolicy.fromAwsManagedPolicyName('AmazonSSMManagedInstanceCore'),
      ],
    });

    // Add custom policy for application needs
    webServerRole.addToPolicy(new iam.PolicyStatement({
      effect: iam.Effect.ALLOW,
      actions: [
        'secretsmanager:GetSecretValue',
        's3:GetObject',
        's3:PutObject',
        'cloudwatch:PutMetricData',
        'logs:PutLogEvents',
        'logs:CreateLogGroup',
        'logs:CreateLogStream',
      ],
      resources: ['*'],
    }));

    // Create instance profile
    const instanceProfile = new iam.InstanceProfile(this, 'WebServerInstanceProfile', {
      role: webServerRole,
    });

    // User data script for web servers
    const userData = ec2.UserData.forLinux();
    userData.addCommands(
      '#!/bin/bash',
      'yum update -y',
      'yum install -y httpd php php-mysqlnd amazon-cloudwatch-agent',
      
      // Install and configure CloudWatch agent
      'wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm',
      'rpm -U ./amazon-cloudwatch-agent.rpm',
      
      // Create CloudWatch config
      'cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << EOF',
      JSON.stringify({
        agent: {
          metrics_collection_interval: 60,
          run_as_user: 'cwagent'
        },
        metrics: {
          namespace: 'CWAgent',
          metrics_collected: {
            cpu: {
              measurement: [
                'cpu_usage_idle',
                'cpu_usage_iowait',
                'cpu_usage_user',
                'cpu_usage_system'
              ],
              metrics_collection_interval: 60,
              totalcpu: false
            },
            disk: {
              measurement: [
                'used_percent'
              ],
              metrics_collection_interval: 60,
              resources: ['*']
            },
            diskio: {
              measurement: [
                'io_time'
              ],
              metrics_collection_interval: 60,
              resources: ['*']
            },
            mem: {
              measurement: [
                'mem_used_percent'
              ],
              metrics_collection_interval: 60
            }
          }
        },
        logs: {
          logs_collected: {
            files: {
              collect_list: [
                {
                  file_path: '/var/log/httpd/access_log',
                  log_group_name: `/${this.stackName}/httpd/access_log`,
                  log_stream_name: '{instance_id}'
                },
                {
                  file_path: '/var/log/httpd/error_log',
                  log_group_name: `/${this.stackName}/httpd/error_log`,
                  log_stream_name: '{instance_id}'
                }
              ]
            }
          }
        }
      }),
      'EOF',
      
      // Start CloudWatch agent
      '/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s',
      
      // Configure and start web server
      'systemctl start httpd',
      'systemctl enable httpd',
      
      // Create a simple PHP application
      'cat > /var/www/html/index.php << EOF',
      '<?php',
      'echo "<h1>Hello from AWS CDK Web Server!</h1>";',
      'echo "<p>Instance ID: " . file_get_contents("http://169.254.169.254/latest/meta-data/instance-id") . "</p>";',
      'echo "<p>Availability Zone: " . file_get_contents("http://169.254.169.254/latest/meta-data/placement/availability-zone") . "</p>";',
      `echo "<p>Database Endpoint: ${props.database.instanceEndpoint.hostname}</p>";`,
      'echo "<p>Timestamp: " . date("Y-m-d H:i:s") . "</p>";',
      
      // Test database connection
      '$servername = "' + props.database.instanceEndpoint.hostname + '";',
      '$username = "admin";',
      '$password = "your-password-here"; // In production, use AWS Secrets Manager',
      '$dbname = "webapp";',
      '',
      'try {',
      '    $pdo = new PDO("mysql:host=$servername;dbname=$dbname", $username, $password);',
      '    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);',
      '    echo "<p style=\\"color: green;\\">Database connection: SUCCESS</p>";',
      '} catch(PDOException $e) {',
      '    echo "<p style=\\"color: red;\\">Database connection failed: " . $e->getMessage() . "</p>";',
      '}',
      '?>',
      'EOF',
      
      // Create health check endpoint
      'cat > /var/www/html/health.php << EOF',
      '<?php',
      'http_response_code(200);',
      'echo json_encode(["status" => "healthy", "timestamp" => time()]);',
      'EOF',
      
      // Set permissions
      'chown -R apache:apache /var/www/html/',
      'chmod -R 755 /var/www/html/',
      
      // Configure log rotation
      'cat > /etc/logrotate.d/httpd << EOF',
      '/var/log/httpd/*log {',
      '    daily',
      '    rotate 30',
      '    compress',
      '    delaycompress',
      '    missingok',
      '    notifempty',
      '    create 640 apache apache',
      '    postrotate',
      '        systemctl reload httpd',
      '    endscript',
      '}',
      'EOF'
    );

    // Create Launch Template
    const launchTemplate = new ec2.LaunchTemplate(this, 'WebServerLaunchTemplate', {
      instanceType: new ec2.InstanceType(props.webConfig.instanceType),
      machineImage: ec2.MachineImage.latestAmazonLinux({
        generation: ec2.AmazonLinuxGeneration.AMAZON_LINUX_2,
      }),
      userData,
      role: webServerRole,
      securityGroup: webSecurityGroup,
      keyName: props.webConfig.keyPairName,
      blockDevices: [
        {
          deviceName: '/dev/xvda',
          volume: ec2.BlockDeviceVolume.ebs(20, {
            volumeType: ec2.EbsDeviceVolumeType.GP3,
            encrypted: true,
            deleteOnTermination: true,
          }),
        },
      ],
    });

    // Create Auto Scaling Group
    this.autoScalingGroup = new autoscaling.AutoScalingGroup(this, 'WebServerAutoScalingGroup', {
      vpc: props.vpc,
      launchTemplate,
      minCapacity: props.webConfig.minCapacity,
      maxCapacity: props.webConfig.maxCapacity,
      desiredCapacity: props.webConfig.desiredCapacity,
      vpcSubnets: {
        subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS,
      },
      healthCheck: autoscaling.HealthCheck.elb({
        grace: cdk.Duration.minutes(5),
      }),
      updatePolicy: autoscaling.UpdatePolicy.rollingUpdate({
        maxBatchSize: 1,
        minInstancesInService: 1,
        pauseTime: cdk.Duration.minutes(5),
      }),
    });

    // Add scaling policies
    const scaleUpPolicy = this.autoScalingGroup.scaleOnCpuUtilization('ScaleUpPolicy', {
      targetUtilizationPercent: 70,
      scaleInCooldown: cdk.Duration.minutes(5),
      scaleOutCooldown: cdk.Duration.minutes(3),
    });

    // Create Application Load Balancer
    this.loadBalancer = new elbv2.ApplicationLoadBalancer(this, 'WebApplicationLoadBalancer', {
      vpc: props.vpc,
      internetFacing: true,
      vpcSubnets: {
        subnetType: ec2.SubnetType.PUBLIC,
      },
    });

    // Create Target Group
    this.targetGroup = new elbv2.ApplicationTargetGroup(this, 'WebServerTargetGroup', {
      vpc: props.vpc,
      port: 80,
      protocol: elbv2.ApplicationProtocol.HTTP,
      targets: [this.autoScalingGroup],
      healthCheck: {
        path: '/health.php',
        healthyHttpCodes: '200',
        interval: cdk.Duration.seconds(30),
        timeout: cdk.Duration.seconds(5),
        healthyThresholdCount: 2,
        unhealthyThresholdCount: 3,
      },
      stickinessCookieDuration: cdk.Duration.hours(1),
    });

    // Create SSL certificate if domain is provided
    let certificate: acm.ICertificate | undefined;
    if (props.webConfig.domainName && props.webConfig.enableSsl) {
      certificate = new acm.Certificate(this, 'WebsiteCertificate', {
        domainName: props.webConfig.domainName,
        validation: acm.CertificateValidation.fromDns(),
      });
    }

    // Create listeners
    if (certificate) {
      // HTTPS listener
      this.loadBalancer.addListener('HttpsListener', {
        port: 443,
        protocol: elbv2.ApplicationProtocol.HTTPS,
        certificates: [certificate],
        defaultTargetGroups: [this.targetGroup],
      });

      // HTTP listener with redirect to HTTPS
      this.loadBalancer.addListener('HttpListener', {
        port: 80,
        protocol: elbv2.ApplicationProtocol.HTTP,
        defaultAction: elbv2.ListenerAction.redirect({
          protocol: 'HTTPS',
          port: '443',
          permanent: true,
        }),
      });
    } else {
      // HTTP listener only
      this.loadBalancer.addListener('HttpListener', {
        port: 80,
        protocol: elbv2.ApplicationProtocol.HTTP,
        defaultTargetGroups: [this.targetGroup],
      });
    }

    // Create Route 53 record if domain is provided
    if (props.webConfig.domainName) {
      const hostedZone = route53.HostedZone.fromLookup(this, 'HostedZone', {
        domainName: props.webConfig.domainName,
      });

      new route53.ARecord(this, 'WebsiteAliasRecord', {
        zone: hostedZone,
        recordName: props.webConfig.domainName,
        target: route53.RecordTarget.fromAlias(
          new route53Targets.LoadBalancerTarget(this.loadBalancer)
        ),
      });
    }

    // Add tags
    cdk.Tags.of(this.autoScalingGroup).add('Name', `${this.stackName}-web-server`);
    cdk.Tags.of(this.loadBalancer).add('Name', `${this.stackName}-alb`);
    cdk.Tags.of(this).add('Component', 'WebApplication');

    // Outputs
    new cdk.CfnOutput(this, 'LoadBalancerDNS', {
      value: this.loadBalancer.loadBalancerDnsName,
      description: 'Load Balancer DNS Name',
    });

    new cdk.CfnOutput(this, 'WebsiteURL', {
      value: props.webConfig.enableSsl && props.webConfig.domainName 
        ? `https://${props.webConfig.domainName}`
        : `http://${this.loadBalancer.loadBalancerDnsName}`,
      description: 'Website URL',
    });
  }
}
