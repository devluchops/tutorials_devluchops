# Pulumi - Modern Infrastructure as Code Tutorial

Complete Pulumi tutorial: Infrastructure as Code using real programming languages (TypeScript, Python, Go, C#).

## Why Pulumi vs Terraform?

### **Terraform** 🟡
- ✅ Mature and stable
- ✅ Large provider ecosystem
- ❌ HCL is limited for complex logic
- ❌ Manual state management
- ❌ Limited testing

### **Pulumi** 🚀
- ✅ **Real Programming Languages** - TypeScript, Python, Go, C#
- ✅ **Better Testing** - Unit tests, property-based testing
- ✅ **Superior Logic** - Loops, conditions, native functions
- ✅ **Cloud Native** - Built for modern cloud patterns
- ✅ **Policy as Code** - CrossGuard policies

## Architecture and Concepts

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Pulumi CLI    │───▶│  Pulumi Engine  │───▶│  Cloud Provider │
│  (Your Code)    │    │   (State Mgmt)  │    │   (AWS/GCP/K8s) │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
    TypeScript/Python      Deployment Engine        Resources
    Go/C#/Java             Pulumi Service           VPC, EC2, K8s
    Real Languages         State Backend           Load Balancers
```

## Pulumi vs Traditional IaC

### **Traditional Terraform**
```hcl
# Limited conditionals
resource "aws_instance" "web" {
  count = var.environment == "prod" ? 3 : 1
  ami   = data.aws_ami.app.id
  instance_type = var.environment == "prod" ? "t3.large" : "t3.micro"
}
```

### **Pulumi with Real Programming**
```typescript
// Rich programming constructs
const instanceCount = environment === "prod" ? 3 : 1;
const instanceType = environment === "prod" ? "t3.large" : "t3.micro";

const instances = Array.from({ length: instanceCount }, (_, i) => {
  return new aws.ec2.Instance(`web-${i}`, {
    ami: amiId,
    instanceType: instanceType,
    tags: {
      Name: `web-server-${i}`,
      Environment: environment,
      Owner: teamName,
    },
  });
});
```

## Getting Started

### 1. **Installation**
```bash
# Install Pulumi CLI
curl -fsSL https://get.pulumi.com | sh

# Install language runtime
npm install -g typescript  # For TypeScript
pip install pulumi         # For Python
```

### 2. **First Project**
```bash
# Create new project
pulumi new aws-typescript

# Configure AWS
pulumi config set aws:region us-west-2

# Deploy
pulumi up
```

## Advanced Examples

### **1. Multi-Cloud Architecture**
```typescript
// multi-cloud.ts
import * as aws from "@pulumi/aws";
import * as gcp from "@pulumi/gcp";
import * as azure from "@pulumi/azure-native";

// AWS Resources
const awsVpc = new aws.ec2.Vpc("aws-vpc", {
  cidrBlock: "10.0.0.0/16",
  tags: { Name: "aws-primary-vpc" }
});

// GCP Resources  
const gcpNetwork = new gcp.compute.Network("gcp-network", {
  autoCreateSubnetworks: false,
});

// Azure Resources
const azureRg = new azure.resources.ResourceGroup("azure-rg", {
  location: "East US",
});

// Cross-cloud connectivity
const vpnConnection = new aws.ec2.VpnConnection("aws-gcp-vpn", {
  customerGatewayId: customerGateway.id,
  type: "ipsec.1",
  staticRoutesOnly: true,
});
```

### **2. Dynamic Infrastructure**
```python
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
        tags={
            "Name": f"vpc-{env_name}",
            "Environment": env_name
        }
    )
    
    # Subnets based on AZ configuration
    subnets = []
    for i, az in enumerate(env_config["availability_zones"]):
        subnet = aws.ec2.Subnet(f"subnet-{env_name}-{i}",
            vpc_id=vpc.id,
            cidr_block=f"{env_config['cidr'][:-4]}{i+1}.0/24",
            availability_zone=az,
            map_public_ip_on_launch=True,
            tags={
                "Name": f"subnet-{env_name}-{az}",
                "Environment": env_name
            }
        )
        subnets.append(subnet)
    
    # Auto Scaling Group with custom logic
    if env_config.get("auto_scaling", False):
        asg = aws.autoscaling.Group(f"asg-{env_name}",
            desired_capacity=env_config["instance_count"],
            max_size=env_config["max_instances"],
            min_size=env_config["min_instances"],
            vpc_zone_identifiers=[s.id for s in subnets],
            launch_template=aws.autoscaling.LaunchTemplateArgs(
                id=launch_template.id,
                version="$Latest"
            )
        )
```

### **3. Kubernetes with Pulumi**
```typescript
// kubernetes-cluster.ts
import * as k8s from "@pulumi/kubernetes";
import * as eks from "@pulumi/eks";

// EKS Cluster
const cluster = new eks.Cluster("my-cluster", {
  version: "1.27",
  instanceType: "t3.medium",
  desiredCapacity: 3,
  minSize: 1,
  maxSize: 10,
  enabledClusterLogTypes: ["api", "audit", "authenticator"],
});

// Kubernetes Provider
const k8sProvider = new k8s.Provider("k8s-provider", {
  kubeconfig: cluster.kubeconfig,
});

// Deploy applications using real programming
const apps = [
  { name: "frontend", image: "nginx:1.21", replicas: 3, port: 80 },
  { name: "backend", image: "node:16-alpine", replicas: 2, port: 3000 },
  { name: "database", image: "postgres:13", replicas: 1, port: 5432 }
];

apps.forEach(app => {
  // Deployment
  const deployment = new k8s.apps.v1.Deployment(`${app.name}-deployment`, {
    metadata: { name: app.name },
    spec: {
      replicas: app.replicas,
      selector: { matchLabels: { app: app.name } },
      template: {
        metadata: { labels: { app: app.name } },
        spec: {
          containers: [{
            name: app.name,
            image: app.image,
            ports: [{ containerPort: app.port }],
            resources: {
              requests: { memory: "64Mi", cpu: "50m" },
              limits: { memory: "128Mi", cpu: "100m" }
            }
          }]
        }
      }
    }
  }, { provider: k8sProvider });

  // Service
  const service = new k8s.core.v1.Service(`${app.name}-service`, {
    metadata: { name: app.name },
    spec: {
      selector: { app: app.name },
      ports: [{ port: app.port, targetPort: app.port }],
      type: app.name === "frontend" ? "LoadBalancer" : "ClusterIP"
    }
  }, { provider: k8sProvider });
});
```

## Advanced Features

### **1. Policy as Code (CrossGuard)**
```typescript
// policies/security-policies.ts
import { PolicyPack, validateResourceOfType } from "@pulumi/policy";
import { aws } from "@pulumi/aws";

export const securityPolicies = new PolicyPack("security-policies", {
  policies: [
    {
      name: "s3-bucket-encryption",
      description: "S3 buckets must have encryption enabled",
      enforcementLevel: "mandatory",
      validateResource: validateResourceOfType(aws.s3.Bucket, (bucket, args, reportViolation) => {
        if (!bucket.serverSideEncryptionConfiguration) {
          reportViolation("S3 bucket must have encryption enabled");
        }
      }),
    },
    {
      name: "ec2-instance-tags",
      description: "EC2 instances must have required tags",
      enforcementLevel: "advisory",
      validateResource: validateResourceOfType(aws.ec2.Instance, (instance, args, reportViolation) => {
        const requiredTags = ["Environment", "Owner", "Project"];
        const tags = instance.tags || {};
        
        requiredTags.forEach(tag => {
          if (!tags[tag]) {
            reportViolation(`EC2 instance missing required tag: ${tag}`);
          }
        });
      }),
    }
  ],
});
```

### **2. Component Resources**
```typescript
// components/WebApplication.ts
import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";

export interface WebApplicationArgs {
  environment: string;
  instanceType?: string;
  domain?: string;
  sslCertificateArn?: string;
}

export class WebApplication extends pulumi.ComponentResource {
  public readonly loadBalancer: aws.elb.LoadBalancer;
  public readonly autoScalingGroup: aws.autoscaling.Group;
  public readonly url: pulumi.Output<string>;

  constructor(name: string, args: WebApplicationArgs, opts?: pulumi.ComponentResourceOptions) {
    super("custom:WebApplication", name, {}, opts);

    // VPC and networking
    const vpc = new aws.ec2.Vpc(`${name}-vpc`, {
      cidrBlock: "10.0.0.0/16",
      enableDnsHostnames: true,
      tags: { Name: `${name}-vpc`, Environment: args.environment }
    }, { parent: this });

    // Auto Scaling Group
    this.autoScalingGroup = new aws.autoscaling.Group(`${name}-asg`, {
      desiredCapacity: args.environment === "prod" ? 3 : 1,
      maxSize: args.environment === "prod" ? 10 : 2,
      minSize: 1,
      // ... more configuration
    }, { parent: this });

    // Load Balancer
    this.loadBalancer = new aws.elb.LoadBalancer(`${name}-lb`, {
      // ... configuration
    }, { parent: this });

    // Output the URL
    this.url = this.loadBalancer.dnsName.apply(dns => 
      args.domain ? `https://${args.domain}` : `http://${dns}`
    );

    this.registerOutputs({
      loadBalancer: this.loadBalancer,
      autoScalingGroup: this.autoScalingGroup,
      url: this.url
    });
  }
}

// Usage
const webApp = new WebApplication("my-app", {
  environment: "production",
  instanceType: "t3.large",
  domain: "myapp.com"
});

export const appUrl = webApp.url;
```

### **3. Testing Infrastructure**
```typescript
// tests/infrastructure.test.ts
import { describe, it } from "mocha";
import * as chai from "chai";
import * as pulumi from "@pulumi/pulumi";

// Mock Pulumi runtime
pulumi.runtime.setMocks({
  newResource: function(args: pulumi.runtime.MockResourceArgs): {id: string, state: any} {
    return {
      id: args.inputs.name + "_id",
      state: args.inputs,
    };
  },
  call: function(args: pulumi.runtime.MockCallArgs) {
    return args.inputs;
  },
});

describe("Infrastructure Tests", function() {
  let infra: typeof import("../index");

  before(async function() {
    infra = await import("../index");
  });

  it("should create VPC with correct CIDR", function(done) {
    pulumi.all([infra.vpc.cidrBlock]).apply(([cidr]) => {
      chai.expect(cidr).to.equal("10.0.0.0/16");
      done();
    });
  });

  it("should have encryption enabled on S3 bucket", function(done) {
    pulumi.all([infra.bucket.serverSideEncryptionConfiguration]).apply(([encryption]) => {
      chai.expect(encryption).to.not.be.undefined;
      done();
    });
  });
});
```

## CI/CD Integration

### **GitHub Actions**
```yaml
# .github/workflows/pulumi.yml
name: Pulumi Infrastructure

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  preview:
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '18'
    - name: Install dependencies
      run: npm install
    - name: Pulumi Preview
      uses: pulumi/actions@v4
      with:
        command: preview
        stack-name: dev
      env:
        PULUMI_ACCESS_TOKEN: ${{ secrets.PULUMI_ACCESS_TOKEN }}

  deploy:
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '18'
    - name: Install dependencies
      run: npm install
    - name: Pulumi Deploy
      uses: pulumi/actions@v4
      with:
        command: up
        stack-name: prod
      env:
        PULUMI_ACCESS_TOKEN: ${{ secrets.PULUMI_ACCESS_TOKEN }}
```

## Best Practices

### **1. Project Structure**
```
my-infrastructure/
├── src/
│   ├── components/
│   │   ├── WebApplication.ts
│   │   └── Database.ts
│   ├── policies/
│   │   └── security.ts
│   └── index.ts
├── tests/
│   └── infrastructure.test.ts
├── config/
│   ├── dev.yaml
│   └── prod.yaml
├── Pulumi.yaml
└── package.json
```

### **2. Configuration Management**
```yaml
# Pulumi.dev.yaml
config:
  environment: dev
  instance-type: t3.micro
  min-instances: 1
  max-instances: 2

# Pulumi.prod.yaml  
config:
  environment: prod
  instance-type: t3.large
  min-instances: 3
  max-instances: 10
```

## Migrating from Terraform

### **1. Import Existing Resources**
```bash
# Import Terraform state
pulumi import aws:ec2/vpc:Vpc my-vpc vpc-12345
pulumi import aws:ec2/instance:Instance web-server i-abcdef123
```

### **2. Gradual Migration**
```typescript
// Use existing Terraform outputs
import * as terraform from "@pulumi/terraform";

const terraformState = new terraform.state.RemoteStateReference("existing", {
  backendType: "s3",
  bucket: "my-terraform-state",
  key: "terraform.tfstate",
  region: "us-west-2"
});

const existingVpcId = terraformState.getOutput("vpc_id");

// Use in new Pulumi resources
const subnet = new aws.ec2.Subnet("new-subnet", {
  vpcId: existingVpcId,
  cidrBlock: "10.0.1.0/24"
});
```

## Useful Links

- [Pulumi Documentation](https://www.pulumi.com/docs/)
- [Pulumi Examples](https://github.com/pulumi/examples)
- [CrossGuard Policies](https://www.pulumi.com/docs/guides/crossguard/)
- [YouTube Tutorial](https://youtu.be/EXAMPLE)
