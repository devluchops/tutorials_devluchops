// kubernetes-cluster.ts
import * as k8s from "@pulumi/kubernetes";
import * as eks from "@pulumi/eks";
import * as aws from "@pulumi/aws";
import * as awsx from "@pulumi/awsx";

// EKS Cluster
const cluster = new eks.Cluster("my-cluster", {
  version: "1.27",
  instanceType: "t3.medium",
  desiredCapacity: 3,
  minSize: 1,
  maxSize: 10,
  enabledClusterLogTypes: ["api", "audit", "authenticator", "controllerManager", "scheduler"],
  nodeAssociatePublicIpAddress: false,
  createOidcProvider: true,
  tags: {
    "Environment": "development",
    "Project": "kubernetes-demo"
  }
});

// Kubernetes Provider
const k8sProvider = new k8s.Provider("k8s-provider", {
  kubeconfig: cluster.kubeconfig,
});

// Deploy applications using real programming
const apps = [
  { 
    name: "frontend", 
    image: "nginx:1.21", 
    replicas: 3, 
    port: 80,
    env: {
      "BACKEND_URL": "http://backend-service:3000"
    }
  },
  { 
    name: "backend", 
    image: "node:16-alpine", 
    replicas: 2, 
    port: 3000,
    env: {
      "DATABASE_URL": "postgres://postgres:password@database-service:5432/myapp",
      "NODE_ENV": "production"
    }
  },
  { 
    name: "database", 
    image: "postgres:13", 
    replicas: 1, 
    port: 5432,
    env: {
      "POSTGRES_DB": "myapp",
      "POSTGRES_USER": "postgres",
      "POSTGRES_PASSWORD": "password"
    }
  }
];

// Create namespace
const appNamespace = new k8s.core.v1.Namespace("app-namespace", {
  metadata: {
    name: "my-application"
  }
}, { provider: k8sProvider });

apps.forEach(app => {
  // ConfigMap for environment variables
  const configMap = new k8s.core.v1.ConfigMap(`${app.name}-config`, {
    metadata: { 
      name: `${app.name}-config`,
      namespace: appNamespace.metadata.name
    },
    data: app.env
  }, { provider: k8sProvider });

  // Secret for sensitive data (if database)
  let secret;
  if (app.name === "database") {
    secret = new k8s.core.v1.Secret(`${app.name}-secret`, {
      metadata: {
        name: `${app.name}-secret`,
        namespace: appNamespace.metadata.name
      },
      type: "Opaque",
      data: {
        "postgres-password": Buffer.from("password").toString("base64")
      }
    }, { provider: k8sProvider });
  }

  // Deployment
  const deployment = new k8s.apps.v1.Deployment(`${app.name}-deployment`, {
    metadata: { 
      name: app.name,
      namespace: appNamespace.metadata.name,
      labels: {
        app: app.name,
        version: "v1"
      }
    },
    spec: {
      replicas: app.replicas,
      selector: { 
        matchLabels: { 
          app: app.name 
        } 
      },
      template: {
        metadata: { 
          labels: { 
            app: app.name,
            version: "v1"
          }
        },
        spec: {
          containers: [{
            name: app.name,
            image: app.image,
            ports: [{ containerPort: app.port }],
            envFrom: [{
              configMapRef: {
                name: configMap.metadata.name
              }
            }],
            ...(app.name === "database" && secret ? {
              env: [{
                name: "POSTGRES_PASSWORD",
                valueFrom: {
                  secretKeyRef: {
                    name: secret.metadata.name,
                    key: "postgres-password"
                  }
                }
              }]
            } : {}),
            resources: {
              requests: { 
                memory: app.name === "database" ? "256Mi" : "64Mi", 
                cpu: app.name === "database" ? "100m" : "50m" 
              },
              limits: { 
                memory: app.name === "database" ? "512Mi" : "128Mi", 
                cpu: app.name === "database" ? "500m" : "100m" 
              }
            },
            ...(app.name === "frontend" ? {
              livenessProbe: {
                httpGet: {
                  path: "/",
                  port: app.port
                },
                initialDelaySeconds: 30,
                periodSeconds: 10
              },
              readinessProbe: {
                httpGet: {
                  path: "/",
                  port: app.port
                },
                initialDelaySeconds: 5,
                periodSeconds: 5
              }
            } : {}),
            ...(app.name === "backend" ? {
              livenessProbe: {
                httpGet: {
                  path: "/health",
                  port: app.port
                },
                initialDelaySeconds: 30,
                periodSeconds: 10
              }
            } : {}),
            ...(app.name === "database" ? {
              volumeMounts: [{
                name: "postgres-storage",
                mountPath: "/var/lib/postgresql/data"
              }]
            } : {})
          }],
          ...(app.name === "database" ? {
            volumes: [{
              name: "postgres-storage",
              persistentVolumeClaim: {
                claimName: `${app.name}-pvc`
              }
            }]
          } : {})
        }
      }
    }
  }, { provider: k8sProvider });

  // PersistentVolumeClaim for database
  if (app.name === "database") {
    const pvc = new k8s.core.v1.PersistentVolumeClaim(`${app.name}-pvc`, {
      metadata: {
        name: `${app.name}-pvc`,
        namespace: appNamespace.metadata.name
      },
      spec: {
        accessModes: ["ReadWriteOnce"],
        resources: {
          requests: {
            storage: "10Gi"
          }
        },
        storageClassName: "gp2"
      }
    }, { provider: k8sProvider });
  }

  // Service
  const service = new k8s.core.v1.Service(`${app.name}-service`, {
    metadata: { 
      name: `${app.name}-service`,
      namespace: appNamespace.metadata.name,
      labels: {
        app: app.name
      }
    },
    spec: {
      selector: { app: app.name },
      ports: [{ 
        port: app.port, 
        targetPort: app.port,
        name: app.name === "frontend" ? "http" : app.name === "backend" ? "api" : "postgres"
      }],
      type: app.name === "frontend" ? "LoadBalancer" : "ClusterIP"
    }
  }, { provider: k8sProvider });

  // HorizontalPodAutoscaler for frontend and backend
  if (app.name !== "database") {
    const hpa = new k8s.autoscaling.v2.HorizontalPodAutoscaler(`${app.name}-hpa`, {
      metadata: {
        name: `${app.name}-hpa`,
        namespace: appNamespace.metadata.name
      },
      spec: {
        scaleTargetRef: {
          apiVersion: "apps/v1",
          kind: "Deployment",
          name: app.name
        },
        minReplicas: 1,
        maxReplicas: app.name === "frontend" ? 10 : 5,
        metrics: [{
          type: "Resource",
          resource: {
            name: "cpu",
            target: {
              type: "Utilization",
              averageUtilization: 70
            }
          }
        }, {
          type: "Resource",
          resource: {
            name: "memory",
            target: {
              type: "Utilization",
              averageUtilization: 80
            }
          }
        }]
      }
    }, { provider: k8sProvider });
  }
});

// Ingress for frontend
const ingress = new k8s.networking.v1.Ingress("app-ingress", {
  metadata: {
    name: "app-ingress",
    namespace: appNamespace.metadata.name,
    annotations: {
      "kubernetes.io/ingress.class": "nginx",
      "nginx.ingress.kubernetes.io/rewrite-target": "/",
      "cert-manager.io/cluster-issuer": "letsencrypt-prod"
    }
  },
  spec: {
    tls: [{
      hosts: ["myapp.example.com"],
      secretName: "app-tls"
    }],
    rules: [{
      host: "myapp.example.com",
      http: {
        paths: [{
          path: "/",
          pathType: "Prefix",
          backend: {
            service: {
              name: "frontend-service",
              port: {
                number: 80
              }
            }
          }
        }, {
          path: "/api",
          pathType: "Prefix",
          backend: {
            service: {
              name: "backend-service",
              port: {
                number: 3000
              }
            }
          }
        }]
      }
    }]
  }
}, { provider: k8sProvider });

// NetworkPolicy for security
const networkPolicy = new k8s.networking.v1.NetworkPolicy("app-network-policy", {
  metadata: {
    name: "app-network-policy",
    namespace: appNamespace.metadata.name
  },
  spec: {
    podSelector: {},
    policyTypes: ["Ingress", "Egress"],
    ingress: [{
      from: [{
        podSelector: {
          matchLabels: {
            app: "frontend"
          }
        }
      }],
      ports: [{
        protocol: "TCP",
        port: 3000
      }]
    }, {
      from: [{
        podSelector: {
          matchLabels: {
            app: "backend"
          }
        }
      }],
      ports: [{
        protocol: "TCP",
        port: 5432
      }]
    }],
    egress: [{
      to: [],
      ports: [{
        protocol: "TCP",
        port: 53
      }, {
        protocol: "UDP",
        port: 53
      }]
    }]
  }
}, { provider: k8sProvider });

// Export cluster information
export const kubeconfig = cluster.kubeconfig;
export const clusterName = cluster.eksCluster.name;
export const clusterEndpoint = cluster.eksCluster.endpoint;
export const clusterVersion = cluster.eksCluster.version;
export const nodeGroupArn = cluster.nodeGroup?.arn;

// Export service endpoints
export const frontendServiceName = "frontend-service";
export const backendServiceName = "backend-service";
export const databaseServiceName = "database-service";
export const appNamespaceName = appNamespace.metadata.name;
