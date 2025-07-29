# dynamic-infrastructure.py
import pulumi
import pulumi_aws as aws
import json

# Configuration-driven infrastructure
config = pulumi.Config()
environments = config.require_object("environments")

# Create resources dynamically
for env_name, env_config in environments.items():
    # VPC per environment
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
    
    # Subnets based on AZ configuration
    subnets = []
    for i, az in enumerate(env_config["availability_zones"]):
        # Public subnet
        public_subnet = aws.ec2.Subnet(f"public-subnet-{env_name}-{i}",
            vpc_id=vpc.id,
            cidr_block=f"{env_config['cidr'][:-4]}{i+1}.0/24",
            availability_zone=az,
            map_public_ip_on_launch=True,
            tags={
                "Name": f"public-subnet-{env_name}-{az}",
                "Environment": env_name,
                "Type": "public"
            }
        )
        subnets.append(public_subnet)
        
        # Private subnet
        private_subnet = aws.ec2.Subnet(f"private-subnet-{env_name}-{i}",
            vpc_id=vpc.id,
            cidr_block=f"{env_config['cidr'][:-4]}{i+10}.0/24",
            availability_zone=az,
            tags={
                "Name": f"private-subnet-{env_name}-{az}",
                "Environment": env_name,
                "Type": "private"
            }
        )
        subnets.append(private_subnet)
    
    # Route Table for public subnets
    public_rt = aws.ec2.RouteTable(f"public-rt-{env_name}",
        vpc_id=vpc.id,
        tags={
            "Name": f"public-rt-{env_name}",
            "Environment": env_name
        }
    )
    
    # Route to Internet Gateway
    public_route = aws.ec2.Route(f"public-route-{env_name}",
        route_table_id=public_rt.id,
        destination_cidr_block="0.0.0.0/0",
        gateway_id=igw.id
    )
    
    # Launch Template for Auto Scaling
    user_data = f"""#!/bin/bash
yum update -y
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user

# Install application
echo "Environment: {env_name}" > /var/log/app-info.log
echo "Instance launched at: $(date)" >> /var/log/app-info.log

# Start application container
docker run -d -p 80:80 --name app nginx:latest
"""
    
    launch_template = aws.ec2.LaunchTemplate(f"lt-{env_name}",
        name=f"lt-{env_name}",
        image_id=env_config.get("ami_id", "ami-0c02fb55956c7d316"),
        instance_type=env_config["instance_type"],
        key_name=env_config.get("key_name", "default-key"),
        vpc_security_group_ids=[],  # Will be filled after security group creation
        user_data=pulumi.Output.from_input(user_data).apply(lambda ud: 
            __import__('base64').b64encode(ud.encode()).decode()),
        tag_specifications=[{
            "resource_type": "instance",
            "tags": {
                "Name": f"instance-{env_name}",
                "Environment": env_name,
                "LaunchedBy": "pulumi"
            }
        }]
    )
    
    # Security Group
    security_group = aws.ec2.SecurityGroup(f"sg-{env_name}",
        name=f"sg-{env_name}",
        description=f"Security group for {env_name} environment",
        vpc_id=vpc.id,
        ingress=[
            {
                "protocol": "tcp",
                "from_port": 80,
                "to_port": 80,
                "cidr_blocks": ["0.0.0.0/0"],
                "description": "HTTP access"
            },
            {
                "protocol": "tcp", 
                "from_port": 443,
                "to_port": 443,
                "cidr_blocks": ["0.0.0.0/0"],
                "description": "HTTPS access"
            },
            {
                "protocol": "tcp",
                "from_port": 22,
                "to_port": 22,
                "cidr_blocks": [env_config["cidr"]],
                "description": "SSH access from VPC"
            }
        ],
        egress=[{
            "protocol": "-1",
            "from_port": 0,
            "to_port": 0,
            "cidr_blocks": ["0.0.0.0/0"],
            "description": "All outbound traffic"
        }],
        tags={
            "Name": f"sg-{env_name}",
            "Environment": env_name
        }
    )
    
    # Auto Scaling Group with custom logic
    if env_config.get("auto_scaling", False):
        # Target Group for Load Balancer
        target_group = aws.lb.TargetGroup(f"tg-{env_name}",
            name=f"tg-{env_name}",
            port=80,
            protocol="HTTP",
            vpc_id=vpc.id,
            health_check={
                "enabled": True,
                "healthy_threshold": 2,
                "unhealthy_threshold": 3,
                "timeout": 5,
                "interval": 30,
                "path": "/",
                "matcher": "200"
            },
            tags={
                "Name": f"tg-{env_name}",
                "Environment": env_name
            }
        )
        
        # Application Load Balancer
        load_balancer = aws.lb.LoadBalancer(f"alb-{env_name}",
            name=f"alb-{env_name}",
            load_balancer_type="application",
            subnets=[s.id for s in subnets if "public" in s._name],
            security_groups=[security_group.id],
            tags={
                "Name": f"alb-{env_name}",
                "Environment": env_name
            }
        )
        
        # Listener
        listener = aws.lb.Listener(f"listener-{env_name}",
            load_balancer_arn=load_balancer.arn,
            port=80,
            protocol="HTTP",
            default_actions=[{
                "type": "forward",
                "target_group_arn": target_group.arn
            }]
        )
        
        # Auto Scaling Group
        asg = aws.autoscaling.Group(f"asg-{env_name}",
            name=f"asg-{env_name}",
            desired_capacity=env_config["instance_count"],
            max_size=env_config["max_instances"],
            min_size=env_config["min_instances"],
            vpc_zone_identifiers=[s.id for s in subnets if "public" in s._name],
            target_group_arns=[target_group.arn],
            health_check_type="ELB",
            health_check_grace_period=300,
            launch_template={
                "id": launch_template.id,
                "version": "$Latest"
            },
            tags=[{
                "key": "Name",
                "value": f"asg-{env_name}",
                "propagate_at_launch": True
            }, {
                "key": "Environment", 
                "value": env_name,
                "propagate_at_launch": True
            }]
        )
        
        # Auto Scaling Policies
        scale_up_policy = aws.autoscaling.Policy(f"scale-up-{env_name}",
            name=f"scale-up-{env_name}",
            autoscaling_group_name=asg.name,
            adjustment_type="ChangeInCapacity",
            scaling_adjustment=1,
            cooldown=300,
            policy_type="SimpleScaling"
        )
        
        scale_down_policy = aws.autoscaling.Policy(f"scale-down-{env_name}",
            name=f"scale-down-{env_name}",
            autoscaling_group_name=asg.name,
            adjustment_type="ChangeInCapacity",
            scaling_adjustment=-1,
            cooldown=300,
            policy_type="SimpleScaling"
        )
        
        # CloudWatch Alarms
        high_cpu_alarm = aws.cloudwatch.MetricAlarm(f"high-cpu-{env_name}",
            name=f"high-cpu-{env_name}",
            comparison_operator="GreaterThanThreshold",
            evaluation_periods=2,
            metric_name="CPUUtilization",
            namespace="AWS/EC2",
            period=120,
            statistic="Average",
            threshold=env_config.get("cpu_threshold_high", 70),
            alarm_description=f"High CPU utilization for {env_name}",
            alarm_actions=[scale_up_policy.arn],
            dimensions={
                "AutoScalingGroupName": asg.name
            }
        )
        
        low_cpu_alarm = aws.cloudwatch.MetricAlarm(f"low-cpu-{env_name}",
            name=f"low-cpu-{env_name}",
            comparison_operator="LessThanThreshold",
            evaluation_periods=2,
            metric_name="CPUUtilization",
            namespace="AWS/EC2",
            period=120,
            statistic="Average",
            threshold=env_config.get("cpu_threshold_low", 30),
            alarm_description=f"Low CPU utilization for {env_name}",
            alarm_actions=[scale_down_policy.arn],
            dimensions={
                "AutoScalingGroupName": asg.name
            }
        )
        
        # Export load balancer DNS
        pulumi.export(f"{env_name}_load_balancer_dns", load_balancer.dns_name)
        pulumi.export(f"{env_name}_load_balancer_zone_id", load_balancer.zone_id)
    
    # Export VPC information
    pulumi.export(f"{env_name}_vpc_id", vpc.id)
    pulumi.export(f"{env_name}_vpc_cidr", vpc.cidr_block)
    pulumi.export(f"{env_name}_subnet_ids", [s.id for s in subnets])
    
    # Export security group
    pulumi.export(f"{env_name}_security_group_id", security_group.id)
