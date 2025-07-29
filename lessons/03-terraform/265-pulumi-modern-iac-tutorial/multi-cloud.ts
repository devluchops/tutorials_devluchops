// multi-cloud.ts
import * as aws from "@pulumi/aws";
import * as gcp from "@pulumi/gcp";
import * as azure from "@pulumi/azure-native";

// AWS Resources
const awsVpc = new aws.ec2.Vpc("aws-vpc", {
  cidrBlock: "10.0.0.0/16",
  tags: { Name: "aws-primary-vpc" }
});

// AWS Subnets
const awsPublicSubnet = new aws.ec2.Subnet("aws-public-subnet", {
  vpcId: awsVpc.id,
  cidrBlock: "10.0.1.0/24",
  availabilityZone: "us-west-2a",
  mapPublicIpOnLaunch: true,
  tags: { Name: "aws-public-subnet" }
});

const awsPrivateSubnet = new aws.ec2.Subnet("aws-private-subnet", {
  vpcId: awsVpc.id,
  cidrBlock: "10.0.2.0/24",
  availabilityZone: "us-west-2b",
  tags: { Name: "aws-private-subnet" }
});

// Internet Gateway
const awsIgw = new aws.ec2.InternetGateway("aws-igw", {
  vpcId: awsVpc.id,
  tags: { Name: "aws-igw" }
});

// GCP Resources  
const gcpNetwork = new gcp.compute.Network("gcp-network", {
  autoCreateSubnetworks: false,
  description: "GCP network for multi-cloud setup"
});

const gcpSubnet = new gcp.compute.Subnetwork("gcp-subnet", {
  ipCidrRange: "10.1.0.0/16",
  network: gcpNetwork.id,
  region: "us-central1",
  description: "GCP subnet for multi-cloud setup"
});

// Azure Resources
const azureRg = new azure.resources.ResourceGroup("azure-rg", {
  location: "East US",
  resourceGroupName: "multi-cloud-rg"
});

const azureVnet = new azure.network.VirtualNetwork("azure-vnet", {
  resourceGroupName: azureRg.name,
  location: azureRg.location,
  addressSpace: {
    addressPrefixes: ["10.2.0.0/16"]
  },
  virtualNetworkName: "azure-vnet"
});

const azureSubnet = new azure.network.Subnet("azure-subnet", {
  resourceGroupName: azureRg.name,
  virtualNetworkName: azureVnet.name,
  addressPrefix: "10.2.1.0/24",
  subnetName: "azure-subnet"
});

// Cross-cloud connectivity setup
// AWS Customer Gateway (for VPN)
const customerGateway = new aws.ec2.CustomerGateway("customer-gateway", {
  bgpAsn: 65000,
  ipAddress: "203.0.113.12", // Example public IP
  type: "ipsec.1",
  tags: { Name: "gcp-customer-gateway" }
});

// VPN Gateway
const vpnGateway = new aws.ec2.VpnGateway("vpn-gateway", {
  vpcId: awsVpc.id,
  tags: { Name: "aws-vpn-gateway" }
});

// VPN Connection
const vpnConnection = new aws.ec2.VpnConnection("aws-gcp-vpn", {
  customerGatewayId: customerGateway.id,
  vpnGatewayId: vpnGateway.id,
  type: "ipsec.1",
  staticRoutesOnly: true,
  tags: { Name: "aws-gcp-vpn" }
});

// Export important values
export const awsVpcId = awsVpc.id;
export const awsVpcCidr = awsVpc.cidrBlock;
export const gcpNetworkId = gcpNetwork.id;
export const gcpNetworkSelfLink = gcpNetwork.selfLink;
export const azureResourceGroupName = azureRg.name;
export const azureVnetId = azureVnet.id;
export const vpnConnectionId = vpnConnection.id;
