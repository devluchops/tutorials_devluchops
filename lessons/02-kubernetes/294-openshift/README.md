OpenShift is a Kubernetes-based container platform that extends Kubernetes with additional features and functionalities. Many of the administrative commands used in OpenShift are similar to those in Kubernetes, but there are also specific OpenShift commands. Here are some commonly used administrative commands in OpenShift:

## Cluster Management

- `oc cluster-info` - Display information about the OpenShift cluster.
- `oc get nodes` - List all nodes in the cluster.
- `oc describe node node_name` - Display detailed information about a specific node.
- `oc get projects` - List all projects (namespaces) in the cluster.
- `oc describe project project_name` - Display detailed information about a specific project.
- `oc get clusteroperators` - List all cluster operators and their status.
- `oc get clusterversion` - Display the OpenShift cluster version information.
- `oc get pods --all-namespaces` - List all pods in all namespaces in the cluster.
- `oc adm top nodes` - Display resource usage statistics for nodes in the cluster.
- `oc adm top pods` - Display resource usage statistics for pods in the cluster.

## User and Role Management

- `oc adm policy add-role-to-user role_name username` - Add a role to a user.
- `oc adm policy remove-role-from-user role_name username` - Remove a role from a user.
- `oc adm policy add-cluster-role-to-user role_name username` - Add a cluster role to a user.
- `oc adm policy remove-cluster-role-from-user role_name username` - Remove a cluster role from a user.
- `oc adm policy add-role-to-group role_name group_name` - Add a role to a group.
- `oc adm policy remove-role-from-group role_name group_name` - Remove a role from a group.
- `oc adm policy add-scc-to-user scc_name username` - Add a security context constraint (SCC) to a user.
- `oc adm policy remove-scc-from-user scc_name username` - Remove a security context constraint (SCC) from a user.

## Builds and Deployments

- `oc new-app` - Create a new application from source code or a Docker image.
- `oc start-build` - Start a new build of an application.
- `oc rollout latest deployment/deployment_name` - Deploy the latest version of a deployment.
- `oc rollout pause deployment/deployment_name` - Pause the deployment of a deployment.
- `oc rollout resume deployment/deployment_name` - Resume the deployment of a deployment.
- `oc rollout status deployment/deployment_name` - Check the status of a deployment rollout.
- `oc rollout history deployment/deployment_name` - View the revision history of a deployment.

## Logging and Monitoring

- `oc logs pod_name` - View the logs of a specific pod.
- `oc logs pod_name -c container_name` - View the logs of a specific container within a pod.
- `oc adm top pod` - Display resource usage statistics for pods in the cluster.
- `oc adm top node` - Display resource usage statistics for nodes in the cluster.
- `oc adm top project` - Display resource usage statistics for projects in the cluster.
- `oc adm diagnostics` - Run diagnostics on the cluster.

## Storage Management

- `oc get pv` - List all persistent volumes in the cluster.
- `oc describe pv pv_name` - Display detailed information about a specific persistent volume.
- `oc get pvc` - List all persistent volume claims in the cluster.
- `oc describe pvc pvc_name` - Display detailed information about a specific persistent volume claim.
- `oc adm top pv` - Display resource usage statistics for persistent volumes in the cluster.

Certainly! Here are some more administrative commands in OpenShift:

## Networking

- `oc get routes` - List all routes in the cluster.
- `oc describe route route_name` - Display detailed information about a specific route.
- `oc get ingress` - List all ingresses in the cluster.
- `oc describe ingress ingress_name` - Display detailed information about a specific ingress.
- `oc get services` - List all services in the cluster.
- `oc describe service service_name` - Display detailed information about a specific service.
- `oc get endpoints` - List all endpoints in the cluster.
- `oc describe endpoint endpoint_name` - Display detailed information about a specific endpoint.
- `oc adm pod-network` - View or update the Pod network configuration.

## Secrets and ConfigMaps

- `oc get secrets` - List all secrets in the cluster.
- `oc describe secret secret_name` - Display detailed information about a specific secret.
- `oc create secret` - Create a new secret.
- `oc get configmaps` - List all config maps in the cluster.
- `oc describe configmap configmap_name` - Display detailed information about a specific config map.
- `oc create configmap` - Create a new config map.

## Cluster Monitoring and Logging

- `oc get clusteroperators` - List all cluster operators and their status.
- `oc describe clusteroperator clusteroperator_name` - Display detailed information about a specific cluster operator.
- `oc adm top nodes` - Display resource usage statistics for nodes in the cluster.
- `oc adm top pods` - Display resource usage statistics for pods in the cluster.
- `oc adm top projects` - Display resource usage statistics for projects in the cluster.
- `oc adm top pv` - Display resource usage statistics for persistent volumes in the cluster.
- `oc logs -n openshift-logging` - View the logs of the OpenShift logging components.

## Monitoring and Debugging Tools

- `oc adm must-gather` - Collect diagnostic information about the cluster for troubleshooting.
- `oc debug node/node_name` - Start a debugging session on a specific node.
- `oc debug pod/pod_name` - Start a debugging session on a specific pod.
- `oc adm policy add-cluster-role-to-user cluster-admin username` - Add the cluster-admin role to a user for administrative access.

## Scaling and Autoscaling

- `oc scale --replicas=5 deployment/deployment_name` - Scale a deployment to a specific number of replicas.
- `oc autoscale deployment/deployment_name --min=2 --max=10 --cpu-percent=80` - Configure autoscaling for a deployment based on CPU usage.
- `oc get hpa` - List all HorizontalPodAutoscalers (HPAs) in the cluster.
- `oc describe hpa hpa_name` - Display detailed information about a specific HPA.

## Image Management

- `oc import-image image_name --from=source_image --confirm` - Import an external image into the cluster.
- `oc export imagestream/imagestream_name --as-file=filename` - Export an image stream as a YAML file.

## Security and Certificates

- `oc adm certificate approve certificate_name` - Approve a certificate signing request (CSR).
- `oc adm ca create-server-cert --signer-cert=ca_cert --signer-key=ca_key --signer-serial=ca_serial --hostnames=hostname --cert=server_cert --key=server_key` - Create a server certificate signed by the cluster's CA.
- `oc adm ca create-client-cert --signer-cert=ca_cert --signer-key=ca_key --signer-serial=ca_serial --username=username --cert=client_cert --key=client_key` - Create a client certificate signed by the cluster's CA.
- `oc adm rotate certificate ca_name` - Rotate a certificate authority (CA).

## Cluster Upgrades

- `oc adm upgrade` - Perform an OpenShift cluster upgrade.
- `oc adm upgrade status` - Check the status of an ongoing cluster upgrade.
- `oc adm upgrade plan` - View the upgrade plan for the cluster.

## Project/Namespace Management

- `oc new-project project_name` - Create a new project (namespace) in the cluster.
- `oc delete project project_name` - Delete a project and all its resources.
- `oc adm pod-network join-projects project_name1,project_name2` - Join multiple projects into a single network.

## Rolling Updates and Rollbacks

- `oc rollout latest dc/deployment_config_name` - Deploy the latest version of a deployment config.
- `oc rollout pause dc/deployment_config_name` - Pause the rollout of a deployment config.
- `oc rollout resume dc/deployment_config_name` - Resume the rollout of a deployment config.
- `oc rollout history dc/deployment_config_name` - View the revision history of a deployment config.
- `oc rollout undo dc/deployment_config_name` - Rollback a deployment config to the previous revision.

## Storage Management

- `oc get storageclass` - List all storage classes in the cluster.
- `oc describe storageclass storageclass_name` - Display detailed information about a specific storage class.
- `oc get volume` - List all persistent volumes in the cluster.
- `oc describe volume volume_name` - Display detailed information about a specific persistent volume.
- `oc get volumeclaim` - List all persistent volume claims in the cluster.
- `oc describe volumeclaim volumeclaim_name` - Display detailed information about a specific persistent volume claim.

## Resource Quotas

- `oc create quota quota_name --hard=resource_limits --scopes=scopes` - Create a resource quota for a project.
- `oc get quota` - List all resource quotas in the cluster.
- `oc describe quota quota_name` - Display detailed information about a specific resource quota.

## Monitoring and Metrics

- `oc adm top pods` - Display resource usage statistics for pods in the cluster.
- `oc adm top nodes` - Display resource usage statistics for nodes in the cluster.
- `oc adm top projects` - Display resource usage statistics for projects in the cluster.
- `oc adm top containers` - Display resource usage statistics for containers in the cluster.
- `oc get events` - List all events in the cluster.

## Custom Resource Definitions (CRDs)

- `oc get crd` - List all custom resource definitions in the cluster.
- `oc describe crd crd_name` - Display detailed information about a specific custom resource definition.
- `oc get customresourcedefinition` - List all custom resources in the cluster.
- `oc describe customresourcedefinition cr_name` - Display detailed information about a specific custom resource.
