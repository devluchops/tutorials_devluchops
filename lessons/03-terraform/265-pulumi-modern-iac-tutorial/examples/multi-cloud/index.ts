// Multi-Cloud Infrastructure with Pulumi
import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";
import * as gcp from "@pulumi/gcp";
import * as azure from "@pulumi/azure-native";

// Configuration
const config = new pulumi.Config();
const environment = config.require("environment");
const region = config.get("region") || "us-west-2";

// AWS Resources
const awsProvider = new aws.Provider("aws-provider", {
    region: region,
});

const awsVpc = new aws.ec2.Vpc("aws-vpc", {
    cidrBlock: "10.0.0.0/16",
    enableDnsHostnames: true,
    enableDnsSupport: true,
    tags: {
        Name: `aws-vpc-${environment}`,
        Environment: environment,
        Provider: "aws",
    },
}, { provider: awsProvider });

const awsSubnet = new aws.ec2.Subnet("aws-subnet", {
    vpcId: awsVpc.id,
    cidrBlock: "10.0.1.0/24",
    availabilityZone: `${region}a`,
    mapPublicIpOnLaunch: true,
    tags: {
        Name: `aws-subnet-${environment}`,
        Environment: environment,
    },
}, { provider: awsProvider });

const awsSecurityGroup = new aws.ec2.SecurityGroup("aws-sg", {
    vpcId: awsVpc.id,
    description: "Allow HTTP and SSH",
    ingress: [
        {
            protocol: "tcp",
            fromPort: 80,
            toPort: 80,
            cidrBlocks: ["0.0.0.0/0"],
        },
        {
            protocol: "tcp",
            fromPort: 22,
            toPort: 22,
            cidrBlocks: ["0.0.0.0/0"],
        },
    ],
    egress: [
        {
            protocol: "-1",
            fromPort: 0,
            toPort: 0,
            cidrBlocks: ["0.0.0.0/0"],
        },
    ],
    tags: {
        Name: `aws-sg-${environment}`,
        Environment: environment,
    },
}, { provider: awsProvider });

// GCP Resources
const gcpProject = config.require("gcpProject");
const gcpProvider = new gcp.Provider("gcp-provider", {
    project: gcpProject,
    region: "us-central1",
});

const gcpNetwork = new gcp.compute.Network("gcp-network", {
    autoCreateSubnetworks: false,
    description: "Custom VPC network",
}, { provider: gcpProvider });

const gcpSubnet = new gcp.compute.Subnetwork("gcp-subnet", {
    network: gcpNetwork.id,
    ipCidrRange: "10.1.0.0/16",
    region: "us-central1",
    description: "Custom subnet",
}, { provider: gcpProvider });

const gcpFirewall = new gcp.compute.Firewall("gcp-firewall", {
    network: gcpNetwork.id,
    allows: [
        {
            protocol: "tcp",
            ports: ["80", "22"],
        },
    ],
    sourceRanges: ["0.0.0.0/0"],
    description: "Allow HTTP and SSH",
}, { provider: gcpProvider });

// Azure Resources
const azureProvider = new azure.Provider("azure-provider", {});

const azureRg = new azure.resources.ResourceGroup("azure-rg", {
    location: "East US",
    resourceGroupName: `rg-${environment}`,
}, { provider: azureProvider });

const azureVnet = new azure.network.VirtualNetwork("azure-vnet", {
    resourceGroupName: azureRg.name,
    location: azureRg.location,
    virtualNetworkName: `vnet-${environment}`,
    addressSpace: {
        addressPrefixes: ["10.2.0.0/16"],
    },
}, { provider: azureProvider });

const azureSubnet = new azure.network.Subnet("azure-subnet", {
    resourceGroupName: azureRg.name,
    virtualNetworkName: azureVnet.name,
    subnetName: `subnet-${environment}`,
    addressPrefix: "10.2.1.0/24",
}, { provider: azureProvider });

// Cross-Cloud Load Balancer using AWS
const crossCloudAlb = new aws.lb.LoadBalancer("cross-cloud-alb", {
    loadBalancerType: "application",
    subnets: [awsSubnet.id],
    securityGroups: [awsSecurityGroup.id],
    enableDeletionProtection: false,
    tags: {
        Name: `cross-cloud-alb-${environment}`,
        Environment: environment,
    },
}, { provider: awsProvider });

// Outputs
export const awsVpcId = awsVpc.id;
export const gcpNetworkId = gcpNetwork.id;
export const azureVnetId = azureVnet.id;
export const loadBalancerDns = crossCloudAlb.dnsName;

// Stack outputs with descriptions
export const outputs = {
    aws: {
        vpcId: awsVpc.id,
        subnetId: awsSubnet.id,
        region: region,
    },
    gcp: {
        networkId: gcpNetwork.id,
        subnetId: gcpSubnet.id,
        project: gcpProject,
    },
    azure: {
        resourceGroupName: azureRg.name,
        vnetId: azureVnet.id,
        location: azureRg.location,
    },
    crossCloud: {
        loadBalancerDns: crossCloudAlb.dnsName,
        loadBalancerArn: crossCloudAlb.arn,
    },
};
