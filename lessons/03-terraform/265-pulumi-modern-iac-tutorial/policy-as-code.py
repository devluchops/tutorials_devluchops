# Policy as Code with Pulumi

import pulumi
from pulumi import Config, Output
from pulumi_aws import iam, ec2
from typing import Dict, Any, List

config = Config()

class SecurityPolicyManager:
    """Manages security policies as code"""
    
    def __init__(self, name: str):
        self.name = name
        self.policies = {}
        
    def create_iam_policy(self, policy_name: str, policy_config: Dict[str, Any]) -> iam.Policy:
        """Create IAM policy from configuration"""
        
        policy_document = {
            "Version": "2012-10-17",
            "Statement": []
        }
        
        # Add statements based on configuration
        for statement in policy_config.get("statements", []):
            policy_statement = {
                "Effect": statement.get("effect", "Allow"),
                "Action": statement.get("actions", []),
                "Resource": statement.get("resources", ["*"])
            }
            
            if "conditions" in statement:
                policy_statement["Condition"] = statement["conditions"]
                
            policy_document["Statement"].append(policy_statement)
        
        policy = iam.Policy(
            f"{self.name}-{policy_name}",
            name=f"{self.name}-{policy_name}",
            description=policy_config.get("description", f"Policy for {policy_name}"),
            policy=pulumi.Output.from_input(policy_document).apply(lambda doc: pulumi.Output.json_dumps(doc))
        )
        
        self.policies[policy_name] = policy
        return policy
    
    def create_security_group_rules(self, sg_name: str, rules_config: List[Dict[str, Any]]) -> ec2.SecurityGroup:
        """Create security group with rules from configuration"""
        
        ingress_rules = []
        egress_rules = []
        
        for rule in rules_config:
            rule_dict = {
                "protocol": rule.get("protocol", "tcp"),
                "from_port": rule.get("from_port", 80),
                "to_port": rule.get("to_port", 80),
                "cidr_blocks": rule.get("cidr_blocks", ["0.0.0.0/0"]),
                "description": rule.get("description", "")
            }
            
            if rule.get("direction") == "egress":
                egress_rules.append(rule_dict)
            else:
                ingress_rules.append(rule_dict)
        
        security_group = ec2.SecurityGroup(
            f"{self.name}-{sg_name}",
            name=f"{self.name}-{sg_name}",
            description=f"Security group for {sg_name}",
            ingress=ingress_rules,
            egress=egress_rules,
            tags={"Name": f"{self.name}-{sg_name}"}
        )
        
        return security_group

# Policy configurations
SECURITY_POLICIES = {
    "ec2_read_only": {
        "description": "EC2 read-only access policy",
        "statements": [
            {
                "effect": "Allow",
                "actions": [
                    "ec2:Describe*",
                    "ec2:List*",
                    "ec2:Get*"
                ],
                "resources": ["*"]
            }
        ]
    },
    "s3_bucket_access": {
        "description": "S3 bucket specific access policy",
        "statements": [
            {
                "effect": "Allow",
                "actions": [
                    "s3:GetObject",
                    "s3:PutObject",
                    "s3:DeleteObject"
                ],
                "resources": ["arn:aws:s3:::my-bucket/*"],
                "conditions": {
                    "StringEquals": {
                        "s3:x-amz-server-side-encryption": "AES256"
                    }
                }
            }
        ]
    },
    "cloudwatch_metrics": {
        "description": "CloudWatch metrics access policy",
        "statements": [
            {
                "effect": "Allow",
                "actions": [
                    "cloudwatch:GetMetricStatistics",
                    "cloudwatch:ListMetrics",
                    "cloudwatch:PutMetricData"
                ],
                "resources": ["*"]
            }
        ]
    }
}

SECURITY_GROUP_RULES = {
    "web_server_rules": [
        {
            "direction": "ingress",
            "protocol": "tcp",
            "from_port": 80,
            "to_port": 80,
            "cidr_blocks": ["0.0.0.0/0"],
            "description": "HTTP access"
        },
        {
            "direction": "ingress",
            "protocol": "tcp",
            "from_port": 443,
            "to_port": 443,
            "cidr_blocks": ["0.0.0.0/0"],
            "description": "HTTPS access"
        },
        {
            "direction": "ingress",
            "protocol": "tcp",
            "from_port": 22,
            "to_port": 22,
            "cidr_blocks": ["10.0.0.0/8"],
            "description": "SSH access from private networks"
        },
        {
            "direction": "egress",
            "protocol": "-1",
            "from_port": 0,
            "to_port": 0,
            "cidr_blocks": ["0.0.0.0/0"],
            "description": "All outbound traffic"
        }
    ],
    "database_rules": [
        {
            "direction": "ingress",
            "protocol": "tcp",
            "from_port": 5432,
            "to_port": 5432,
            "cidr_blocks": ["10.0.0.0/16"],
            "description": "PostgreSQL access from VPC"
        },
        {
            "direction": "ingress",
            "protocol": "tcp",
            "from_port": 3306,
            "to_port": 3306,
            "cidr_blocks": ["10.0.0.0/16"],
            "description": "MySQL access from VPC"
        }
    ]
}

def main():
    """Main function to create security policies"""
    
    # Get environment
    environment = config.get("environment") or "dev"
    
    # Create policy manager
    policy_manager = SecurityPolicyManager(f"pulumi-tutorial-{environment}")
    
    # Create IAM policies
    created_policies = {}
    for policy_name, policy_config in SECURITY_POLICIES.items():
        policy = policy_manager.create_iam_policy(policy_name, policy_config)
        created_policies[policy_name] = policy
        
        # Export policy ARN
        pulumi.export(f"{policy_name}_arn", policy.arn)
    
    # Create security groups
    created_security_groups = {}
    for sg_name, rules_config in SECURITY_GROUP_RULES.items():
        sg = policy_manager.create_security_group_rules(sg_name, rules_config)
        created_security_groups[sg_name] = sg
        
        # Export security group ID
        pulumi.export(f"{sg_name}_id", sg.id)
    
    # Create role with policies attached
    assume_role_policy = {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Action": "sts:AssumeRole",
                "Effect": "Allow",
                "Principal": {
                    "Service": "ec2.amazonaws.com"
                }
            }
        ]
    }
    
    role = iam.Role(
        f"pulumi-tutorial-{environment}-role",
        name=f"pulumi-tutorial-{environment}-role",
        assume_role_policy=pulumi.Output.from_input(assume_role_policy).apply(
            lambda doc: pulumi.Output.json_dumps(doc)
        ),
        tags={"Environment": environment}
    )
    
    # Attach policies to role
    for policy_name, policy in created_policies.items():
        iam.RolePolicyAttachment(
            f"pulumi-tutorial-{environment}-{policy_name}-attachment",
            role=role.name,
            policy_arn=policy.arn
        )
    
    # Create instance profile
    instance_profile = iam.InstanceProfile(
        f"pulumi-tutorial-{environment}-profile",
        name=f"pulumi-tutorial-{environment}-profile",
        role=role.name
    )
    
    # Export outputs
    pulumi.export("role_arn", role.arn)
    pulumi.export("instance_profile_name", instance_profile.name)
    pulumi.export("security_policies_count", len(created_policies))
    pulumi.export("security_groups_count", len(created_security_groups))

if __name__ == "__main__":
    main()
