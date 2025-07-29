# Dynamic Infrastructure with Python
import pulumi
import pulumi_aws as aws
import json

# Configuration
config = pulumi.Config()
environments = config.require_object("environments")

def create_environment_resources(env_name: str, env_config: dict):
    """Create resources for a specific environment"""
    
    # VPC
    vpc = aws.ec2.Vpc(f"vpc-{env_name}",
        cidr_block=env_config["cidr"],
        enable_dns_hostnames=True,
        enable_dns_support=True,
        tags={
            "Name": f"vpc-{env_name}",
            "Environment": env_name
        }
    )
    
    # Internet Gateway
    igw = aws.ec2.InternetGateway(f"igw-{env_name}",
        vpc_id=vpc.id,
        tags={
            "Name": f"igw-{env_name}",
            "Environment": env_name
        }
    )
    
    # Subnets
    subnets = []
    for i, az in enumerate(env_config["availability_zones"]):
        subnet = aws.ec2.Subnet(f"subnet-{env_name}-{i}",
            vpc_id=vpc.id,
            cidr_block=f"{env_config['cidr'][:-4]}{i+1}.0/24",
            availability_zone=az,
            map_public_ip_on_launch=True,
            tags={
                "Name": f"subnet-{env_name}-{az}",
                "Environment": env_name,
                "Type": "public"
            }
        )
        subnets.append(subnet)
    
    # Route Table
    route_table = aws.ec2.RouteTable(f"rt-{env_name}",
        vpc_id=vpc.id,
        routes=[
            aws.ec2.RouteTableRouteArgs(
                cidr_block="0.0.0.0/0",
                gateway_id=igw.id,
            )
        ],
        tags={
            "Name": f"rt-{env_name}",
            "Environment": env_name
        }
    )
    
    # Associate subnets with route table
    for i, subnet in enumerate(subnets):
        aws.ec2.RouteTableAssociation(f"rta-{env_name}-{i}",
            subnet_id=subnet.id,
            route_table_id=route_table.id
        )
    
    # Security Group
    security_group = aws.ec2.SecurityGroup(f"sg-{env_name}",
        vpc_id=vpc.id,
        description=f"Security group for {env_name} environment",
        ingress=[
            aws.ec2.SecurityGroupIngressArgs(
                protocol="tcp",
                from_port=80,
                to_port=80,
                cidr_blocks=["0.0.0.0/0"],
            ),
            aws.ec2.SecurityGroupIngressArgs(
                protocol="tcp",
                from_port=443,
                to_port=443,
                cidr_blocks=["0.0.0.0/0"],
            ),
            aws.ec2.SecurityGroupIngressArgs(
                protocol="tcp",
                from_port=22,
                to_port=22,
                cidr_blocks=["10.0.0.0/8"],
            ),
        ],
        egress=[
            aws.ec2.SecurityGroupEgressArgs(
                protocol="-1",
                from_port=0,
                to_port=0,
                cidr_blocks=["0.0.0.0/0"],
            )
        ],
        tags={
            "Name": f"sg-{env_name}",
            "Environment": env_name
        }
    )
    
    # Launch Template
    user_data = f"""#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
echo "<h1>Hello from {env_name} environment!</h1>" > /var/www/html/index.html
"""
    
    launch_template = aws.ec2.LaunchTemplate(f"lt-{env_name}",
        image_id=env_config["ami_id"],
        instance_type=env_config["instance_type"],
        vpc_security_group_ids=[security_group.id],
        user_data=pulumi.Output.secret(user_data).apply(lambda x: 
            __import__('base64').b64encode(x.encode()).decode()),
        tag_specifications=[
            aws.ec2.LaunchTemplateTagSpecificationArgs(
                resource_type="instance",
                tags={
                    "Name": f"instance-{env_name}",
                    "Environment": env_name,
                    "LaunchedBy": "autoscaling"
                }
            )
        ],
        tags={
            "Name": f"lt-{env_name}",
            "Environment": env_name
        }
    )
    
    # Auto Scaling Group (if enabled)
    if env_config.get("auto_scaling", False):
        asg = aws.autoscaling.Group(f"asg-{env_name}",
            desired_capacity=env_config["instance_count"],
            max_size=env_config["max_instances"],
            min_size=env_config["min_instances"],
            vpc_zone_identifiers=[s.id for s in subnets],
            launch_template=aws.autoscaling.GroupLaunchTemplateArgs(
                id=launch_template.id,
                version="$Latest"
            ),
            health_check_type="ELB",
            health_check_grace_period=300,
            tags=[
                aws.autoscaling.GroupTagArgs(
                    key="Name",
                    value=f"asg-{env_name}",
                    propagate_at_launch=True
                ),
                aws.autoscaling.GroupTagArgs(
                    key="Environment",
                    value=env_name,
                    propagate_at_launch=True
                )
            ]
        )
        
        # Load Balancer
        alb = aws.lb.LoadBalancer(f"alb-{env_name}",
            load_balancer_type="application",
            subnets=[s.id for s in subnets],
            security_groups=[security_group.id],
            enable_deletion_protection=env_config.get("deletion_protection", False),
            tags={
                "Name": f"alb-{env_name}",
                "Environment": env_name
            }
        )
        
        # Target Group
        target_group = aws.lb.TargetGroup(f"tg-{env_name}",
            port=80,
            protocol="HTTP",
            vpc_id=vpc.id,
            health_check=aws.lb.TargetGroupHealthCheckArgs(
                enabled=True,
                healthy_threshold=2,
                interval=30,
                matcher="200",
                path="/",
                port="traffic-port",
                protocol="HTTP",
                timeout=5,
                unhealthy_threshold=2,
            ),
            tags={
                "Name": f"tg-{env_name}",
                "Environment": env_name
            }
        )
        
        # Listener
        listener = aws.lb.Listener(f"listener-{env_name}",
            load_balancer_arn=alb.arn,
            port="80",
            protocol="HTTP",
            default_actions=[
                aws.lb.ListenerDefaultActionArgs(
                    type="forward",
                    target_group_arn=target_group.arn,
                )
            ]
        )
        
        # Auto Scaling Group Attachment
        aws.autoscaling.Attachment(f"asg-attachment-{env_name}",
            autoscaling_group_name=asg.name,
            lb_target_group_arn=target_group.arn
        )
        
        # Scaling Policies
        scale_up_policy = aws.autoscaling.Policy(f"scale-up-{env_name}",
            autoscaling_group_name=asg.name,
            adjustment_type="ChangeInCapacity",
            scaling_adjustment=1,
            cooldown=300,
            policy_type="SimpleScaling"
        )
        
        scale_down_policy = aws.autoscaling.Policy(f"scale-down-{env_name}",
            autoscaling_group_name=asg.name,
            adjustment_type="ChangeInCapacity",
            scaling_adjustment=-1,
            cooldown=300,
            policy_type="SimpleScaling"
        )
        
        # CloudWatch Alarms
        aws.cloudwatch.MetricAlarm(f"cpu-high-{env_name}",
            comparison_operator="GreaterThanThreshold",
            evaluation_periods=2,
            metric_name="CPUUtilization",
            namespace="AWS/EC2",
            period=120,
            statistic="Average",
            threshold=70.0,
            alarm_description="This metric monitors ec2 cpu utilization",
            alarm_actions=[scale_up_policy.arn],
            dimensions={
                "AutoScalingGroupName": asg.name,
            }
        )
        
        aws.cloudwatch.MetricAlarm(f"cpu-low-{env_name}",
            comparison_operator="LessThanThreshold",
            evaluation_periods=2,
            metric_name="CPUUtilization",
            namespace="AWS/EC2",
            period=120,
            statistic="Average",
            threshold=10.0,
            alarm_description="This metric monitors ec2 cpu utilization",
            alarm_actions=[scale_down_policy.arn],
            dimensions={
                "AutoScalingGroupName": asg.name,
            }
        )
        
        # Export Load Balancer DNS
        pulumi.export(f"{env_name}_load_balancer_dns", alb.dns_name)
    
    # Single EC2 instance (if auto scaling is disabled)
    else:
        instance = aws.ec2.Instance(f"instance-{env_name}",
            ami=env_config["ami_id"],
            instance_type=env_config["instance_type"],
            subnet_id=subnets[0].id,
            vpc_security_group_ids=[security_group.id],
            user_data=user_data,
            tags={
                "Name": f"instance-{env_name}",
                "Environment": env_name
            }
        )
        
        # Export instance public IP
        pulumi.export(f"{env_name}_instance_public_ip", instance.public_ip)
    
    # Export VPC information
    pulumi.export(f"{env_name}_vpc_id", vpc.id)
    pulumi.export(f"{env_name}_vpc_cidr", vpc.cidr_block)
    pulumi.export(f"{env_name}_subnet_ids", [s.id for s in subnets])

# Create resources for each environment
for env_name, env_config in environments.items():
    create_environment_resources(env_name, env_config)
