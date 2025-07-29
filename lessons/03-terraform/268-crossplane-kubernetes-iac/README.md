# Crossplane - Kubernetes-native Infrastructure as Code

Complete Crossplane tutorial for managing multi-cloud infrastructure using Kubernetes as a control plane.

## What is Crossplane?

Crossplane is an open-source platform that transforms Kubernetes into a universal control plane for cloud infrastructure.

### **Crossplane vs Traditional IaC**

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Traditional   │    │   Crossplane    │    │   Benefits      │
│   IaC Tools     │───▶│   Kubernetes    │───▶│   • GitOps      │
│   • Terraform   │    │   • CRDs        │    │   • RBAC        │
│   • Pulumi      │    │   • Controllers │    │   • Self-Service│
│   • CloudForm.  │    │   • Compositions│    │   • Multi-Cloud │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Core Concepts

### **1. Providers, Managed Resources, and Compositions**
```yaml
# Provider - Connects to cloud APIs
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-aws
spec:
  package: xpkg.upbound.io/upbound/provider-aws:v0.44.0

---
# Managed Resource - Direct cloud resource
apiVersion: ec2.aws.upbound.io/v1beta1
kind: Instance
metadata:
  name: sample-instance
spec:
  forProvider:
    region: us-west-2
    instanceType: t3.micro
    ami: ami-0c02fb55956c7d316
  providerConfigRef:
    name: default

---
# Composite Resource Definition - Platform API
apiVersion: apiextensions.crossplane.io/v1
kind: CompositeResourceDefinition
metadata:
  name: xpostgresqlinstances.database.example.com
spec:
  group: database.example.com
  names:
    kind: XPostgreSQLInstance
    plural: xpostgresqlinstances
  versions:
  - name: v1alpha1
    served: true
    referenceable: true
    schema:
      openAPIV3Schema:
        type: object
        properties:
          spec:
            type: object
            properties:
              parameters:
                type: object
                properties:
                  storageGB:
                    type: integer
                    description: "Size of the database in GB"
                  region:
                    type: string
                    description: "AWS region"
                required:
                - storageGB
                - region
          status:
            type: object
            properties:
              connectionSecret:
                type: string
```

## Getting Started

### **1. Installation**
```bash
# Install Crossplane using Helm
helm repo add crossplane-stable https://charts.crossplane.io/stable
helm repo update

# Install Crossplane
helm install crossplane \
  crossplane-stable/crossplane \
  --namespace crossplane-system \
  --create-namespace

# Verify installation
kubectl get pods -n crossplane-system

# Install Crossplane CLI
curl -sL https://raw.githubusercontent.com/crossplane/crossplane/master/install.sh | sh
sudo mv kubectl-crossplane /usr/local/bin
```

### **2. Basic Setup**
```bash
# Install AWS Provider
kubectl crossplane install provider xpkg.upbound.io/upbound/provider-aws:v0.44.0

# Create AWS ProviderConfig
cat <<EOF | kubectl apply -f -
apiVersion: aws.upbound.io/v1beta1
kind: ProviderConfig
metadata:
  name: default
spec:
  credentials:
    source: Secret
    secretRef:
      namespace: crossplane-system
      name: aws-secret
      key: creds
EOF

# Create AWS credentials secret
kubectl create secret generic aws-secret \
  -n crossplane-system \
  --from-file=creds=aws-credentials.txt
```

## Real-World Examples

### **1. Platform API for Web Applications**
```yaml
# infrastructure/xrds/web-application.yaml
apiVersion: apiextensions.crossplane.io/v1
kind: CompositeResourceDefinition
metadata:
  name: xwebapplications.platform.example.com
spec:
  group: platform.example.com
  names:
    kind: XWebApplication
    plural: xwebapplications
  claimNames:
    kind: WebApplication
    plural: webapplications
  versions:
  - name: v1alpha1
    served: true
    referenceable: true
    schema:
      openAPIV3Schema:
        type: object
        properties:
          spec:
            type: object
            properties:
              parameters:
                type: object
                properties:
                  environment:
                    type: string
                    enum: ["dev", "staging", "prod"]
                    description: "Environment for the application"
                  region:
                    type: string
                    description: "AWS region"
                  appName:
                    type: string
                    description: "Application name"
                  instanceType:
                    type: string
                    default: "t3.micro"
                    description: "EC2 instance type"
                  minSize:
                    type: integer
                    default: 1
                    description: "Minimum number of instances"
                  maxSize:
                    type: integer
                    default: 10
                    description: "Maximum number of instances"
                  dbStorage:
                    type: integer
                    default: 20
                    description: "Database storage in GB"
                required:
                - environment
                - region
                - appName
            required:
            - parameters
          status:
            type: object
            properties:
              loadBalancerUrl:
                type: string
                description: "Application load balancer URL"
              databaseEndpoint:
                type: string
                description: "Database connection endpoint"

---
# infrastructure/compositions/web-application-composition.yaml
apiVersion: apiextensions.crossplane.io/v1
kind: Composition
metadata:
  name: web-application-aws
  labels:
    provider: aws
    service: web-application
spec:
  compositeTypeRef:
    apiVersion: platform.example.com/v1alpha1
    kind: XWebApplication

  resources:
  # VPC
  - name: vpc
    base:
      apiVersion: ec2.aws.upbound.io/v1beta1
      kind: VPC
      spec:
        forProvider:
          cidrBlock: "10.0.0.0/16"
          enableDnsHostnames: true
          enableDnsSupport: true
          tags:
            Name: ""
    patches:
    - type: FromCompositeFieldPath
      fromFieldPath: spec.parameters.appName
      toFieldPath: spec.forProvider.tags.Name
      transforms:
      - type: string
        string:
          fmt: "%s-vpc"
    - type: FromCompositeFieldPath
      fromFieldPath: spec.parameters.region
      toFieldPath: spec.forProvider.region

  # Internet Gateway
  - name: internet-gateway
    base:
      apiVersion: ec2.aws.upbound.io/v1beta1
      kind: InternetGateway
      spec:
        forProvider:
          tags:
            Name: ""
    patches:
    - type: FromCompositeFieldPath
      fromFieldPath: spec.parameters.appName
      toFieldPath: spec.forProvider.tags.Name
      transforms:
      - type: string
        string:
          fmt: "%s-igw"
    - type: FromCompositeFieldPath
      fromFieldPath: spec.parameters.region
      toFieldPath: spec.forProvider.region

  # VPC Gateway Attachment
  - name: vpc-gateway-attachment
    base:
      apiVersion: ec2.aws.upbound.io/v1beta1
      kind: VPCGatewayAttachment
      spec:
        forProvider:
          vpcIdSelector:
            matchControllerRef: true
          internetGatewayIdSelector:
            matchControllerRef: true
    patches:
    - type: FromCompositeFieldPath
      fromFieldPath: spec.parameters.region
      toFieldPath: spec.forProvider.region

  # Public Subnets
  - name: public-subnet-1
    base:
      apiVersion: ec2.aws.upbound.io/v1beta1
      kind: Subnet
      spec:
        forProvider:
          cidrBlock: "10.0.1.0/24"
          mapPublicIpOnLaunch: true
          vpcIdSelector:
            matchControllerRef: true
          tags:
            Name: ""
            Type: "public"
    patches:
    - type: FromCompositeFieldPath
      fromFieldPath: spec.parameters.appName
      toFieldPath: spec.forProvider.tags.Name
      transforms:
      - type: string
        string:
          fmt: "%s-public-subnet-1"
    - type: FromCompositeFieldPath
      fromFieldPath: spec.parameters.region
      toFieldPath: spec.forProvider.region
    - type: FromCompositeFieldPath
      fromFieldPath: spec.parameters.region
      toFieldPath: spec.forProvider.availabilityZone
      transforms:
      - type: string
        string:
          fmt: "%sa"

  - name: public-subnet-2
    base:
      apiVersion: ec2.aws.upbound.io/v1beta1
      kind: Subnet
      spec:
        forProvider:
          cidrBlock: "10.0.2.0/24"
          mapPublicIpOnLaunch: true
          vpcIdSelector:
            matchControllerRef: true
          tags:
            Name: ""
            Type: "public"
    patches:
    - type: FromCompositeFieldPath
      fromFieldPath: spec.parameters.appName
      toFieldPath: spec.forProvider.tags.Name
      transforms:
      - type: string
        string:
          fmt: "%s-public-subnet-2"
    - type: FromCompositeFieldPath
      fromFieldPath: spec.parameters.region
      toFieldPath: spec.forProvider.region
    - type: FromCompositeFieldPath
      fromFieldPath: spec.parameters.region
      toFieldPath: spec.forProvider.availabilityZone
      transforms:
      - type: string
        string:
          fmt: "%sb"

  # Private Subnets for Database
  - name: private-subnet-1
    base:
      apiVersion: ec2.aws.upbound.io/v1beta1
      kind: Subnet
      spec:
        forProvider:
          cidrBlock: "10.0.101.0/24"
          vpcIdSelector:
            matchControllerRef: true
          tags:
            Name: ""
            Type: "private"
    patches:
    - type: FromCompositeFieldPath
      fromFieldPath: spec.parameters.appName
      toFieldPath: spec.forProvider.tags.Name
      transforms:
      - type: string
        string:
          fmt: "%s-private-subnet-1"
    - type: FromCompositeFieldPath
      fromFieldPath: spec.parameters.region
      toFieldPath: spec.forProvider.region
    - type: FromCompositeFieldPath
      fromFieldPath: spec.parameters.region
      toFieldPath: spec.forProvider.availabilityZone
      transforms:
      - type: string
        string:
          fmt: "%sa"

  - name: private-subnet-2
    base:
      apiVersion: ec2.aws.upbound.io/v1beta1
      kind: Subnet
      spec:
        forProvider:
          cidrBlock: "10.0.102.0/24"
          vpcIdSelector:
            matchControllerRef: true
          tags:
            Name: ""
            Type: "private"
    patches:
    - type: FromCompositeFieldPath
      fromFieldPath: spec.parameters.appName
      toFieldPath: spec.forProvider.tags.Name
      transforms:
      - type: string
        string:
          fmt: "%s-private-subnet-2"
    - type: FromCompositeFieldPath
      fromFieldPath: spec.parameters.region
      toFieldPath: spec.forProvider.region
    - type: FromCompositeFieldPath
      fromFieldPath: spec.parameters.region
      toFieldPath: spec.forProvider.availabilityZone
      transforms:
      - type: string
        string:
          fmt: "%sb"

  # Security Groups
  - name: web-security-group
    base:
      apiVersion: ec2.aws.upbound.io/v1beta1
      kind: SecurityGroup
      spec:
        forProvider:
          description: "Security group for web servers"
          vpcIdSelector:
            matchControllerRef: true
          tags:
            Name: ""
    patches:
    - type: FromCompositeFieldPath
      fromFieldPath: spec.parameters.appName
      toFieldPath: spec.forProvider.tags.Name
      transforms:
      - type: string
        string:
          fmt: "%s-web-sg"
    - type: FromCompositeFieldPath
      fromFieldPath: spec.parameters.region
      toFieldPath: spec.forProvider.region

  # Security Group Rules
  - name: web-sg-rule-http
    base:
      apiVersion: ec2.aws.upbound.io/v1beta1
      kind: SecurityGroupRule
      spec:
        forProvider:
          type: "ingress"
          fromPort: 80
          toPort: 80
          protocol: "tcp"
          cidrBlocks: ["0.0.0.0/0"]
          securityGroupIdSelector:
            matchControllerRef: true
            matchLabels:
              type: "web"
    patches:
    - type: FromCompositeFieldPath
      fromFieldPath: spec.parameters.region
      toFieldPath: spec.forProvider.region

  # Database Subnet Group
  - name: db-subnet-group
    base:
      apiVersion: rds.aws.upbound.io/v1beta1
      kind: SubnetGroup
      spec:
        forProvider:
          description: "Database subnet group"
          subnetIdSelector:
            matchControllerRef: true
            matchLabels:
              Type: "private"
          tags:
            Name: ""
    patches:
    - type: FromCompositeFieldPath
      fromFieldPath: spec.parameters.appName
      toFieldPath: spec.forProvider.tags.Name
      transforms:
      - type: string
        string:
          fmt: "%s-db-subnet-group"
    - type: FromCompositeFieldPath
      fromFieldPath: spec.parameters.region
      toFieldPath: spec.forProvider.region

  # RDS Database
  - name: database
    base:
      apiVersion: rds.aws.upbound.io/v1beta1
      kind: Instance
      spec:
        forProvider:
          engine: "postgres"
          engineVersion: "14.9"
          instanceClass: "db.t3.micro"
          dbName: "appdb"
          username: "postgres"
          manageMasterUserPassword: true
          multiAz: false
          publiclyAccessible: false
          storageEncrypted: true
          storageType: "gp2"
          backupRetentionPeriod: 7
          dbSubnetGroupNameSelector:
            matchControllerRef: true
          vpcSecurityGroupIdSelector:
            matchControllerRef: true
          tags:
            Name: ""
    patches:
    - type: FromCompositeFieldPath
      fromFieldPath: spec.parameters.appName
      toFieldPath: spec.forProvider.tags.Name
      transforms:
      - type: string
        string:
          fmt: "%s-database"
    - type: FromCompositeFieldPath
      fromFieldPath: spec.parameters.region
      toFieldPath: spec.forProvider.region
    - type: FromCompositeFieldPath
      fromFieldPath: spec.parameters.dbStorage
      toFieldPath: spec.forProvider.allocatedStorage
    - type: FromCompositeFieldPath
      fromFieldPath: spec.parameters.environment
      toFieldPath: spec.forProvider.instanceClass
      transforms:
      - type: map
        map:
          dev: "db.t3.micro"
          staging: "db.t3.small"
          prod: "db.t3.medium"
    - type: FromCompositeFieldPath
      fromFieldPath: spec.parameters.environment
      toFieldPath: spec.forProvider.multiAz
      transforms:
      - type: map
        map:
          dev: false
          staging: false
          prod: true

  # Application Load Balancer
  - name: load-balancer
    base:
      apiVersion: elbv2.aws.upbound.io/v1beta1
      kind: LB
      spec:
        forProvider:
          loadBalancerType: "application"
          scheme: "internet-facing"
          subnetIdSelector:
            matchControllerRef: true
            matchLabels:
              Type: "public"
          securityGroupSelector:
            matchControllerRef: true
          tags:
            Name: ""
    patches:
    - type: FromCompositeFieldPath
      fromFieldPath: spec.parameters.appName
      toFieldPath: spec.forProvider.tags.Name
      transforms:
      - type: string
        string:
          fmt: "%s-alb"
    - type: FromCompositeFieldPath
      fromFieldPath: spec.parameters.region
      toFieldPath: spec.forProvider.region
    - type: ToCompositeFieldPath
      fromFieldPath: status.atProvider.dnsName
      toFieldPath: status.loadBalancerUrl

  # Launch Template
  - name: launch-template
    base:
      apiVersion: ec2.aws.upbound.io/v1beta1
      kind: LaunchTemplate
      spec:
        forProvider:
          imageId: "ami-0c02fb55956c7d316"  # Amazon Linux 2
          instanceType: ""
          keyName: "my-key-pair"
          vpcSecurityGroupIdSelector:
            matchControllerRef: true
          userData: ""
          tags:
            Name: ""
    patches:
    - type: FromCompositeFieldPath
      fromFieldPath: spec.parameters.appName
      toFieldPath: spec.forProvider.tags.Name
      transforms:
      - type: string
        string:
          fmt: "%s-launch-template"
    - type: FromCompositeFieldPath
      fromFieldPath: spec.parameters.region
      toFieldPath: spec.forProvider.region
    - type: FromCompositeFieldPath
      fromFieldPath: spec.parameters.instanceType
      toFieldPath: spec.forProvider.instanceType
    - type: FromCompositeFieldPath
      fromFieldPath: spec.parameters.appName
      toFieldPath: spec.forProvider.userData
      transforms:
      - type: string
        string:
          fmt: |
            #!/bin/bash
            yum update -y
            yum install -y docker
            systemctl start docker
            systemctl enable docker
            usermod -aG docker ec2-user
            echo "Application: %s" > /var/log/app-info.log

  # Auto Scaling Group
  - name: auto-scaling-group
    base:
      apiVersion: autoscaling.aws.upbound.io/v1beta1
      kind: AutoScalingGroup
      spec:
        forProvider:
          desiredCapacity: 2
          maxSize: 10
          minSize: 1
          vpcZoneIdentifierSelector:
            matchControllerRef: true
            matchLabels:
              Type: "public"
          launchTemplate:
          - version: "$Latest"
          tags:
          - key: "Name"
            value: ""
            propagateAtLaunch: true
    patches:
    - type: FromCompositeFieldPath
      fromFieldPath: spec.parameters.appName
      toFieldPath: spec.forProvider.tags[0].value
      transforms:
      - type: string
        string:
          fmt: "%s-asg-instance"
    - type: FromCompositeFieldPath
      fromFieldPath: spec.parameters.region
      toFieldPath: spec.forProvider.region
    - type: FromCompositeFieldPath
      fromFieldPath: spec.parameters.minSize
      toFieldPath: spec.forProvider.minSize
    - type: FromCompositeFieldPath
      fromFieldPath: spec.parameters.maxSize
      toFieldPath: spec.forProvider.maxSize
    - type: FromCompositeFieldPath
      fromFieldPath: spec.parameters.environment
      toFieldPath: spec.forProvider.desiredCapacity
      transforms:
      - type: map
        map:
          dev: 1
          staging: 2
          prod: 3

  # Status patches to expose important information
  writeConnectionSecretsToNamespace: crossplane-system
```

### **2. Multi-Cloud Database Platform**
```yaml
# infrastructure/xrds/database-xrd.yaml
apiVersion: apiextensions.crossplane.io/v1
kind: CompositeResourceDefinition
metadata:
  name: xdatabases.platform.example.com
spec:
  group: platform.example.com
  names:
    kind: XDatabase
    plural: xdatabases
  claimNames:
    kind: Database
    plural: databases
  versions:
  - name: v1alpha1
    served: true
    referenceable: true
    schema:
      openAPIV3Schema:
        type: object
        properties:
          spec:
            type: object
            properties:
              parameters:
                type: object
                properties:
                  provider:
                    type: string
                    enum: ["aws", "gcp", "azure"]
                    description: "Cloud provider"
                  engine:
                    type: string
                    enum: ["postgres", "mysql", "mongodb"]
                    description: "Database engine"
                  size:
                    type: string
                    enum: ["small", "medium", "large"]
                    description: "Database size"
                  region:
                    type: string
                    description: "Region for deployment"
                  highAvailability:
                    type: boolean
                    default: false
                    description: "Enable high availability"
                  backup:
                    type: object
                    properties:
                      enabled:
                        type: boolean
                        default: true
                      retentionDays:
                        type: integer
                        default: 7
                        minimum: 1
                        maximum: 35
                required:
                - provider
                - engine
                - size
                - region
          status:
            type: object
            properties:
              endpoint:
                type: string
                description: "Database connection endpoint"
              port:
                type: integer
                description: "Database port"

---
# infrastructure/compositions/database-aws.yaml
apiVersion: apiextensions.crossplane.io/v1
kind: Composition
metadata:
  name: database-aws
  labels:
    provider: aws
    service: database
spec:
  compositeTypeRef:
    apiVersion: platform.example.com/v1alpha1
    kind: XDatabase

  resources:
  # AWS RDS Instance
  - name: rds-instance
    base:
      apiVersion: rds.aws.upbound.io/v1beta1
      kind: Instance
      spec:
        forProvider:
          dbName: "app"
          username: "admin"
          manageMasterUserPassword: true
          storageEncrypted: true
          backupRetentionPeriod: 7
          backupWindow: "03:00-04:00"
          maintenanceWindow: "sun:04:00-sun:05:00"
          skipFinalSnapshot: false
          finalSnapshotIdentifier: ""
          tags:
            ManagedBy: "crossplane"
        writeConnectionSecretsToRef:
          namespace: crossplane-system
    patches:
    # Engine mapping
    - type: FromCompositeFieldPath
      fromFieldPath: spec.parameters.engine
      toFieldPath: spec.forProvider.engine
      transforms:
      - type: map
        map:
          postgres: "postgres"
          mysql: "mysql"
    
    # Engine version mapping
    - type: FromCompositeFieldPath
      fromFieldPath: spec.parameters.engine
      toFieldPath: spec.forProvider.engineVersion
      transforms:
      - type: map
        map:
          postgres: "14.9"
          mysql: "8.0.35"
    
    # Instance class based on size
    - type: FromCompositeFieldPath
      fromFieldPath: spec.parameters.size
      toFieldPath: spec.forProvider.instanceClass
      transforms:
      - type: map
        map:
          small: "db.t3.micro"
          medium: "db.t3.small"
          large: "db.t3.medium"
    
    # Storage based on size
    - type: FromCompositeFieldPath
      fromFieldPath: spec.parameters.size
      toFieldPath: spec.forProvider.allocatedStorage
      transforms:
      - type: map
        map:
          small: 20
          medium: 100
          large: 500
    
    # High availability
    - type: FromCompositeFieldPath
      fromFieldPath: spec.parameters.highAvailability
      toFieldPath: spec.forProvider.multiAz
    
    # Backup retention
    - type: FromCompositeFieldPath
      fromFieldPath: spec.parameters.backup.retentionDays
      toFieldPath: spec.forProvider.backupRetentionPeriod
    
    # Region
    - type: FromCompositeFieldPath
      fromFieldPath: spec.parameters.region
      toFieldPath: spec.forProvider.region
    
    # Final snapshot identifier
    - type: FromCompositeFieldPath
      fromFieldPath: metadata.name
      toFieldPath: spec.forProvider.finalSnapshotIdentifier
      transforms:
      - type: string
        string:
          fmt: "%s-final-snapshot"
    
    # Connection secret name
    - type: FromCompositeFieldPath
      fromFieldPath: metadata.name
      toFieldPath: spec.writeConnectionSecretsToRef.name
      transforms:
      - type: string
        string:
          fmt: "%s-connection"
    
    # Status patches
    - type: ToCompositeFieldPath
      fromFieldPath: status.atProvider.endpoint
      toFieldPath: status.endpoint
    - type: ToCompositeFieldPath
      fromFieldPath: status.atProvider.port
      toFieldPath: status.port

---
# infrastructure/compositions/database-gcp.yaml
apiVersion: apiextensions.crossplane.io/v1
kind: Composition
metadata:
  name: database-gcp
  labels:
    provider: gcp
    service: database
spec:
  compositeTypeRef:
    apiVersion: platform.example.com/v1alpha1
    kind: XDatabase

  resources:
  # GCP Cloud SQL Instance
  - name: cloudsql-instance
    base:
      apiVersion: sql.gcp.upbound.io/v1beta1
      kind: DatabaseInstance
      spec:
        forProvider:
          databaseVersion: ""
          settings:
          - tier: ""
            backupConfiguration:
            - enabled: true
              startTime: "03:00"
              pointInTimeRecoveryEnabled: true
            ipConfiguration:
            - ipv4Enabled: true
              authorizedNetworks:
              - name: "all"
                value: "0.0.0.0/0"
            maintenanceWindow:
            - day: 7
              hour: 4
              updateTrack: "stable"
        writeConnectionSecretsToRef:
          namespace: crossplane-system
    patches:
    # Database version mapping
    - type: FromCompositeFieldPath
      fromFieldPath: spec.parameters.engine
      toFieldPath: spec.forProvider.databaseVersion
      transforms:
      - type: map
        map:
          postgres: "POSTGRES_14"
          mysql: "MYSQL_8_0"
    
    # Tier based on size
    - type: FromCompositeFieldPath
      fromFieldPath: spec.parameters.size
      toFieldPath: spec.forProvider.settings[0].tier
      transforms:
      - type: map
        map:
          small: "db-f1-micro"
          medium: "db-n1-standard-1"
          large: "db-n1-standard-2"
    
    # High availability
    - type: FromCompositeFieldPath
      fromFieldPath: spec.parameters.highAvailability
      toFieldPath: spec.forProvider.settings[0].availabilityType
      transforms:
      - type: map
        map:
          true: "REGIONAL"
          false: "ZONAL"
    
    # Backup configuration
    - type: FromCompositeFieldPath
      fromFieldPath: spec.parameters.backup.enabled
      toFieldPath: spec.forProvider.settings[0].backupConfiguration[0].enabled
    
    # Region
    - type: FromCompositeFieldPath
      fromFieldPath: spec.parameters.region
      toFieldPath: spec.forProvider.region
    
    # Connection secret
    - type: FromCompositeFieldPath
      fromFieldPath: metadata.name
      toFieldPath: spec.writeConnectionSecretsToRef.name
      transforms:
      - type: string
        string:
          fmt: "%s-connection"
    
    # Status patches
    - type: ToCompositeFieldPath
      fromFieldPath: status.atProvider.connectionName
      toFieldPath: status.endpoint
    - type: ToCompositeFieldPath
      fromFieldPath: status.atProvider.ipAddress[0].ipAddress
      toFieldPath: status.ipAddress
```

### **3. Usage Examples**
```yaml
# applications/dev-web-app.yaml
apiVersion: platform.example.com/v1alpha1
kind: WebApplication
metadata:
  name: dev-web-app
  namespace: development
spec:
  parameters:
    environment: dev
    region: us-west-2
    appName: my-awesome-app
    instanceType: t3.micro
    minSize: 1
    maxSize: 3
    dbStorage: 20
  compositionRef:
    name: web-application-aws

---
# applications/prod-database.yaml
apiVersion: platform.example.com/v1alpha1
kind: Database
metadata:
  name: prod-database
  namespace: production
spec:
  parameters:
    provider: aws
    engine: postgres
    size: large
    region: us-east-1
    highAvailability: true
    backup:
      enabled: true
      retentionDays: 30
  compositionRef:
    name: database-aws
```

## Advanced Features

### **1. Configuration and Environment Management**
```yaml
# config/environments/dev-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: dev-environment-config
  namespace: crossplane-system
data:
  default-region: "us-west-2"
  instance-types: |
    small: t3.micro
    medium: t3.small
    large: t3.medium
  database-config: |
    backup-retention: "7"
    multi-az: "false"
    storage-encrypted: "true"

---
# config/environments/prod-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: prod-environment-config
  namespace: crossplane-system
data:
  default-region: "us-east-1"
  instance-types: |
    small: t3.small
    medium: t3.medium
    large: t3.large
  database-config: |
    backup-retention: "30"
    multi-az: "true"
    storage-encrypted: "true"

---
# Enhanced composition with environment-aware configuration
apiVersion: apiextensions.crossplane.io/v1
kind: Composition
metadata:
  name: environment-aware-webapp
spec:
  compositeTypeRef:
    apiVersion: platform.example.com/v1alpha1
    kind: XWebApplication
  
  # Environment-specific functions
  functions:
  - name: environment-config
    type: function
    step: environment-config
    input:
      apiVersion: template.fn.crossplane.io/v1beta1
      kind: GoTemplate
      source: Inline
      inline: |
        {{ $env := .observed.composite.resource.spec.parameters.environment }}
        {{ $config := index .observed.resources "environment-config" }}
        
        # Set environment-specific defaults
        {{ if eq $env "prod" }}
        {{ $instanceType := "t3.large" }}
        {{ $minSize := 3 }}
        {{ $multiAz := true }}
        {{ else }}
        {{ $instanceType := "t3.micro" }}
        {{ $minSize := 1 }}
        {{ $multiAz := false }}
        {{ end }}
        
        # Apply configuration
        resources:
        - name: auto-scaling-group
          base:
            spec:
              forProvider:
                minSize: {{ $minSize }}
                desiredCapacity: {{ $minSize }}
        - name: database
          base:
            spec:
              forProvider:
                instanceClass: {{ if eq $env "prod" }}db.t3.medium{{ else }}db.t3.micro{{ end }}
                multiAz: {{ $multiAz }}
```

### **2. Policy and Governance**
```yaml
# policies/resource-policies.yaml
apiVersion: apiextensions.crossplane.io/v1alpha1
kind: CompositionValidation
metadata:
  name: security-policy
spec:
  compositeTypeRef:
    apiVersion: platform.example.com/v1alpha1
    kind: XWebApplication
  validations:
  - rule: "spec.parameters.environment in ['dev', 'staging', 'prod']"
    message: "Environment must be one of: dev, staging, prod"
  - rule: |
      spec.parameters.environment == 'prod' 
      ? spec.parameters.highAvailability == true 
      : true
    message: "Production environments must have high availability enabled"
  - rule: |
      spec.parameters.dbStorage >= 20 && spec.parameters.dbStorage <= 1000
    message: "Database storage must be between 20GB and 1000GB"

---
# RBAC for platform teams
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: platform-user
rules:
- apiGroups: ["platform.example.com"]
  resources: ["webapplications", "databases"]
  verbs: ["create", "get", "list", "watch", "update", "patch"]
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "list"]
  resourceNames: ["*-connection"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: developers-platform-access
subjects:
- kind: Group
  name: developers
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: platform-user
  apiGroup: rbac.authorization.k8s.io

---
# Namespace-based isolation
apiVersion: v1
kind: Namespace
metadata:
  name: team-frontend
  labels:
    team: frontend
    environment: dev

---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  namespace: team-frontend
  name: frontend-team-access
subjects:
- kind: User
  name: alice@company.com
  apiGroup: rbac.authorization.k8s.io
- kind: User
  name: bob@company.com
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: platform-user
  apiGroup: rbac.authorization.k8s.io
```

### **3. Monitoring and Observability**
```yaml
# monitoring/composition-monitoring.yaml
apiVersion: apiextensions.crossplane.io/v1
kind: Composition
metadata:
  name: monitored-web-application
spec:
  compositeTypeRef:
    apiVersion: platform.example.com/v1alpha1
    kind: XWebApplication
  
  resources:
  # ... existing resources ...
  
  # CloudWatch Alarms
  - name: high-cpu-alarm
    base:
      apiVersion: cloudwatch.aws.upbound.io/v1beta1
      kind: MetricAlarm
      spec:
        forProvider:
          alarmName: ""
          comparisonOperator: "GreaterThanThreshold"
          evaluationPeriods: 2
          metricName: "CPUUtilization"
          namespace: "AWS/EC2"
          period: 300
          statistic: "Average"
          threshold: 80
          alarmDescription: "High CPU utilization"
          alarmActions: []
          dimensions:
            AutoScalingGroupName: ""
    patches:
    - type: FromCompositeFieldPath
      fromFieldPath: spec.parameters.appName
      toFieldPath: spec.forProvider.alarmName
      transforms:
      - type: string
        string:
          fmt: "%s-high-cpu"
    - type: FromCompositeFieldPath
      fromFieldPath: spec.parameters.region
      toFieldPath: spec.forProvider.region

  # Application Insights
  - name: application-insights
    base:
      apiVersion: applicationinsights.aws.upbound.io/v1beta1
      kind: Application
      spec:
        forProvider:
          resourceGroupName: ""
          autoConfigEnabled: true
          autoCreate: true
          tags:
            ManagedBy: "crossplane"
    patches:
    - type: FromCompositeFieldPath
      fromFieldPath: spec.parameters.appName
      toFieldPath: spec.forProvider.resourceGroupName
      transforms:
      - type: string
        string:
          fmt: "%s-resource-group"
    - type: FromCompositeFieldPath
      fromFieldPath: spec.parameters.region
      toFieldPath: spec.forProvider.region

  # Custom metrics using Functions
  - name: custom-metrics
    base:
      apiVersion: template.fn.crossplane.io/v1beta1
      kind: GoTemplate
      spec:
        source: Inline
        inline: |
          {{ range .observed.composite.resource.status.conditions }}
          apiVersion: v1
          kind: Event
          metadata:
            name: {{ $.observed.composite.resource.metadata.name }}-{{ .type | lower }}
            namespace: {{ $.observed.composite.resource.metadata.namespace }}
          message: "WebApplication {{ $.observed.composite.resource.metadata.name }}: {{ .message }}"
          reason: "{{ .reason }}"
          type: "{{ if eq .status "True" }}Normal{{ else }}Warning{{ end }}"
          source:
            component: "crossplane-composition"
          ---
          {{ end }}
```

## CI/CD Integration

### **1. GitOps with ArgoCD**
```yaml
# gitops/applications/web-app-dev.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: web-app-dev
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/company/platform-configs
    targetRevision: HEAD
    path: environments/dev/web-applications
  destination:
    server: https://kubernetes.default.svc
    namespace: development
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true

---
# gitops/app-of-apps.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: platform-infrastructure
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/company/platform-configs
    targetRevision: HEAD
    path: gitops/applications
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### **2. GitHub Actions Pipeline**
```yaml
# .github/workflows/platform-deploy.yml
name: Platform Infrastructure Deployment

on:
  push:
    paths:
    - 'infrastructure/**'
    - 'compositions/**'
    branches: [main, develop]
  pull_request:
    paths:
    - 'infrastructure/**'
    - 'compositions/**'

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup kubectl
      uses: azure/setup-kubectl@v3
      with:
        version: 'latest'
    
    - name: Validate Crossplane manifests
      run: |
        # Validate YAML syntax
        find infrastructure/ compositions/ -name "*.yaml" -o -name "*.yml" | xargs -I {} kubectl --dry-run=client apply -f {}
        
        # Check for required fields
        for file in infrastructure/xrds/*.yaml; do
          if ! grep -q "openAPIV3Schema" "$file"; then
            echo "ERROR: $file missing openAPIV3Schema"
            exit 1
          fi
        done
    
    - name: Lint with crossplane CLI
      run: |
        curl -sL https://raw.githubusercontent.com/crossplane/crossplane/master/install.sh | sh
        sudo mv kubectl-crossplane /usr/local/bin
        kubectl crossplane beta validate infrastructure/

  deploy-dev:
    if: github.ref == 'refs/heads/develop'
    needs: validate
    runs-on: ubuntu-latest
    environment: development
    steps:
    - uses: actions/checkout@v3
    
    - name: Configure kubectl
      env:
        KUBE_CONFIG: ${{ secrets.KUBE_CONFIG_DEV }}
      run: |
        mkdir -p ~/.kube
        echo "$KUBE_CONFIG" | base64 -d > ~/.kube/config
        chmod 600 ~/.kube/config
    
    - name: Deploy XRDs
      run: |
        kubectl apply -f infrastructure/xrds/
        kubectl wait --for=condition=established --timeout=60s crd --all
    
    - name: Deploy Compositions
      run: |
        kubectl apply -f infrastructure/compositions/
    
    - name: Verify deployment
      run: |
        kubectl get xrd
        kubectl get compositions

  deploy-prod:
    if: github.ref == 'refs/heads/main'
    needs: validate
    runs-on: ubuntu-latest
    environment: production
    steps:
    - uses: actions/checkout@v3
    
    - name: Configure kubectl
      env:
        KUBE_CONFIG: ${{ secrets.KUBE_CONFIG_PROD }}
      run: |
        mkdir -p ~/.kube
        echo "$KUBE_CONFIG" | base64 -d > ~/.kube/config
        chmod 600 ~/.kube/config
    
    - name: Deploy with approval
      run: |
        echo "Deploying to production..."
        kubectl apply -f infrastructure/xrds/
        kubectl wait --for=condition=established --timeout=60s crd --all
        kubectl apply -f infrastructure/compositions/
    
    - name: Run integration tests
      run: |
        # Test creating a sample application
        cat <<EOF | kubectl apply -f -
        apiVersion: platform.example.com/v1alpha1
        kind: WebApplication
        metadata:
          name: test-app
          namespace: test
        spec:
          parameters:
            environment: dev
            region: us-west-2
            appName: integration-test
        EOF
        
        # Wait for resources to be created
        kubectl wait --for=condition=Ready --timeout=300s webapplication/test-app -n test
        
        # Cleanup
        kubectl delete webapplication/test-app -n test
```

## Best Practices

### **1. Composition Design Patterns**
```yaml
# Pattern 1: Layered Compositions
# Base infrastructure composition
apiVersion: apiextensions.crossplane.io/v1
kind: Composition
metadata:
  name: base-infrastructure
spec:
  # VPC, Subnets, Security Groups, etc.

---
# Application composition that uses base infrastructure
apiVersion: apiextensions.crossplane.io/v1
kind: Composition
metadata:
  name: web-application
spec:
  # References base infrastructure
  resources:
  - name: infrastructure
    base:
      apiVersion: platform.example.com/v1alpha1
      kind: XBaseInfrastructure

# Pattern 2: Composable Functions
functions:
- name: resource-namer
  type: function
  step: naming
  input:
    apiVersion: template.fn.crossplane.io/v1beta1
    kind: GoTemplate
    source: Inline
    inline: |
      {{ $name := .observed.composite.resource.metadata.name }}
      {{ $env := .observed.composite.resource.spec.parameters.environment }}
      {{ $region := .observed.composite.resource.spec.parameters.region }}
      
      # Generate consistent naming
      {{ range .desired.resources }}
      metadata:
        name: {{ $name }}-{{ $env }}-{{ .metadata.name }}-{{ $region }}
      {{ end }}

# Pattern 3: Environment-specific patches
environmentSpecificPatches:
  dev:
    - type: FromCompositeFieldPath
      fromFieldPath: spec.parameters.environment
      toFieldPath: spec.forProvider.instanceType
      transforms:
      - type: string
        string:
          fmt: "t3.micro"
  prod:
    - type: FromCompositeFieldPath
      fromFieldPath: spec.parameters.environment
      toFieldPath: spec.forProvider.instanceType
      transforms:
      - type: string
        string:
          fmt: "t3.large"
```

### **2. Testing Strategy**
```bash
#!/bin/bash
# scripts/test-compositions.sh

set -e

echo "🧪 Testing Crossplane Compositions"

# Function to test composition
test_composition() {
    local composition_file=$1
    local test_claim=$2
    
    echo "Testing $composition_file..."
    
    # Apply composition
    kubectl apply -f "$composition_file"
    
    # Create test claim
    kubectl apply -f "$test_claim"
    
    # Wait for resources
    local claim_name=$(yq e '.metadata.name' "$test_claim")
    local claim_namespace=$(yq e '.metadata.namespace' "$test_claim")
    
    kubectl wait --for=condition=Ready --timeout=300s \
        -n "$claim_namespace" \
        $(yq e '.kind' "$test_claim")"/$claim_name"
    
    # Verify resources were created
    local composite_name=$(kubectl get -n "$claim_namespace" \
        $(yq e '.kind' "$test_claim") "$claim_name" \
        -o jsonpath='{.spec.resourceRef.name}')
    
    echo "✅ Composite resource $composite_name created successfully"
    
    # Check managed resources
    kubectl get managed --selector crossplane.io/composite="$composite_name"
    
    # Cleanup
    kubectl delete -f "$test_claim"
    kubectl delete -f "$composition_file"
    
    echo "✅ Test completed successfully"
}

# Test all compositions
for composition in infrastructure/compositions/*.yaml; do
    test_file="tests/$(basename "$composition" .yaml).test.yaml"
    if [[ -f "$test_file" ]]; then
        test_composition "$composition" "$test_file"
    else
        echo "⚠️ No test file found for $composition"
    fi
done

echo "🎉 All composition tests completed!"
```

### **3. Debugging and Troubleshooting**
```bash
# Useful debugging commands

# Check Crossplane status
kubectl get providers
kubectl get compositions
kubectl get xrd

# Debug composition issues
kubectl describe composition web-application-aws

# Check managed resources
kubectl get managed
kubectl describe managed

# View composite resource status
kubectl get xwebapplications
kubectl describe xwebapplication my-app

# Check events
kubectl get events --sort-by=.metadata.creationTimestamp

# Debug provider issues
kubectl logs -n crossplane-system deployment/crossplane-provider-aws

# Check resource conditions
kubectl get webapplication my-app -o yaml | yq e '.status.conditions'
```

## Useful Links

- [Crossplane Documentation](https://docs.crossplane.io/)
- [Crossplane GitHub](https://github.com/crossplane/crossplane)
- [Provider Documentation](https://marketplace.upbound.io/)
- [Crossplane Slack](https://slack.crossplane.io/)
- [Composition Functions](https://docs.crossplane.io/v1.14/concepts/composition-functions/)
- [Upbound Registry](https://marketplace.upbound.io/)
