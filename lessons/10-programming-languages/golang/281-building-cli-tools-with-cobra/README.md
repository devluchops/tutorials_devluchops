# Tutorial 281: Building CLI Tools with Cobra

## 🎯 Overview

Learn to build professional command-line tools using Cobra, the same library used by kubectl, docker, and many other popular DevOps tools. Create a feature-rich CLI application for infrastructure management.

### What You'll Learn
- ✅ Setting up Cobra CLI framework
- ✅ Creating commands, subcommands, and flags
- ✅ Input validation and error handling
- ✅ Configuration file management
- ✅ Auto-completion and help generation
- ✅ Building and distributing CLI tools

### Prerequisites
- Go installed (1.21+)
- Basic Go knowledge (complete Tutorial 280 first)
- Command line familiarity

### Time to Complete
⏱️ Approximately 45 minutes

## 🏗️ Architecture

We'll build `devctl` - a DevOps CLI tool:

```
devctl
├── cluster (manage clusters)
│   ├── create
│   ├── delete
│   ├── list
│   └── status
├── deploy (deployment management)
│   ├── app
│   ├── rollback
│   └── status
└── config (configuration management)
    ├── get
    ├── set
    └── list
```

## 🛠️ Setup

### Step 1: Initialize Project
```bash
mkdir devctl
cd devctl
go mod init devctl
```

### Step 2: Install Cobra
```bash
go get -u github.com/spf13/cobra@latest
go get -u github.com/spf13/viper@latest
```

### Step 3: Install Cobra CLI Generator (Optional)
```bash
go install github.com/spf13/cobra-cli@latest
```

## 📋 Implementation

### Phase 1: Basic CLI Structure

**main.go:**
```go
package main

import "devctl/cmd"

func main() {
    cmd.Execute()
}
```

**cmd/root.go:**
```go
package cmd

import (
    "fmt"
    "os"
    
    "github.com/spf13/cobra"
    "github.com/spf13/viper"
)

var cfgFile string

// rootCmd represents the base command when called without any subcommands
var rootCmd = &cobra.Command{
    Use:   "devctl",
    Short: "A DevOps CLI tool for infrastructure management",
    Long: `devctl is a comprehensive CLI tool for DevOps engineers to manage
clusters, deployments, and configurations efficiently.

Built with Go and Cobra, it provides a kubectl-like experience
for your infrastructure operations.`,
    Version: "1.0.0",
}

// Execute adds all child commands to the root command and sets flags appropriately.
func Execute() {
    err := rootCmd.Execute()
    if err != nil {
        os.Exit(1)
    }
}

func init() {
    cobra.OnInitialize(initConfig)
    
    // Global flags
    rootCmd.PersistentFlags().StringVar(&cfgFile, "config", "", "config file (default is $HOME/.devctl.yaml)")
    rootCmd.PersistentFlags().BoolVarP(&verbose, "verbose", "v", false, "verbose output")
    rootCmd.PersistentFlags().StringVarP(&output, "output", "o", "table", "output format (table|json|yaml)")
    
    // Bind flags to viper
    viper.BindPFlag("verbose", rootCmd.PersistentFlags().Lookup("verbose"))
    viper.BindPFlag("output", rootCmd.PersistentFlags().Lookup("output"))
}

var verbose bool
var output string

// initConfig reads in config file and ENV variables if set.
func initConfig() {
    if cfgFile != "" {
        viper.SetConfigFile(cfgFile)
    } else {
        home, err := os.UserHomeDir()
        cobra.CheckErr(err)
        
        viper.AddConfigPath(home)
        viper.AddConfigPath(".")
        viper.SetConfigType("yaml")
        viper.SetConfigName(".devctl")
    }
    
    viper.AutomaticEnv()
    
    if err := viper.ReadInConfig(); err == nil {
        if viper.GetBool("verbose") {
            fmt.Println("Using config file:", viper.ConfigFileUsed())
        }
    }
}
```

### Phase 2: Cluster Management Commands

**cmd/cluster.go:**
```go
package cmd

import (
    "fmt"
    
    "github.com/spf13/cobra"
)

// clusterCmd represents the cluster command
var clusterCmd = &cobra.Command{
    Use:   "cluster",
    Short: "Manage Kubernetes clusters",
    Long: `Manage Kubernetes clusters with create, delete, list, and status operations.
    
Examples:
  devctl cluster list
  devctl cluster create --name my-cluster --region us-west-2
  devctl cluster delete my-cluster`,
}

var clusterListCmd = &cobra.Command{
    Use:   "list",
    Short: "List all clusters",
    Long:  "List all available Kubernetes clusters with their status and details.",
    Run: func(cmd *cobra.Command, args []string) {
        listClusters()
    },
}

var clusterCreateCmd = &cobra.Command{
    Use:   "create",
    Short: "Create a new cluster",
    Long:  "Create a new Kubernetes cluster with specified configuration.",
    Run: func(cmd *cobra.Command, args []string) {
        createCluster()
    },
}

var clusterDeleteCmd = &cobra.Command{
    Use:   "delete [cluster-name]",
    Short: "Delete a cluster",
    Long:  "Delete an existing Kubernetes cluster.",
    Args:  cobra.ExactArgs(1),
    Run: func(cmd *cobra.Command, args []string) {
        deleteCluster(args[0])
    },
}

var clusterStatusCmd = &cobra.Command{
    Use:   "status [cluster-name]",
    Short: "Show cluster status",
    Long:  "Show detailed status information for a specific cluster.",
    Args:  cobra.ExactArgs(1),
    Run: func(cmd *cobra.Command, args []string) {
        showClusterStatus(args[0])
    },
}

// Cluster command flags
var (
    clusterName   string
    clusterRegion string
    nodeCount     int
    nodeType      string
)

func init() {
    rootCmd.AddCommand(clusterCmd)
    clusterCmd.AddCommand(clusterListCmd)
    clusterCmd.AddCommand(clusterCreateCmd)
    clusterCmd.AddCommand(clusterDeleteCmd)
    clusterCmd.AddCommand(clusterStatusCmd)
    
    // Flags for cluster create
    clusterCreateCmd.Flags().StringVarP(&clusterName, "name", "n", "", "cluster name (required)")
    clusterCreateCmd.Flags().StringVarP(&clusterRegion, "region", "r", "us-west-2", "AWS region")
    clusterCreateCmd.Flags().IntVar(&nodeCount, "nodes", 3, "number of worker nodes")
    clusterCreateCmd.Flags().StringVar(&nodeType, "node-type", "t3.medium", "EC2 instance type for nodes")
    
    clusterCreateCmd.MarkFlagRequired("name")
}

func listClusters() {
    if verbose {
        fmt.Println("🔍 Listing all clusters...")
    }
    
    // Mock cluster data
    clusters := []struct {
        Name    string
        Status  string
        Region  string
        Nodes   int
        Version string
    }{
        {"production", "running", "us-west-2", 5, "1.28"},
        {"staging", "running", "us-east-1", 3, "1.28"},
        {"development", "stopped", "us-west-1", 2, "1.27"},
    }
    
    switch output {
    case "json":
        fmt.Printf("[\n")
        for i, cluster := range clusters {
            fmt.Printf(`  {"name": "%s", "status": "%s", "region": "%s", "nodes": %d, "version": "%s"}`,
                cluster.Name, cluster.Status, cluster.Region, cluster.Nodes, cluster.Version)
            if i < len(clusters)-1 {
                fmt.Printf(",")
            }
            fmt.Printf("\n")
        }
        fmt.Printf("]\n")
    case "yaml":
        fmt.Println("clusters:")
        for _, cluster := range clusters {
            fmt.Printf("- name: %s\n", cluster.Name)
            fmt.Printf("  status: %s\n", cluster.Status)
            fmt.Printf("  region: %s\n", cluster.Region)
            fmt.Printf("  nodes: %d\n", cluster.Nodes)
            fmt.Printf("  version: %s\n", cluster.Version)
        }
    default: // table
        fmt.Printf("%-15s %-10s %-12s %-6s %-8s\n", "NAME", "STATUS", "REGION", "NODES", "VERSION")
        fmt.Printf("%-15s %-10s %-12s %-6s %-8s\n", "----", "------", "------", "-----", "-------")
        for _, cluster := range clusters {
            fmt.Printf("%-15s %-10s %-12s %-6d %-8s\n",
                cluster.Name, cluster.Status, cluster.Region, cluster.Nodes, cluster.Version)
        }
    }
}

func createCluster() {
    fmt.Printf("🚀 Creating cluster '%s' in region '%s'...\n", clusterName, clusterRegion)
    fmt.Printf("   Node count: %d\n", nodeCount)
    fmt.Printf("   Node type: %s\n", nodeType)
    
    // Simulate cluster creation
    fmt.Println("   ✅ VPC created")
    fmt.Println("   ✅ Security groups configured")
    fmt.Println("   ✅ IAM roles created")
    fmt.Println("   ✅ EKS cluster created")
    fmt.Printf("   ✅ %d worker nodes launched\n", nodeCount)
    
    fmt.Printf("✨ Cluster '%s' created successfully!\n", clusterName)
    fmt.Printf("💡 Use 'devctl cluster status %s' to check cluster details\n", clusterName)
}

func deleteCluster(name string) {
    fmt.Printf("🗑️  Deleting cluster '%s'...\n", name)
    
    // Simulate deletion
    fmt.Println("   ⏳ Draining nodes...")
    fmt.Println("   ⏳ Deleting worker nodes...")
    fmt.Println("   ⏳ Deleting EKS cluster...")
    fmt.Println("   ⏳ Cleaning up IAM roles...")
    fmt.Println("   ⏳ Deleting VPC resources...")
    
    fmt.Printf("✨ Cluster '%s' deleted successfully!\n", name)
}

func showClusterStatus(name string) {
    fmt.Printf("📊 Cluster Status: %s\n", name)
    fmt.Printf("=================%s\n", "=".Repeat(len(name)))
    
    // Mock cluster status
    fmt.Printf("Status:           running\n")
    fmt.Printf("Region:           us-west-2\n")
    fmt.Printf("Kubernetes:       v1.28.2\n")
    fmt.Printf("API Server:       https://ABC123.gr7.us-west-2.eks.amazonaws.com\n")
    fmt.Printf("Nodes:            3/3 ready\n")
    fmt.Printf("Pods:             24/30 running\n")
    fmt.Printf("Created:          2024-01-15 10:30:00 UTC\n")
    fmt.Printf("Last Updated:     2024-01-20 14:22:15 UTC\n")
    
    if verbose {
        fmt.Printf("\n🔍 Node Details:\n")
        fmt.Printf("%-20s %-15s %-10s %-8s\n", "NAME", "INSTANCE-ID", "STATUS", "VERSION")
        fmt.Printf("%-20s %-15s %-10s %-8s\n", "----", "-----------", "------", "-------")
        fmt.Printf("%-20s %-15s %-10s %-8s\n", "node-1", "i-1234567890abcdef0", "Ready", "v1.28.2")
        fmt.Printf("%-20s %-15s %-10s %-8s\n", "node-2", "i-0987654321fedcba0", "Ready", "v1.28.2")
        fmt.Printf("%-20s %-15s %-10s %-8s\n", "node-3", "i-abcdef1234567890", "Ready", "v1.28.2")
    }
}
```

### Phase 3: Deploy Management Commands

**cmd/deploy.go:**
```go
package cmd

import (
    "fmt"
    "time"
    
    "github.com/spf13/cobra"
)

var deployCmd = &cobra.Command{
    Use:   "deploy",
    Short: "Manage application deployments",
    Long: `Deploy applications, check deployment status, and manage rollbacks.
    
Examples:
  devctl deploy app --name myapp --image nginx:latest
  devctl deploy status myapp
  devctl deploy rollback myapp --revision 2`,
}

var deployAppCmd = &cobra.Command{
    Use:   "app",
    Short: "Deploy an application",
    Long:  "Deploy an application to the specified cluster with the given configuration.",
    Run: func(cmd *cobra.Command, args []string) {
        deployApplication()
    },
}

var deployStatusCmd = &cobra.Command{
    Use:   "status [app-name]",
    Short: "Show deployment status",
    Long:  "Show detailed deployment status for the specified application.",
    Args:  cobra.ExactArgs(1),
    Run: func(cmd *cobra.Command, args []string) {
        showDeploymentStatus(args[0])
    },
}

var deployRollbackCmd = &cobra.Command{
    Use:   "rollback [app-name]",
    Short: "Rollback a deployment",
    Long:  "Rollback an application deployment to a previous revision.",
    Args:  cobra.ExactArgs(1),
    Run: func(cmd *cobra.Command, args []string) {
        rollbackDeployment(args[0])
    },
}

// Deploy command flags
var (
    appName     string
    appImage    string
    appReplicas int
    appPort     int
    revision    int
)

func init() {
    rootCmd.AddCommand(deployCmd)
    deployCmd.AddCommand(deployAppCmd)
    deployCmd.AddCommand(deployStatusCmd)
    deployCmd.AddCommand(deployRollbackCmd)
    
    // Flags for deploy app
    deployAppCmd.Flags().StringVarP(&appName, "name", "n", "", "application name (required)")
    deployAppCmd.Flags().StringVarP(&appImage, "image", "i", "", "container image (required)")
    deployAppCmd.Flags().IntVarP(&appReplicas, "replicas", "r", 3, "number of replicas")
    deployAppCmd.Flags().IntVarP(&appPort, "port", "p", 80, "container port")
    
    deployAppCmd.MarkFlagRequired("name")
    deployAppCmd.MarkFlagRequired("image")
    
    // Flags for rollback
    deployRollbackCmd.Flags().IntVar(&revision, "revision", 0, "revision to rollback to (0 = previous)")
}

func deployApplication() {
    fmt.Printf("🚀 Deploying application '%s'...\n", appName)
    fmt.Printf("   Image: %s\n", appImage)
    fmt.Printf("   Replicas: %d\n", appReplicas)
    fmt.Printf("   Port: %d\n", appPort)
    
    // Simulate deployment steps
    steps := []string{
        "Creating namespace",
        "Applying deployment manifest",
        "Creating service",
        "Configuring ingress",
        "Waiting for pods to be ready",
    }
    
    for i, step := range steps {
        fmt.Printf("   [%d/%d] %s...", i+1, len(steps), step)
        time.Sleep(500 * time.Millisecond) // Simulate work
        fmt.Printf(" ✅\n")
    }
    
    fmt.Printf("\n✨ Application '%s' deployed successfully!\n", appName)
    fmt.Printf("💡 Use 'devctl deploy status %s' to check deployment status\n", appName)
}

func showDeploymentStatus(name string) {
    fmt.Printf("📊 Deployment Status: %s\n", name)
    fmt.Printf("===================%s\n", "=".Repeat(len(name)))
    
    // Mock deployment status
    fmt.Printf("Status:           Available\n")
    fmt.Printf("Replicas:         3/3 ready\n")
    fmt.Printf("Image:            nginx:1.21\n")
    fmt.Printf("Revision:         3\n")
    fmt.Printf("Age:              2h15m\n")
    fmt.Printf("Strategy:         RollingUpdate\n")
    fmt.Printf("Conditions:       Available, Progressing\n")
    
    if verbose {
        fmt.Printf("\n🔍 Pod Details:\n")
        fmt.Printf("%-30s %-15s %-10s %-8s\n", "NAME", "STATUS", "RESTARTS", "AGE")
        fmt.Printf("%-30s %-15s %-10s %-8s\n", "----", "------", "--------", "---")
        fmt.Printf("%-30s %-15s %-10s %-8s\n", name+"-7d4f8b5c9-abc12", "Running", "0", "2h15m")
        fmt.Printf("%-30s %-15s %-10s %-8s\n", name+"-7d4f8b5c9-def34", "Running", "0", "2h15m")
        fmt.Printf("%-30s %-15s %-10s %-8s\n", name+"-7d4f8b5c9-ghi56", "Running", "0", "2h15m")
        
        fmt.Printf("\n📈 Deployment History:\n")
        fmt.Printf("%-10s %-20s %-15s %-20s\n", "REVISION", "IMAGE", "STATUS", "CREATED")
        fmt.Printf("%-10s %-20s %-15s %-20s\n", "--------", "-----", "------", "-------")
        fmt.Printf("%-10s %-20s %-15s %-20s\n", "3", "nginx:1.21", "Current", "2h15m ago")
        fmt.Printf("%-10s %-20s %-15s %-20s\n", "2", "nginx:1.20", "Previous", "1d ago")
        fmt.Printf("%-10s %-20s %-15s %-20s\n", "1", "nginx:1.19", "Previous", "3d ago")
    }
}

func rollbackDeployment(name string) {
    targetRevision := revision
    if targetRevision == 0 {
        targetRevision = 2 // Previous revision
    }
    
    fmt.Printf("🔄 Rolling back '%s' to revision %d...\n", name, targetRevision)
    
    // Simulate rollback steps
    steps := []string{
        "Fetching deployment history",
        "Validating target revision",
        "Updating deployment",
        "Waiting for rollout to complete",
        "Verifying deployment health",
    }
    
    for i, step := range steps {
        fmt.Printf("   [%d/%d] %s...", i+1, len(steps), step)
        time.Sleep(300 * time.Millisecond)
        fmt.Printf(" ✅\n")
    }
    
    fmt.Printf("\n✨ Rollback completed successfully!\n")
    fmt.Printf("💡 Use 'devctl deploy status %s' to verify the rollback\n", name)
}
```

### Phase 4: Configuration Management

**cmd/config.go:**
```go
package cmd

import (
    "fmt"
    "strings"
    
    "github.com/spf13/cobra"
    "github.com/spf13/viper"
)

var configCmd = &cobra.Command{
    Use:   "config",
    Short: "Manage devctl configuration",
    Long: `Manage devctl configuration settings including clusters, contexts, and preferences.
    
Examples:
  devctl config get
  devctl config set cluster.default production
  devctl config list`,
}

var configGetCmd = &cobra.Command{
    Use:   "get [key]",
    Short: "Get configuration value",
    Long:  "Get a specific configuration value or all values if no key is specified.",
    Args:  cobra.MaximumNArgs(1),
    Run: func(cmd *cobra.Command, args []string) {
        if len(args) == 0 {
            getAllConfig()
        } else {
            getConfig(args[0])
        }
    },
}

var configSetCmd = &cobra.Command{
    Use:   "set [key] [value]",
    Short: "Set configuration value",
    Long:  "Set a configuration value for the specified key.",
    Args:  cobra.ExactArgs(2),
    Run: func(cmd *cobra.Command, args []string) {
        setConfig(args[0], args[1])
    },
}

var configListCmd = &cobra.Command{
    Use:   "list",
    Short: "List all configuration",
    Long:  "List all configuration keys and values.",
    Run: func(cmd *cobra.Command, args []string) {
        getAllConfig()
    },
}

func init() {
    rootCmd.AddCommand(configCmd)
    configCmd.AddCommand(configGetCmd)
    configCmd.AddCommand(configSetCmd)
    configCmd.AddCommand(configListCmd)
}

func getAllConfig() {
    fmt.Println("📋 Current Configuration:")
    fmt.Println("========================")
    
    // Get all settings from viper
    settings := viper.AllSettings()
    
    if len(settings) == 0 {
        fmt.Println("No configuration found. Use 'devctl config set' to add settings.")
        return
    }
    
    switch output {
    case "json":
        // Print JSON format
        for key, value := range settings {
            fmt.Printf(`"%s": "%v",`, key, value)
        }
        fmt.Println()
    case "yaml":
        // Print YAML format
        for key, value := range settings {
            fmt.Printf("%s: %v\n", key, value)
        }
    default: // table
        fmt.Printf("%-25s %-30s\n", "KEY", "VALUE")
        fmt.Printf("%-25s %-30s\n", strings.Repeat("-", 25), strings.Repeat("-", 30))
        for key, value := range settings {
            fmt.Printf("%-25s %-30v\n", key, value)
        }
    }
}

func getConfig(key string) {
    value := viper.Get(key)
    if value == nil {
        fmt.Printf("❌ Configuration key '%s' not found\n", key)
        return
    }
    
    switch output {
    case "json":
        fmt.Printf(`{"%s": "%v"}`, key, value)
        fmt.Println()
    case "yaml":
        fmt.Printf("%s: %v\n", key, value)
    default:
        fmt.Printf("%s = %v\n", key, value)
    }
}

func setConfig(key, value string) {
    viper.Set(key, value)
    
    // Write to config file
    err := viper.WriteConfig()
    if err != nil {
        // If config file doesn't exist, create it
        err = viper.SafeWriteConfig()
        if err != nil {
            fmt.Printf("❌ Failed to write config: %v\n", err)
            return
        }
    }
    
    fmt.Printf("✅ Configuration updated: %s = %s\n", key, value)
    
    if verbose {
        fmt.Printf("💡 Config file: %s\n", viper.ConfigFileUsed())
    }
}
```

## ✅ Verification

### Build and Test the CLI

```bash
# Build the application
go build -o devctl

# Test basic commands
./devctl --help
./devctl version

# Test cluster commands
./devctl cluster list
./devctl cluster create --name test-cluster --region us-east-1 --nodes 2
./devctl cluster status test-cluster
./devctl cluster delete test-cluster

# Test deploy commands
./devctl deploy app --name myapp --image nginx:latest --replicas 3
./devctl deploy status myapp
./devctl deploy rollback myapp --revision 2

# Test config commands
./devctl config set cluster.default production
./devctl config set region us-west-2
./devctl config get cluster.default
./devctl config list

# Test different output formats
./devctl cluster list --output json
./devctl cluster list --output yaml
./devctl config list --verbose
```

Expected output:
```
🚀 Creating cluster 'test-cluster' in region 'us-east-1'...
   Node count: 2
   Node type: t3.medium
   ✅ VPC created
   ✅ Security groups configured
   ✅ IAM roles created
   ✅ EKS cluster created
   ✅ 2 worker nodes launched
✨ Cluster 'test-cluster' created successfully!
💡 Use 'devctl cluster status test-cluster' to check cluster details
```

### Generate Completion Scripts

```bash
# Bash completion
./devctl completion bash > devctl-completion.bash
source devctl-completion.bash

# Zsh completion
./devctl completion zsh > _devctl
# Move to your zsh completions directory

# Fish completion
./devctl completion fish > devctl.fish
source devctl.fish
```

## 🧹 Cleanup

```bash
rm -rf devctl/
rm devctl-completion.bash _devctl devctl.fish
```

## 🔍 Troubleshooting

| Issue | Solution |
|-------|----------|
| `command not found` | Ensure the binary is in your PATH or use `./devctl` |
| Config file errors | Check permissions and file format (YAML) |
| Flag parsing errors | Use `--help` to see available flags and formats |
| Build errors | Run `go mod tidy` to resolve dependencies |

## 📚 Additional Resources

- [Cobra Documentation](https://cobra.dev/)
- [Viper Configuration](https://github.com/spf13/viper)
- [Go CLI Best Practices](https://blog.carlmjohnson.net/post/2020/go-cli-how-to-and-advice/)
- [kubectl Source Code](https://github.com/kubernetes/kubernetes/tree/master/cmd/kubectl)

## 🏆 Challenge

Enhance the CLI tool with:
1. **Real Integrations** - Connect to actual AWS/Kubernetes APIs
2. **Plugin System** - Allow third-party commands
3. **Interactive Mode** - Add prompts for missing parameters
4. **Progress Bars** - Show progress for long-running operations
5. **Configuration Validation** - Validate settings before applying
6. **Logging** - Add structured logging with different levels

## 📝 Notes

- Cobra provides automatic help generation and command discovery
- Viper handles configuration from files, environment variables, and flags
- Use consistent naming and flag conventions across all commands
- Always provide meaningful error messages and usage examples

---

### 🔗 Navigation
- [← Previous Tutorial: Go Fundamentals for DevOps](../280-go-fundamentals-for-devops/)
- [→ Next Tutorial: HTTP APIs and Microservices with Gin](../282-http-apis-microservices-gin/)
- [📚 Programming Languages Index](../README.md)
- [🏠 Main Index](../../README.md)
