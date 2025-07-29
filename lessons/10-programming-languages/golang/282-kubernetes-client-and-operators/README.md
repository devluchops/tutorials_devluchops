# Tutorial 282: Kubernetes Client and Custom Operators in Go

## 🎯 Overview

Learn to build Kubernetes clients and custom operators using Go and the official Kubernetes client libraries. Create controllers that manage custom resources and automate cluster operations.

### What You'll Learn
- ✅ Kubernetes client-go library fundamentals
- ✅ Interacting with Kubernetes APIs programmatically
- ✅ Creating custom resources and controllers
- ✅ Building Kubernetes operators with operator-sdk
- ✅ Implementing reconciliation loops
- ✅ Best practices for production operators

### Prerequisites
- Go installed (1.21+)
- Kubernetes cluster (local or remote)
- kubectl configured
- Basic Kubernetes knowledge
- Completed previous Go tutorials (280, 281)

### Time to Complete
⏱️ Approximately 90 minutes

## 🏗️ Architecture

We'll build a **Database Operator** that manages PostgreSQL instances:

```
Database Operator
├── Custom Resource Definition (CRD)
│   └── PostgreSQLCluster
├── Controller
│   ├── Reconciliation Logic
│   ├── Event Handling
│   └── Status Updates
├── Kubernetes Resources
│   ├── Deployment
│   ├── Service
│   ├── ConfigMap
│   └── PersistentVolumeClaim
└── Monitoring & Metrics
    ├── Health Checks
    └── Prometheus Metrics
```

## 🛠️ Setup

### Step 1: Initialize Project
```bash
mkdir k8s-postgres-operator
cd k8s-postgres-operator
go mod init k8s-postgres-operator
```

### Step 2: Install Dependencies
```bash
# Kubernetes client libraries
go get k8s.io/client-go@v0.28.0
go get k8s.io/apimachinery@v0.28.0
go get k8s.io/api@v0.28.0

# Controller runtime
go get sigs.k8s.io/controller-runtime@v0.16.0

# Logging
go get github.com/go-logr/logr@v1.2.4
go get sigs.k8s.io/controller-runtime/pkg/log/zap@v0.16.0
```

### Step 3: Verify Kubernetes Access
```bash
kubectl cluster-info
kubectl get nodes
```

## 📋 Implementation

### Phase 1: Custom Resource Definition

**api/v1/postgresql_types.go:**
```go
package v1

import (
    metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// PostgreSQLClusterSpec defines the desired state of PostgreSQLCluster
type PostgreSQLClusterSpec struct {
    // Size is the number of PostgreSQL replicas
    Size int32 `json:"size"`
    
    // Version specifies the PostgreSQL version
    Version string `json:"version"`
    
    // DatabaseName is the initial database to create
    DatabaseName string `json:"databaseName"`
    
    // Storage configuration
    Storage StorageSpec `json:"storage"`
    
    // Resources configuration
    Resources ResourceRequirements `json:"resources,omitempty"`
    
    // Backup configuration
    Backup *BackupSpec `json:"backup,omitempty"`
}

type StorageSpec struct {
    // Size of the storage
    Size string `json:"size"`
    
    // StorageClass for PVCs
    StorageClass *string `json:"storageClass,omitempty"`
}

type ResourceRequirements struct {
    // CPU limit
    CPU string `json:"cpu,omitempty"`
    
    // Memory limit  
    Memory string `json:"memory,omitempty"`
}

type BackupSpec struct {
    // Enabled indicates if backup is enabled
    Enabled bool `json:"enabled"`
    
    // Schedule is the cron schedule for backups
    Schedule string `json:"schedule,omitempty"`
    
    // Retention policy
    RetentionDays int32 `json:"retentionDays,omitempty"`
}

// PostgreSQLClusterStatus defines the observed state of PostgreSQLCluster
type PostgreSQLClusterStatus struct {
    // Phase represents the current phase of the cluster
    Phase string `json:"phase,omitempty"`
    
    // ReadyReplicas is the number of ready replicas
    ReadyReplicas int32 `json:"readyReplicas"`
    
    // Conditions represent the latest available observations
    Conditions []metav1.Condition `json:"conditions,omitempty"`
    
    // DatabaseHost is the connection endpoint
    DatabaseHost string `json:"databaseHost,omitempty"`
    
    // LastBackup timestamp
    LastBackup *metav1.Time `json:"lastBackup,omitempty"`
}

//+kubebuilder:object:root=true
//+kubebuilder:subresource:status
//+kubebuilder:subresource:scale:specpath=.spec.size,statuspath=.status.readyReplicas
//+kubebuilder:printcolumn:name="Phase",type="string",JSONPath=".status.phase"
//+kubebuilder:printcolumn:name="Ready",type="integer",JSONPath=".status.readyReplicas"
//+kubebuilder:printcolumn:name="Size",type="integer",JSONPath=".spec.size"
//+kubebuilder:printcolumn:name="Version",type="string",JSONPath=".spec.version"
//+kubebuilder:printcolumn:name="Age",type="date",JSONPath=".metadata.creationTimestamp"

// PostgreSQLCluster is the Schema for the postgresqlclusters API
type PostgreSQLCluster struct {
    metav1.TypeMeta   `json:",inline"`
    metav1.ObjectMeta `json:"metadata,omitempty"`

    Spec   PostgreSQLClusterSpec   `json:"spec,omitempty"`
    Status PostgreSQLClusterStatus `json:"status,omitempty"`
}

//+kubebuilder:object:root=true

// PostgreSQLClusterList contains a list of PostgreSQLCluster
type PostgreSQLClusterList struct {
    metav1.TypeMeta `json:",inline"`
    metav1.ListMeta `json:"metadata,omitempty"`
    Items           []PostgreSQLCluster `json:"items"`
}

func init() {
    SchemeBuilder.Register(&PostgreSQLCluster{}, &PostgreSQLClusterList{})
}
```

### Phase 2: Controller Implementation

**controllers/postgresql_controller.go:**
```go
package controllers

import (
    "context"
    "fmt"
    "time"

    appsv1 "k8s.io/api/apps/v1"
    corev1 "k8s.io/api/core/v1"
    "k8s.io/apimachinery/pkg/api/errors"
    "k8s.io/apimachinery/pkg/api/resource"
    metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
    "k8s.io/apimachinery/pkg/runtime"
    "k8s.io/apimachinery/pkg/util/intstr"
    ctrl "sigs.k8s.io/controller-runtime"
    "sigs.k8s.io/controller-runtime/pkg/client"
    "sigs.k8s.io/controller-runtime/pkg/controller/controllerutil"
    "sigs.k8s.io/controller-runtime/pkg/log"

    databasev1 "k8s-postgres-operator/api/v1"
)

// PostgreSQLClusterReconciler reconciles a PostgreSQLCluster object
type PostgreSQLClusterReconciler struct {
    client.Client
    Scheme *runtime.Scheme
}

//+kubebuilder:rbac:groups=database.example.com,resources=postgresqlclusters,verbs=get;list;watch;create;update;patch;delete
//+kubebuilder:rbac:groups=database.example.com,resources=postgresqlclusters/status,verbs=get;update;patch
//+kubebuilder:rbac:groups=database.example.com,resources=postgresqlclusters/finalizers,verbs=update
//+kubebuilder:rbac:groups=apps,resources=deployments,verbs=get;list;watch;create;update;patch;delete
//+kubebuilder:rbac:groups="",resources=services,verbs=get;list;watch;create;update;patch;delete
//+kubebuilder:rbac:groups="",resources=configmaps,verbs=get;list;watch;create;update;patch;delete
//+kubebuilder:rbac:groups="",resources=persistentvolumeclaims,verbs=get;list;watch;create;update;patch;delete

func (r *PostgreSQLClusterReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
    logger := log.FromContext(ctx)

    // Fetch the PostgreSQLCluster instance
    var postgresql databasev1.PostgreSQLCluster
    if err := r.Get(ctx, req.NamespacedName, &postgresql); err != nil {
        if errors.IsNotFound(err) {
            logger.Info("PostgreSQLCluster resource not found. Ignoring since object must be deleted")
            return ctrl.Result{}, nil
        }
        logger.Error(err, "Failed to get PostgreSQLCluster")
        return ctrl.Result{}, err
    }

    logger.Info("Reconciling PostgreSQLCluster", "name", postgresql.Name, "namespace", postgresql.Namespace)

    // Handle deletion
    if postgresql.DeletionTimestamp != nil {
        return r.handleDeletion(ctx, &postgresql)
    }

    // Add finalizer if not present
    if !controllerutil.ContainsFinalizer(&postgresql, "postgresql.database.example.com/finalizer") {
        controllerutil.AddFinalizer(&postgresql, "postgresql.database.example.com/finalizer")
        return ctrl.Result{}, r.Update(ctx, &postgresql)
    }

    // Update status phase
    if postgresql.Status.Phase == "" {
        postgresql.Status.Phase = "Pending"
        if err := r.Status().Update(ctx, &postgresql); err != nil {
            return ctrl.Result{}, err
        }
    }

    // Reconcile resources
    if err := r.reconcileConfigMap(ctx, &postgresql); err != nil {
        return ctrl.Result{}, err
    }

    if err := r.reconcilePVC(ctx, &postgresql); err != nil {
        return ctrl.Result{}, err
    }

    if err := r.reconcileDeployment(ctx, &postgresql); err != nil {
        return ctrl.Result{}, err
    }

    if err := r.reconcileService(ctx, &postgresql); err != nil {
        return ctrl.Result{}, err
    }

    // Update status
    if err := r.updateStatus(ctx, &postgresql); err != nil {
        return ctrl.Result{}, err
    }

    logger.Info("Successfully reconciled PostgreSQLCluster")
    return ctrl.Result{RequeueAfter: time.Minute * 5}, nil
}

func (r *PostgreSQLClusterReconciler) reconcileConfigMap(ctx context.Context, postgresql *databasev1.PostgreSQLCluster) error {
    configMap := &corev1.ConfigMap{
        ObjectMeta: metav1.ObjectMeta{
            Name:      postgresql.Name + "-config",
            Namespace: postgresql.Namespace,
        },
        Data: map[string]string{
            "postgresql.conf": `
# PostgreSQL configuration
max_connections = 100
shared_buffers = 128MB
effective_cache_size = 4GB
maintenance_work_mem = 64MB
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 100
random_page_cost = 1.1
effective_io_concurrency = 200
work_mem = 4MB
min_wal_size = 1GB
max_wal_size = 4GB
`,
            "init.sql": fmt.Sprintf(`
CREATE DATABASE %s;
CREATE USER postgres_user WITH PASSWORD 'secure_password';
GRANT ALL PRIVILEGES ON DATABASE %s TO postgres_user;
`, postgresql.Spec.DatabaseName, postgresql.Spec.DatabaseName),
        },
    }

    if err := controllerutil.SetControllerReference(postgresql, configMap, r.Scheme); err != nil {
        return err
    }

    found := &corev1.ConfigMap{}
    err := r.Get(ctx, client.ObjectKeyFromObject(configMap), found)
    if err != nil && errors.IsNotFound(err) {
        return r.Create(ctx, configMap)
    } else if err != nil {
        return err
    }

    // Update if needed
    if found.Data["postgresql.conf"] != configMap.Data["postgresql.conf"] {
        found.Data = configMap.Data
        return r.Update(ctx, found)
    }

    return nil
}

func (r *PostgreSQLClusterReconciler) reconcilePVC(ctx context.Context, postgresql *databasev1.PostgreSQLCluster) error {
    pvc := &corev1.PersistentVolumeClaim{
        ObjectMeta: metav1.ObjectMeta{
            Name:      postgresql.Name + "-data",
            Namespace: postgresql.Namespace,
        },
        Spec: corev1.PersistentVolumeClaimSpec{
            AccessModes: []corev1.PersistentVolumeAccessMode{
                corev1.ReadWriteOnce,
            },
            Resources: corev1.ResourceRequirements{
                Requests: corev1.ResourceList{
                    corev1.ResourceStorage: resource.MustParse(postgresql.Spec.Storage.Size),
                },
            },
        },
    }

    if postgresql.Spec.Storage.StorageClass != nil {
        pvc.Spec.StorageClassName = postgresql.Spec.Storage.StorageClass
    }

    if err := controllerutil.SetControllerReference(postgresql, pvc, r.Scheme); err != nil {
        return err
    }

    found := &corev1.PersistentVolumeClaim{}
    err := r.Get(ctx, client.ObjectKeyFromObject(pvc), found)
    if err != nil && errors.IsNotFound(err) {
        return r.Create(ctx, pvc)
    }
    return err
}

func (r *PostgreSQLClusterReconciler) reconcileDeployment(ctx context.Context, postgresql *databasev1.PostgreSQLCluster) error {
    labels := map[string]string{
        "app":     "postgresql",
        "cluster": postgresql.Name,
    }

    deployment := &appsv1.Deployment{
        ObjectMeta: metav1.ObjectMeta{
            Name:      postgresql.Name,
            Namespace: postgresql.Namespace,
            Labels:    labels,
        },
        Spec: appsv1.DeploymentSpec{
            Replicas: &postgresql.Spec.Size,
            Selector: &metav1.LabelSelector{
                MatchLabels: labels,
            },
            Template: corev1.PodTemplateSpec{
                ObjectMeta: metav1.ObjectMeta{
                    Labels: labels,
                },
                Spec: corev1.PodSpec{
                    Containers: []corev1.Container{
                        {
                            Name:  "postgresql",
                            Image: fmt.Sprintf("postgres:%s", postgresql.Spec.Version),
                            Env: []corev1.EnvVar{
                                {
                                    Name:  "POSTGRES_DB",
                                    Value: postgresql.Spec.DatabaseName,
                                },
                                {
                                    Name:  "POSTGRES_USER",
                                    Value: "postgres",
                                },
                                {
                                    Name:  "POSTGRES_PASSWORD",
                                    Value: "secure_password", // In production, use secrets
                                },
                                {
                                    Name:  "PGDATA",
                                    Value: "/var/lib/postgresql/data/pgdata",
                                },
                            },
                            Ports: []corev1.ContainerPort{
                                {
                                    ContainerPort: 5432,
                                    Name:          "postgresql",
                                },
                            },
                            VolumeMounts: []corev1.VolumeMount{
                                {
                                    Name:      "data",
                                    MountPath: "/var/lib/postgresql/data",
                                },
                                {
                                    Name:      "config",
                                    MountPath: "/etc/postgresql",
                                },
                            },
                            LivenessProbe: &corev1.Probe{
                                ProbeHandler: corev1.ProbeHandler{
                                    Exec: &corev1.ExecAction{
                                        Command: []string{
                                            "pg_isready",
                                            "-U", "postgres",
                                            "-d", postgresql.Spec.DatabaseName,
                                        },
                                    },
                                },
                                InitialDelaySeconds: 30,
                                PeriodSeconds:       10,
                            },
                            ReadinessProbe: &corev1.Probe{
                                ProbeHandler: corev1.ProbeHandler{
                                    Exec: &corev1.ExecAction{
                                        Command: []string{
                                            "pg_isready",
                                            "-U", "postgres",
                                            "-d", postgresql.Spec.DatabaseName,
                                        },
                                    },
                                },
                                InitialDelaySeconds: 5,
                                PeriodSeconds:       5,
                            },
                        },
                    },
                    Volumes: []corev1.Volume{
                        {
                            Name: "data",
                            VolumeSource: corev1.VolumeSource{
                                PersistentVolumeClaim: &corev1.PersistentVolumeClaimVolumeSource{
                                    ClaimName: postgresql.Name + "-data",
                                },
                            },
                        },
                        {
                            Name: "config",
                            VolumeSource: corev1.VolumeSource{
                                ConfigMap: &corev1.ConfigMapVolumeSource{
                                    LocalObjectReference: corev1.LocalObjectReference{
                                        Name: postgresql.Name + "-config",
                                    },
                                },
                            },
                        },
                    },
                },
            },
        },
    }

    // Set resource limits if specified
    if postgresql.Spec.Resources.CPU != "" || postgresql.Spec.Resources.Memory != "" {
        resources := corev1.ResourceRequirements{
            Limits: corev1.ResourceList{},
        }
        if postgresql.Spec.Resources.CPU != "" {
            resources.Limits[corev1.ResourceCPU] = resource.MustParse(postgresql.Spec.Resources.CPU)
        }
        if postgresql.Spec.Resources.Memory != "" {
            resources.Limits[corev1.ResourceMemory] = resource.MustParse(postgresql.Spec.Resources.Memory)
        }
        deployment.Spec.Template.Spec.Containers[0].Resources = resources
    }

    if err := controllerutil.SetControllerReference(postgresql, deployment, r.Scheme); err != nil {
        return err
    }

    found := &appsv1.Deployment{}
    err := r.Get(ctx, client.ObjectKeyFromObject(deployment), found)
    if err != nil && errors.IsNotFound(err) {
        return r.Create(ctx, deployment)
    } else if err != nil {
        return err
    }

    // Update if replicas changed
    if *found.Spec.Replicas != postgresql.Spec.Size {
        found.Spec.Replicas = &postgresql.Spec.Size
        return r.Update(ctx, found)
    }

    return nil
}

func (r *PostgreSQLClusterReconciler) reconcileService(ctx context.Context, postgresql *databasev1.PostgreSQLCluster) error {
    service := &corev1.Service{
        ObjectMeta: metav1.ObjectMeta{
            Name:      postgresql.Name + "-service",
            Namespace: postgresql.Namespace,
        },
        Spec: corev1.ServiceSpec{
            Selector: map[string]string{
                "app":     "postgresql",
                "cluster": postgresql.Name,
            },
            Ports: []corev1.ServicePort{
                {
                    Port:       5432,
                    TargetPort: intstr.FromInt(5432),
                    Name:       "postgresql",
                },
            },
            Type: corev1.ServiceTypeClusterIP,
        },
    }

    if err := controllerutil.SetControllerReference(postgresql, service, r.Scheme); err != nil {
        return err
    }

    found := &corev1.Service{}
    err := r.Get(ctx, client.ObjectKeyFromObject(service), found)
    if err != nil && errors.IsNotFound(err) {
        return r.Create(ctx, service)
    }
    return err
}

func (r *PostgreSQLClusterReconciler) updateStatus(ctx context.Context, postgresql *databasev1.PostgreSQLCluster) error {
    // Get the deployment to check status
    deployment := &appsv1.Deployment{}
    err := r.Get(ctx, client.ObjectKey{
        Namespace: postgresql.Namespace,
        Name:      postgresql.Name,
    }, deployment)
    if err != nil {
        return err
    }

    postgresql.Status.ReadyReplicas = deployment.Status.ReadyReplicas

    // Update phase based on deployment status
    if deployment.Status.ReadyReplicas == postgresql.Spec.Size {
        postgresql.Status.Phase = "Running"
        postgresql.Status.DatabaseHost = postgresql.Name + "-service." + postgresql.Namespace + ".svc.cluster.local"
    } else if deployment.Status.ReadyReplicas > 0 {
        postgresql.Status.Phase = "Partial"
    } else {
        postgresql.Status.Phase = "Pending"
    }

    // Update conditions
    readyCondition := metav1.Condition{
        Type:   "Ready",
        Status: metav1.ConditionFalse,
        Reason: "DeploymentNotReady",
        Message: fmt.Sprintf("%d/%d replicas ready", 
            deployment.Status.ReadyReplicas, postgresql.Spec.Size),
    }

    if deployment.Status.ReadyReplicas == postgresql.Spec.Size {
        readyCondition.Status = metav1.ConditionTrue
        readyCondition.Reason = "AllReplicasReady"
        readyCondition.Message = "All replicas are ready"
    }

    // Update or add condition
    updated := false
    for i, condition := range postgresql.Status.Conditions {
        if condition.Type == "Ready" {
            postgresql.Status.Conditions[i] = readyCondition
            updated = true
            break
        }
    }
    if !updated {
        postgresql.Status.Conditions = append(postgresql.Status.Conditions, readyCondition)
    }

    return r.Status().Update(ctx, postgresql)
}

func (r *PostgreSQLClusterReconciler) handleDeletion(ctx context.Context, postgresql *databasev1.PostgreSQLCluster) (ctrl.Result, error) {
    logger := log.FromContext(ctx)
    logger.Info("Handling deletion", "name", postgresql.Name)

    // Perform cleanup operations here
    // For example, backup data, cleanup external resources, etc.

    // Remove finalizer
    controllerutil.RemoveFinalizer(postgresql, "postgresql.database.example.com/finalizer")
    return ctrl.Result{}, r.Update(ctx, postgresql)
}

// SetupWithManager sets up the controller with the Manager.
func (r *PostgreSQLClusterReconciler) SetupWithManager(mgr ctrl.Manager) error {
    return ctrl.NewControllerManagedBy(mgr).
        For(&databasev1.PostgreSQLCluster{}).
        Owns(&appsv1.Deployment{}).
        Owns(&corev1.Service{}).
        Owns(&corev1.ConfigMap{}).
        Owns(&corev1.PersistentVolumeClaim{}).
        Complete(r)
}
```

### Phase 3: Main Application

**main.go:**
```go
package main

import (
    "flag"
    "os"

    "k8s.io/apimachinery/pkg/runtime"
    utilruntime "k8s.io/apimachinery/pkg/util/runtime"
    clientgoscheme "k8s.io/client-go/kubernetes/scheme"
    ctrl "sigs.k8s.io/controller-runtime"
    "sigs.k8s.io/controller-runtime/pkg/healthz"
    "sigs.k8s.io/controller-runtime/pkg/log/zap"

    databasev1 "k8s-postgres-operator/api/v1"
    "k8s-postgres-operator/controllers"
)

var (
    scheme   = runtime.NewScheme()
    setupLog = ctrl.Log.WithName("setup")
)

func init() {
    utilruntime.Must(clientgoscheme.AddToScheme(scheme))
    utilruntime.Must(databasev1.AddToScheme(scheme))
}

func main() {
    var metricsAddr string
    var enableLeaderElection bool
    var probeAddr string
    
    flag.StringVar(&metricsAddr, "metrics-bind-address", ":8080", 
        "The address the metric endpoint binds to.")
    flag.StringVar(&probeAddr, "health-probe-bind-address", ":8081", 
        "The address the probe endpoint binds to.")
    flag.BoolVar(&enableLeaderElection, "leader-elect", false,
        "Enable leader election for controller manager.")
    
    opts := zap.Options{
        Development: true,
    }
    opts.BindFlags(flag.CommandLine)
    flag.Parse()

    ctrl.SetLogger(zap.New(zap.UseFlagOptions(&opts)))

    mgr, err := ctrl.NewManager(ctrl.GetConfigOrDie(), ctrl.Options{
        Scheme:                 scheme,
        MetricsBindAddress:     metricsAddr,
        Port:                   9443,
        HealthProbeBindAddress: probeAddr,
        LeaderElection:         enableLeaderElection,
        LeaderElectionID:       "postgresql-operator.database.example.com",
    })
    if err != nil {
        setupLog.Error(err, "unable to start manager")
        os.Exit(1)
    }

    if err = (&controllers.PostgreSQLClusterReconciler{
        Client: mgr.GetClient(),
        Scheme: mgr.GetScheme(),
    }).SetupWithManager(mgr); err != nil {
        setupLog.Error(err, "unable to create controller", "controller", "PostgreSQLCluster")
        os.Exit(1)
    }

    if err := mgr.AddHealthzCheck("healthz", healthz.Ping); err != nil {
        setupLog.Error(err, "unable to set up health check")
        os.Exit(1)
    }
    if err := mgr.AddReadyzCheck("readyz", healthz.Ping); err != nil {
        setupLog.Error(err, "unable to set up ready check")
        os.Exit(1)
    }

    setupLog.Info("starting manager")
    if err := mgr.Start(ctrl.SetupSignalHandler()); err != nil {
        setupLog.Error(err, "problem running manager")
        os.Exit(1)
    }
}
```

### Phase 4: Custom Resource Examples

**examples/postgresql-cluster.yaml:**
```yaml
apiVersion: database.example.com/v1
kind: PostgreSQLCluster
metadata:
  name: my-postgres
  namespace: default
spec:
  size: 3
  version: "15"
  databaseName: "myapp"
  storage:
    size: "10Gi"
    storageClass: "fast-ssd"
  resources:
    cpu: "500m"
    memory: "1Gi"
  backup:
    enabled: true
    schedule: "0 2 * * *"
    retentionDays: 7
```

**examples/high-availability-cluster.yaml:**
```yaml
apiVersion: database.example.com/v1
kind: PostgreSQLCluster
metadata:
  name: production-postgres
  namespace: production
spec:
  size: 5
  version: "15"
  databaseName: "production_app"
  storage:
    size: "100Gi"
    storageClass: "premium-ssd"
  resources:
    cpu: "2"
    memory: "4Gi"
  backup:
    enabled: true
    schedule: "0 */6 * * *"  # Every 6 hours
    retentionDays: 30
```

## ✅ Verification

### Deploy the Operator

```bash
# Install CRDs
kubectl apply -f config/crd/

# Build and run operator
go build -o manager main.go
./manager

# Or run in development mode
go run main.go
```

### Test Custom Resources

```bash
# Create a PostgreSQL cluster
kubectl apply -f examples/postgresql-cluster.yaml

# Check the cluster status
kubectl get postgresqlclusters
kubectl describe postgresqlcluster my-postgres

# Check created resources
kubectl get deployments,services,configmaps,pvc

# Check logs
kubectl logs deployment/my-postgres

# Scale the cluster
kubectl patch postgresqlcluster my-postgres -p '{"spec":{"size":5}}' --type=merge

# Delete the cluster
kubectl delete postgresqlcluster my-postgres
```

Expected output:
```
NAME          PHASE     READY   SIZE   VERSION   AGE
my-postgres   Running   3       3      15        5m23s

# Detailed status
Status:
  Conditions:
    Message:               All replicas are ready
    Reason:                AllReplicasReady
    Status:                True
    Type:                  Ready
  Database Host:           my-postgres-service.default.svc.cluster.local
  Phase:                   Running
  Ready Replicas:          3
```

### Connect to Database

```bash
# Port forward to connect
kubectl port-forward service/my-postgres-service 5432:5432

# Connect with psql
psql -h localhost -p 5432 -U postgres -d myapp
```

## 🧹 Cleanup

```bash
kubectl delete postgresqlcluster --all
kubectl delete -f config/crd/
```

## 🔍 Troubleshooting

| Issue | Solution |
|-------|----------|
| CRD not found | Apply CRDs first: `kubectl apply -f config/crd/` |
| RBAC errors | Check operator has correct permissions |
| Controller not starting | Check Kubernetes config and connectivity |
| Resources not created | Check controller logs for errors |

## 📚 Additional Resources

- [Kubebuilder Documentation](https://kubebuilder.io/)
- [Controller Runtime](https://github.com/kubernetes-sigs/controller-runtime)
- [Kubernetes API Reference](https://kubernetes.io/docs/reference/)
- [Operator Pattern](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/)

## 🏆 Challenge

Enhance the operator with:
1. **High Availability** - Add streaming replication support
2. **Backup Automation** - Implement scheduled backups to S3
3. **Monitoring** - Add Prometheus metrics
4. **Upgrades** - Handle PostgreSQL version upgrades
5. **Security** - Implement proper secret management
6. **Webhooks** - Add validation and mutation webhooks

## 📝 Notes

- Always use finalizers for cleanup operations
- Implement proper status reporting
- Handle edge cases and error conditions
- Use controller-runtime for better abstractions
- Follow Kubernetes API conventions

---

### 🔗 Navigation
- [← Previous Tutorial: Building CLI Tools with Cobra](../281-building-cli-tools-with-cobra/)
- [→ Next Tutorial: Monitoring and Metrics with Prometheus](../283-monitoring-metrics-prometheus/)
- [📚 Programming Languages Index](../README.md)
- [🏠 Main Index](../../README.md)
