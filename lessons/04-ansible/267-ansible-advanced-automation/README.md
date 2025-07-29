# Ansible Advanced Automation - Enterprise Patterns

Tutorial avanzado de Ansible para automatización empresarial con patrones de infraestructura moderna, roles complejos y CI/CD.

## Why Advanced Ansible?

### **Ansible Básico vs Avanzado**

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Basic Ansible  │───▶│ Advanced Ansible│───▶│  Enterprise     │
│  • Playbooks    │    │ • Collections   │    │  • CI/CD        │
│  • Simple Tasks │    │ • Custom Modules│    │  • GitOps       │
│  • Static Inv.  │    │ • Dynamic Inv.  │    │  • Governance   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### **Modern Infrastructure Challenges**
- **Multi-Cloud** - AWS, GCP, Azure, On-Premise
- **Container Orchestration** - Kubernetes, Docker Swarm
- **Immutable Infrastructure** - GitOps, Infrastructure as Code
- **Security Compliance** - CIS Benchmarks, SOC 2, PCI DSS
- **Zero Downtime Deployments** - Blue/Green, Canary

## Advanced Project Structure

```
ansible-enterprise/
├── ansible.cfg                 # Global configuration
├── requirements.yml           # Collections and roles
├── site.yml                  # Master playbook
├── group_vars/
│   ├── all/
│   │   ├── vault.yml         # Encrypted secrets
│   │   └── main.yml          # Global variables
│   ├── production/
│   └── development/
├── host_vars/
├── inventories/
│   ├── production/
│   │   ├── hosts.yml
│   │   └── group_vars/
│   ├── staging/
│   └── development/
├── roles/
│   ├── common/
│   ├── security/
│   ├── kubernetes/
│   ├── monitoring/
│   └── applications/
├── collections/
│   └── my_company/
│       └── infrastructure/
├── filter_plugins/
├── callback_plugins/
├── library/                  # Custom modules
├── tests/
│   ├── molecule/
│   └── integration/
└── .gitlab-ci.yml           # CI/CD pipeline
```

## Advanced Inventory Management

### **1. Dynamic Inventory with AWS**
```python
#!/usr/bin/env python3
# inventories/aws_ec2.py

import boto3
import json
import argparse
from typing import Dict, List, Any

class AWSInventory:
    def __init__(self):
        self.ec2 = boto3.client('ec2')
        self.inventory = {
            '_meta': {
                'hostvars': {}
            }
        }
        
    def get_inventory(self) -> Dict[str, Any]:
        instances = self.ec2.describe_instances()
        
        for reservation in instances['Reservations']:
            for instance in reservation['Instances']:
                if instance['State']['Name'] != 'running':
                    continue
                    
                # Get instance details
                instance_id = instance['InstanceId']
                private_ip = instance.get('PrivateIpAddress', '')
                public_ip = instance.get('PublicIpAddress', '')
                
                # Parse tags
                tags = {tag['Key']: tag['Value'] for tag in instance.get('Tags', [])}
                
                # Host variables
                self.inventory['_meta']['hostvars'][private_ip] = {
                    'ansible_host': public_ip or private_ip,
                    'instance_id': instance_id,
                    'instance_type': instance['InstanceType'],
                    'vpc_id': instance['VpcId'],
                    'subnet_id': instance['SubnetId'],
                    'tags': tags,
                    'region': instance['Placement']['AvailabilityZone'][:-1]
                }
                
                # Group by environment
                if 'Environment' in tags:
                    env_group = f"env_{tags['Environment']}"
                    self._add_to_group(env_group, private_ip)
                
                # Group by application
                if 'Application' in tags:
                    app_group = f"app_{tags['Application']}"
                    self._add_to_group(app_group, private_ip)
                
                # Group by instance type
                type_group = f"type_{instance['InstanceType'].replace('.', '_')}"
                self._add_to_group(type_group, private_ip)
                
        return self.inventory
    
    def _add_to_group(self, group_name: str, host: str):
        if group_name not in self.inventory:
            self.inventory[group_name] = {
                'hosts': [],
                'vars': {}
            }
        self.inventory[group_name]['hosts'].append(host)

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--list', action='store_true')
    parser.add_argument('--host', action='store')
    args = parser.parse_args()
    
    inventory = AWSInventory()
    
    if args.list:
        print(json.dumps(inventory.get_inventory(), indent=2))
    elif args.host:
        print(json.dumps({}))
```

### **2. Multi-Cloud Inventory Configuration**
```yaml
# inventories/production/aws_ec2.yml
plugin: amazon.aws.aws_ec2
regions:
  - us-east-1
  - us-west-2
  - eu-west-1

filters:
  instance-state-name: running
  tag:Managed: ansible

keyed_groups:
  - key: tags.Environment
    prefix: env
  - key: tags.Application  
    prefix: app
  - key: tags.Role
    prefix: role
  - key: placement.availability_zone
    prefix: az
    
hostnames:
  - tag:Name
  - private-ip-address

compose:
  ansible_host: public_ip_address | default(private_ip_address)
  instance_name: tags.Name | default('unnamed')
  environment: tags.Environment | default('unknown')

# inventories/production/gcp_compute.yml
plugin: google.cloud.gcp_compute
projects:
  - my-project-prod
  - my-project-shared

zones:
  - us-central1-a
  - us-central1-b
  - europe-west1-b

filters:
  - status = RUNNING
  - labels.managed = ansible

keyed_groups:
  - key: labels.environment
    prefix: env
  - key: labels.application
    prefix: app
  - key: zone
    prefix: zone

hostnames:
  - name
  - private_ip
```

## Advanced Role Development

### **1. Complex Multi-Service Role**
```yaml
# roles/kubernetes_cluster/meta/main.yml
galaxy_info:
  author: DevOps Team
  description: Complete Kubernetes cluster setup
  company: My Company
  license: MIT
  min_ansible_version: 2.12
  platforms:
    - name: Ubuntu
      versions: [20.04, 22.04]
    - name: EL
      versions: [8, 9]

dependencies:
  - role: common
  - role: security
  - role: docker
```

```yaml
# roles/kubernetes_cluster/defaults/main.yml
---
# Kubernetes version
kubernetes_version: "1.28.2"
kubeadm_version: "{{ kubernetes_version }}"
kubectl_version: "{{ kubernetes_version }}"
kubelet_version: "{{ kubernetes_version }}"

# Cluster configuration
cluster_name: "kubernetes-cluster"
pod_subnet: "10.244.0.0/16"
service_subnet: "10.96.0.0/12"
kubernetes_port: 6443

# Node configuration
kubelet_extra_args: |
  --node-labels=environment={{ environment }},role={{ kubernetes_role }}
  --register-with-taints={{ kubernetes_node_taints | default('') }}

# CNI Plugin
cni_plugin: calico
calico_version: "3.26.1"

# High Availability
control_plane_ha: false
loadbalancer_address: ""
loadbalancer_port: 6443

# Security
audit_policy_enabled: true
admission_controllers:
  - NodeRestriction
  - PodSecurityPolicy
  - ServiceAccount

# Add-ons
addons:
  dashboard: true
  metrics_server: true
  ingress_nginx: true
  cert_manager: false
  prometheus: false

# Storage
storage_classes:
  - name: fast-ssd
    provisioner: kubernetes.io/aws-ebs
    parameters:
      type: gp3
      fsType: ext4
    default: true
```

```yaml
# roles/kubernetes_cluster/tasks/main.yml
---
- name: Include OS-specific variables
  include_vars: "{{ ansible_os_family }}.yml"

- name: Validate cluster configuration
  include_tasks: validate.yml

- name: Setup system prerequisites  
  include_tasks: prerequisites.yml

- name: Install container runtime
  include_tasks: container_runtime.yml

- name: Install Kubernetes components
  include_tasks: install_kubernetes.yml

- name: Configure control plane nodes
  include_tasks: control_plane.yml
  when: kubernetes_role == 'master'

- name: Configure worker nodes
  include_tasks: worker_nodes.yml
  when: kubernetes_role == 'worker'

- name: Setup CNI networking
  include_tasks: cni.yml
  when: kubernetes_role == 'master'

- name: Deploy cluster add-ons
  include_tasks: addons.yml
  when: kubernetes_role == 'master'

- name: Configure cluster access
  include_tasks: kubeconfig.yml
  when: kubernetes_role == 'master'
```

```yaml
# roles/kubernetes_cluster/tasks/control_plane.yml
---
- name: Check if cluster is already initialized
  stat:
    path: /etc/kubernetes/admin.conf
  register: cluster_initialized

- name: Generate kubeadm config
  template:
    src: kubeadm-config.yaml.j2
    dest: /tmp/kubeadm-config.yaml
    mode: '0600'
  when: not cluster_initialized.stat.exists

- name: Initialize first control plane node
  command: kubeadm init --config=/tmp/kubeadm-config.yaml --upload-certs
  register: kubeadm_init
  when: 
    - not cluster_initialized.stat.exists
    - inventory_hostname == groups['master'][0]

- name: Save cluster join token
  set_fact:
    cluster_token: "{{ kubeadm_init.stdout_lines | select('match', '.*--token.*') | first | regex_replace('.*--token ([^ ]+).*', '\\1') }}"
    cluster_ca_cert_hash: "{{ kubeadm_init.stdout_lines | select('match', '.*--discovery-token-ca-cert-hash.*') | first | regex_replace('.*--discovery-token-ca-cert-hash ([^ ]+).*', '\\1') }}"
    cluster_certificate_key: "{{ kubeadm_init.stdout_lines | select('match', '.*--certificate-key.*') | first | regex_replace('.*--certificate-key ([^ ]+).*', '\\1') }}"
  when: 
    - kubeadm_init is defined
    - kubeadm_init.changed

- name: Join additional control plane nodes
  command: >
    kubeadm join {{ loadbalancer_address | default(hostvars[groups['master'][0]]['ansible_default_ipv4']['address']) }}:{{ kubernetes_port }}
    --token {{ cluster_token }}
    --discovery-token-ca-cert-hash {{ cluster_ca_cert_hash }}
    --control-plane
    --certificate-key {{ cluster_certificate_key }}
  when:
    - not cluster_initialized.stat.exists
    - inventory_hostname != groups['master'][0]
    - control_plane_ha | bool

- name: Create .kube directory
  file:
    path: /home/{{ ansible_user }}/.kube
    state: directory
    owner: "{{ ansible_user }}"
    group: "{{ ansible_user }}"
    mode: '0755'

- name: Copy admin.conf to user's kube config
  copy:
    src: /etc/kubernetes/admin.conf
    dest: /home/{{ ansible_user }}/.kube/config
    remote_src: true
    owner: "{{ ansible_user }}"
    group: "{{ ansible_user }}"
    mode: '0600'

- name: Install bash completion for kubectl
  shell: kubectl completion bash > /etc/bash_completion.d/kubectl
  args:
    creates: /etc/bash_completion.d/kubectl
```

### **2. Custom Ansible Module**
```python
#!/usr/bin/python
# library/kubernetes_manifest.py

from ansible.module_utils.basic import AnsibleModule
import yaml
import json
import subprocess
import tempfile
import os

DOCUMENTATION = '''
---
module: kubernetes_manifest
short_description: Apply Kubernetes manifests with kubectl
description:
    - Apply or delete Kubernetes manifests using kubectl
    - Supports templating and validation
version_added: "2.12"
options:
    definition:
        description:
            - Kubernetes manifest definition as dict or YAML string
        required: true
        type: raw
    state:
        description:
            - Whether the manifest should be applied or deleted
        required: false
        default: present
        choices: ['present', 'absent']
    namespace:
        description:
            - Kubernetes namespace
        required: false
        type: str
    kubeconfig:
        description:
            - Path to kubeconfig file
        required: false
        type: str
    validate:
        description:
            - Validate manifest before applying
        required: false
        default: true
        type: bool
'''

EXAMPLES = '''
- name: Apply deployment manifest
  kubernetes_manifest:
    definition:
      apiVersion: apps/v1
      kind: Deployment
      metadata:
        name: nginx
        namespace: default
      spec:
        replicas: 3
        selector:
          matchLabels:
            app: nginx
        template:
          metadata:
            labels:
              app: nginx
          spec:
            containers:
            - name: nginx
              image: nginx:1.21
              ports:
              - containerPort: 80

- name: Delete service
  kubernetes_manifest:
    definition:
      apiVersion: v1
      kind: Service
      metadata:
        name: nginx-service
        namespace: default
    state: absent
'''

class KubernetesManifest:
    def __init__(self, module):
        self.module = module
        self.kubeconfig = module.params['kubeconfig']
        self.namespace = module.params['namespace']
        
    def _run_kubectl(self, args, input_data=None):
        """Run kubectl command"""
        cmd = ['kubectl']
        
        if self.kubeconfig:
            cmd.extend(['--kubeconfig', self.kubeconfig])
            
        cmd.extend(args)
        
        try:
            result = subprocess.run(
                cmd,
                input=input_data,
                capture_output=True,
                text=True,
                check=True
            )
            return result.stdout, result.stderr
        except subprocess.CalledProcessError as e:
            self.module.fail_json(
                msg=f"kubectl command failed: {e}",
                stdout=e.stdout,
                stderr=e.stderr,
                cmd=' '.join(cmd)
            )
    
    def _manifest_to_yaml(self, definition):
        """Convert manifest definition to YAML"""
        if isinstance(definition, str):
            return definition
        elif isinstance(definition, dict):
            return yaml.dump(definition, default_flow_style=False)
        else:
            self.module.fail_json(msg="Invalid manifest definition type")
    
    def _get_resource_info(self, definition):
        """Extract resource information from manifest"""
        if isinstance(definition, str):
            definition = yaml.safe_load(definition)
            
        kind = definition.get('kind')
        name = definition.get('metadata', {}).get('name')
        namespace = definition.get('metadata', {}).get('namespace', 'default')
        api_version = definition.get('apiVersion')
        
        return kind, name, namespace, api_version
    
    def resource_exists(self, definition):
        """Check if resource exists"""
        kind, name, namespace, api_version = self._get_resource_info(definition)
        
        args = ['get', kind, name]
        if namespace and kind != 'Namespace':
            args.extend(['-n', namespace])
        args.extend(['-o', 'json'])
        
        try:
            stdout, stderr = self._run_kubectl(args)
            return True, json.loads(stdout)
        except:
            return False, None
    
    def apply_manifest(self, definition):
        """Apply Kubernetes manifest"""
        yaml_content = self._manifest_to_yaml(definition)
        
        # Validate manifest
        if self.module.params['validate']:
            args = ['apply', '--dry-run=client', '-f', '-']
            try:
                self._run_kubectl(args, yaml_content)
            except Exception as e:
                self.module.fail_json(msg=f"Manifest validation failed: {e}")
        
        # Check if resource exists
        exists, current_resource = self.resource_exists(definition)
        
        # Apply manifest
        args = ['apply', '-f', '-']
        stdout, stderr = self._run_kubectl(args, yaml_content)
        
        # Determine if change occurred
        changed = not exists or 'unchanged' not in stdout
        
        return changed, stdout, stderr
    
    def delete_manifest(self, definition):
        """Delete Kubernetes manifest"""
        exists, current_resource = self.resource_exists(definition)
        
        if not exists:
            return False, "Resource does not exist", ""
        
        yaml_content = self._manifest_to_yaml(definition)
        args = ['delete', '-f', '-']
        stdout, stderr = self._run_kubectl(args, yaml_content)
        
        return True, stdout, stderr

def main():
    module = AnsibleModule(
        argument_spec=dict(
            definition=dict(type='raw', required=True),
            state=dict(type='str', default='present', choices=['present', 'absent']),
            namespace=dict(type='str'),
            kubeconfig=dict(type='str'),
            validate=dict(type='bool', default=True)
        ),
        supports_check_mode=True
    )
    
    k8s = KubernetesManifest(module)
    
    if module.check_mode:
        module.exit_json(changed=False, msg="Check mode")
    
    definition = module.params['definition']
    state = module.params['state']
    
    try:
        if state == 'present':
            changed, stdout, stderr = k8s.apply_manifest(definition)
            module.exit_json(
                changed=changed,
                stdout=stdout,
                stderr=stderr,
                msg="Manifest applied successfully"
            )
        else:
            changed, stdout, stderr = k8s.delete_manifest(definition)
            module.exit_json(
                changed=changed,
                stdout=stdout,
                stderr=stderr,
                msg="Manifest deleted successfully"
            )
            
    except Exception as e:
        module.fail_json(msg=f"Operation failed: {str(e)}")

if __name__ == '__main__':
    main()
```

## Advanced Playbook Patterns

### **1. Zero Downtime Deployment**
```yaml
# playbooks/zero_downtime_deploy.yml
---
- name: Zero Downtime Application Deployment
  hosts: app_servers
  serial: "{{ deployment_batch_size | default('25%') }}"
  max_fail_percentage: 10
  vars:
    health_check_url: "http://{{ ansible_default_ipv4.address }}:{{ app_port }}/health"
    deployment_timeout: 300
    
  pre_tasks:
    - name: Verify current service status
      uri:
        url: "{{ health_check_url }}"
        method: GET
        status_code: 200
      register: pre_deploy_health
      retries: 3
      delay: 5
      
    - name: Remove node from load balancer
      uri:
        url: "{{ load_balancer_api }}/nodes/{{ inventory_hostname }}"
        method: DELETE
        headers:
          Authorization: "Bearer {{ lb_api_token }}"
      delegate_to: localhost
      
    - name: Wait for connections to drain
      wait_for:
        timeout: 30
      
  tasks:
    - name: Stop application service
      systemd:
        name: "{{ app_service_name }}"
        state: stopped
        
    - name: Backup current application
      archive:
        path: "{{ app_directory }}"
        dest: "/tmp/{{ app_service_name }}-backup-{{ ansible_date_time.epoch }}.tar.gz"
        
    - name: Deploy new application version
      unarchive:
        src: "{{ app_artifact_url }}"
        dest: "{{ app_directory }}"
        remote_src: true
        owner: "{{ app_user }}"
        group: "{{ app_group }}"
        
    - name: Update configuration files
      template:
        src: "{{ item.src }}"
        dest: "{{ item.dest }}"
        owner: "{{ app_user }}"
        group: "{{ app_group }}"
        mode: '0644'
      loop:
        - { src: app.conf.j2, dest: "{{ app_directory }}/config/app.conf" }
        - { src: database.conf.j2, dest: "{{ app_directory }}/config/database.conf" }
      notify:
        - restart application
        
    - name: Start application service
      systemd:
        name: "{{ app_service_name }}"
        state: started
        enabled: true
        
    - name: Wait for application to be ready
      uri:
        url: "{{ health_check_url }}"
        method: GET
        status_code: 200
      register: health_check
      until: health_check.status == 200
      retries: "{{ deployment_timeout // 10 }}"
      delay: 10
      
  post_tasks:
    - name: Add node back to load balancer
      uri:
        url: "{{ load_balancer_api }}/nodes"
        method: POST
        body_format: json
        body:
          hostname: "{{ inventory_hostname }}"
          address: "{{ ansible_default_ipv4.address }}"
          port: "{{ app_port }}"
        headers:
          Authorization: "Bearer {{ lb_api_token }}"
      delegate_to: localhost
      
    - name: Verify node is healthy in load balancer
      uri:
        url: "{{ load_balancer_api }}/nodes/{{ inventory_hostname }}/health"
        method: GET
        status_code: 200
      delegate_to: localhost
      retries: 5
      delay: 10
      
  handlers:
    - name: restart application
      systemd:
        name: "{{ app_service_name }}"
        state: restarted
        
  rescue:
    - name: Rollback on failure
      include_tasks: rollback.yml
      
    - name: Send failure notification
      mail:
        to: "{{ ops_team_email }}"
        subject: "Deployment Failed: {{ app_service_name }} on {{ inventory_hostname }}"
        body: |
          Deployment of {{ app_service_name }} failed on {{ inventory_hostname }}.
          
          Error: {{ ansible_failed_result.msg }}
          
          Rollback has been initiated.
```

### **2. Infrastructure Compliance Scanning**
```yaml
# playbooks/compliance_scan.yml
---
- name: CIS Benchmark Compliance Scan
  hosts: all
  gather_facts: true
  vars:
    compliance_report_dir: "/tmp/compliance-reports"
    cis_benchmark_version: "2.0"
    
  tasks:
    - name: Create compliance report directory
      file:
        path: "{{ compliance_report_dir }}"
        state: directory
        mode: '0755'
      delegate_to: localhost
      run_once: true
      
    - name: Initialize compliance results
      set_fact:
        compliance_results: []
        compliance_score: 0
        total_checks: 0
        
    - name: CIS 1.1.1 - Ensure mounting of cramfs filesystems is disabled
      block:
        - name: Check cramfs module
          shell: modprobe -n -v cramfs 2>&1 | grep -E "(install /bin/true|blacklist cramfs)"
          register: cramfs_check
          failed_when: false
          changed_when: false
          
        - name: Record cramfs compliance
          set_fact:
            compliance_results: "{{ compliance_results + [cramfs_result] }}"
            total_checks: "{{ total_checks | int + 1 }}"
            compliance_score: "{{ compliance_score | int + (1 if cramfs_check.rc == 0 else 0) }}"
          vars:
            cramfs_result:
              check_id: "1.1.1"
              title: "Ensure mounting of cramfs filesystems is disabled"
              status: "{{ 'PASS' if cramfs_check.rc == 0 else 'FAIL' }}"
              output: "{{ cramfs_check.stdout }}"
              
    - name: CIS 1.4.1 - Ensure permissions on bootloader config are configured
      block:
        - name: Check bootloader permissions
          stat:
            path: /boot/grub/grub.cfg
          register: grub_stat
          
        - name: Record bootloader compliance
          set_fact:
            compliance_results: "{{ compliance_results + [bootloader_result] }}"
            total_checks: "{{ total_checks | int + 1 }}"
            compliance_score: "{{ compliance_score | int + (1 if grub_compliant else 0) }}"
          vars:
            grub_compliant: "{{ grub_stat.stat.exists and grub_stat.stat.mode == '0600' and grub_stat.stat.pw_name == 'root' }}"
            bootloader_result:
              check_id: "1.4.1"
              title: "Ensure permissions on bootloader config are configured"
              status: "{{ 'PASS' if grub_compliant else 'FAIL' }}"
              current_mode: "{{ grub_stat.stat.mode | default('N/A') }}"
              current_owner: "{{ grub_stat.stat.pw_name | default('N/A') }}"
              
    - name: CIS 5.2.5 - Ensure SSH MaxAuthTries is set to 4 or less
      block:
        - name: Check SSH MaxAuthTries
          shell: grep "^MaxAuthTries" /etc/ssh/sshd_config || echo "MaxAuthTries not set"
          register: ssh_maxauth
          changed_when: false
          
        - name: Parse MaxAuthTries value
          set_fact:
            max_auth_tries: "{{ ssh_maxauth.stdout.split()[1] | int if 'MaxAuthTries' in ssh_maxauth.stdout else 6 }}"
            
        - name: Record SSH MaxAuthTries compliance
          set_fact:
            compliance_results: "{{ compliance_results + [ssh_result] }}"
            total_checks: "{{ total_checks | int + 1 }}"
            compliance_score: "{{ compliance_score | int + (1 if max_auth_tries | int <= 4 else 0) }}"
          vars:
            ssh_result:
              check_id: "5.2.5"
              title: "Ensure SSH MaxAuthTries is set to 4 or less"
              status: "{{ 'PASS' if max_auth_tries | int <= 4 else 'FAIL' }}"
              current_value: "{{ max_auth_tries }}"
              expected: "≤ 4"
              
    # Add more CIS checks...
    
    - name: Calculate compliance percentage
      set_fact:
        compliance_percentage: "{{ ((compliance_score | int) / (total_checks | int) * 100) | round(2) }}"
        
    - name: Generate compliance report
      template:
        src: compliance_report.html.j2
        dest: "{{ compliance_report_dir }}/{{ inventory_hostname }}-compliance-{{ ansible_date_time.date }}.html"
      delegate_to: localhost
      
    - name: Generate JSON report for automation
      copy:
        content: |
          {
            "hostname": "{{ inventory_hostname }}",
            "scan_date": "{{ ansible_date_time.iso8601 }}",
            "benchmark": "CIS Ubuntu Linux {{ cis_benchmark_version }}",
            "compliance_score": {{ compliance_score }},
            "total_checks": {{ total_checks }},
            "compliance_percentage": {{ compliance_percentage }},
            "results": {{ compliance_results | to_nice_json }}
          }
        dest: "{{ compliance_report_dir }}/{{ inventory_hostname }}-compliance-{{ ansible_date_time.date }}.json"
      delegate_to: localhost
      
    - name: Send compliance alert if below threshold
      mail:
        to: "{{ security_team_email }}"
        subject: "Compliance Alert: {{ inventory_hostname }} - {{ compliance_percentage }}%"
        body: |
          Server {{ inventory_hostname }} compliance scan results:
          
          Compliance Score: {{ compliance_percentage }}%
          Failed Checks: {{ total_checks | int - compliance_score | int }}
          
          Please review the detailed report for remediation steps.
      when: compliance_percentage | float < compliance_threshold | default(80)
      delegate_to: localhost
```

## CI/CD Integration

### **1. GitLab CI Pipeline**
```yaml
# .gitlab-ci.yml
stages:
  - test
  - security
  - deploy-dev
  - deploy-staging
  - deploy-prod

variables:
  ANSIBLE_HOST_KEY_CHECKING: "False"
  ANSIBLE_STDOUT_CALLBACK: "yaml"
  PIP_CACHE_DIR: "$CI_PROJECT_DIR/.cache/pip"

cache:
  paths:
    - .cache/pip
    - venv/

before_script:
  - python -m venv venv
  - source venv/bin/activate
  - pip install -r requirements.txt
  - ansible-galaxy install -r requirements.yml

# Testing Stage
ansible-lint:
  stage: test
  script:
    - ansible-lint playbooks/ roles/
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
    - if: '$CI_COMMIT_BRANCH == "main"'

syntax-check:
  stage: test
  script:
    - ansible-playbook --syntax-check site.yml
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
    - if: '$CI_COMMIT_BRANCH == "main"'

molecule-test:
  stage: test
  image: quay.io/ansible/molecule:3.6.0
  services:
    - docker:dind
  variables:
    DOCKER_HOST: tcp://docker:2376
    DOCKER_TLS_CERTDIR: "/certs"
    DOCKER_TLS_VERIFY: 1
    DOCKER_CERT_PATH: "$DOCKER_TLS_CERTDIR/client"
  script:
    - cd roles/kubernetes_cluster
    - molecule test
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
    - changes:
        - roles/**/*

# Security Stage
vault-security-scan:
  stage: security
  script:
    - |
      for vault_file in $(find . -name "*vault*" -type f); do
        if ansible-vault view --vault-password-file=<(echo $VAULT_PASSWORD) $vault_file > /dev/null 2>&1; then
          echo "✓ $vault_file is properly encrypted"
        else
          echo "✗ $vault_file is not properly encrypted"
          exit 1
        fi
      done
  rules:
    - if: '$CI_COMMIT_BRANCH == "main"'

secrets-scan:
  stage: security
  image: registry.gitlab.com/gitlab-org/security-products/analyzers/secrets:3
  script:
    - /analyzer run
  artifacts:
    reports:
      secret_detection: gl-secret-detection-report.json

# Deployment Stages
.deploy_template: &deploy_template
  before_script:
    - !reference [.before_script]
    - eval $(ssh-agent -s)
    - echo "$SSH_PRIVATE_KEY" | tr -d '\r' | ssh-add -
    - mkdir -p ~/.ssh && chmod 700 ~/.ssh
    - echo "$SSH_KNOWN_HOSTS" > ~/.ssh/known_hosts
    - chmod 644 ~/.ssh/known_hosts

deploy-dev:
  <<: *deploy_template
  stage: deploy-dev
  environment:
    name: development
    url: https://dev.myapp.com
  script:
    - |
      ansible-playbook site.yml \
        -i inventories/development \
        --vault-password-file=<(echo $VAULT_PASSWORD_DEV) \
        --extra-vars "deployment_version=$CI_COMMIT_SHA"
  rules:
    - if: '$CI_COMMIT_BRANCH == "develop"'

deploy-staging:
  <<: *deploy_template
  stage: deploy-staging
  environment:
    name: staging
    url: https://staging.myapp.com
  script:
    - |
      ansible-playbook site.yml \
        -i inventories/staging \
        --vault-password-file=<(echo $VAULT_PASSWORD_STAGING) \
        --extra-vars "deployment_version=$CI_COMMIT_SHA" \
        --check --diff
    - echo "Staging deployment plan generated. Proceeding with actual deployment..."
    - |
      ansible-playbook site.yml \
        -i inventories/staging \
        --vault-password-file=<(echo $VAULT_PASSWORD_STAGING) \
        --extra-vars "deployment_version=$CI_COMMIT_SHA"
  rules:
    - if: '$CI_COMMIT_BRANCH == "main"'

deploy-prod:
  <<: *deploy_template
  stage: deploy-prod
  environment:
    name: production
    url: https://myapp.com
  script:
    - |
      ansible-playbook site.yml \
        -i inventories/production \
        --vault-password-file=<(echo $VAULT_PASSWORD_PROD) \
        --extra-vars "deployment_version=$CI_COMMIT_TAG"
  rules:
    - if: '$CI_COMMIT_TAG'
  when: manual
  allow_failure: false
```

### **2. GitHub Actions Workflow**
```yaml
# .github/workflows/ansible-deploy.yml
name: Ansible Deployment Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]
  release:
    types: [published]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.9'
        cache: 'pip'
    
    - name: Install dependencies
      run: |
        pip install -r requirements.txt
        ansible-galaxy install -r requirements.yml
    
    - name: Ansible Lint
      run: ansible-lint playbooks/ roles/
    
    - name: Syntax Check
      run: ansible-playbook --syntax-check site.yml
    
    - name: Run Molecule Tests
      run: |
        cd roles/kubernetes_cluster
        molecule test
      env:
        PY_COLORS: '1'
        ANSIBLE_FORCE_COLOR: '1'

  deploy-dev:
    if: github.ref == 'refs/heads/develop'
    needs: test
    runs-on: ubuntu-latest
    environment: development
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.9'
        cache: 'pip'
    
    - name: Install dependencies
      run: |
        pip install -r requirements.txt
        ansible-galaxy install -r requirements.yml
    
    - name: Configure SSH
      env:
        SSH_PRIVATE_KEY: ${{ secrets.SSH_PRIVATE_KEY }}
        SSH_KNOWN_HOSTS: ${{ secrets.SSH_KNOWN_HOSTS }}
      run: |
        mkdir -p ~/.ssh
        echo "$SSH_PRIVATE_KEY" > ~/.ssh/id_rsa
        chmod 600 ~/.ssh/id_rsa
        echo "$SSH_KNOWN_HOSTS" > ~/.ssh/known_hosts
        chmod 644 ~/.ssh/known_hosts
    
    - name: Deploy to Development
      env:
        VAULT_PASSWORD: ${{ secrets.VAULT_PASSWORD_DEV }}
      run: |
        echo "$VAULT_PASSWORD" > .vault_pass
        ansible-playbook site.yml \
          -i inventories/development \
          --vault-password-file .vault_pass \
          --extra-vars "deployment_version=${{ github.sha }}"
        rm .vault_pass

  deploy-prod:
    if: github.event_name == 'release'
    needs: test
    runs-on: ubuntu-latest
    environment: production
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.9'
        cache: 'pip'
    
    - name: Install dependencies
      run: |
        pip install -r requirements.txt
        ansible-galaxy install -r requirements.yml
    
    - name: Configure SSH
      env:
        SSH_PRIVATE_KEY: ${{ secrets.SSH_PRIVATE_KEY_PROD }}
        SSH_KNOWN_HOSTS: ${{ secrets.SSH_KNOWN_HOSTS }}
      run: |
        mkdir -p ~/.ssh
        echo "$SSH_PRIVATE_KEY" > ~/.ssh/id_rsa
        chmod 600 ~/.ssh/id_rsa
        echo "$SSH_KNOWN_HOSTS" > ~/.ssh/known_hosts
        chmod 644 ~/.ssh/known_hosts
    
    - name: Deploy to Production
      env:
        VAULT_PASSWORD: ${{ secrets.VAULT_PASSWORD_PROD }}
      run: |
        echo "$VAULT_PASSWORD" > .vault_pass
        ansible-playbook site.yml \
          -i inventories/production \
          --vault-password-file .vault_pass \
          --extra-vars "deployment_version=${{ github.event.release.tag_name }}"
        rm .vault_pass
```

## Advanced Testing with Molecule

### **1. Molecule Configuration**
```yaml
# roles/kubernetes_cluster/molecule/default/molecule.yml
---
dependency:
  name: galaxy
  options:
    requirements-file: requirements.yml

driver:
  name: docker

platforms:
  - name: ubuntu-20-master
    image: ubuntu:20.04
    command: /sbin/init
    privileged: true
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:ro
    groups:
      - master
    networks:
      - name: k8s-network

  - name: ubuntu-20-worker1
    image: ubuntu:20.04
    command: /sbin/init
    privileged: true
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:ro
    groups:
      - worker
    networks:
      - name: k8s-network

  - name: ubuntu-20-worker2
    image: ubuntu:20.04
    command: /sbin/init
    privileged: true
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:ro
    groups:
      - worker
    networks:
      - name: k8s-network

provisioner:
  name: ansible
  config_options:
    defaults:
      host_key_checking: false
      stdout_callback: yaml
  inventory:
    host_vars:
      ubuntu-20-master:
        kubernetes_role: master
      ubuntu-20-worker1:
        kubernetes_role: worker
      ubuntu-20-worker2:
        kubernetes_role: worker

verifier:
  name: ansible

lint: |
  set -e
  yamllint .
  ansible-lint
  flake8
```

```python
# roles/kubernetes_cluster/molecule/default/tests/test_default.py
import os
import testinfra.utils.ansible_runner

testinfra_hosts = testinfra.utils.ansible_runner.AnsibleRunner(
    os.environ['MOLECULE_INVENTORY_FILE']
).get_hosts('all')

def test_kubelet_service(host):
    """Test that kubelet service is running."""
    service = host.service('kubelet')
    assert service.is_running
    assert service.is_enabled

def test_kubernetes_components_installed(host):
    """Test that Kubernetes components are installed."""
    packages = ['kubelet', 'kubeadm', 'kubectl']
    for package in packages:
        pkg = host.package(package)
        assert pkg.is_installed

def test_container_runtime(host):
    """Test that container runtime is configured."""
    # Test Docker or containerd
    docker = host.service('docker')
    containerd = host.service('containerd')
    
    assert docker.is_running or containerd.is_running

def test_kubernetes_api_server(host):
    """Test API server on master nodes."""
    if 'master' in host.ansible.get_variables().get('group_names', []):
        # Check if API server is responding
        cmd = host.run('kubectl get nodes')
        assert cmd.rc == 0
        
        # Check cluster info
        cmd = host.run('kubectl cluster-info')
        assert cmd.rc == 0
        assert 'Kubernetes control plane' in cmd.stdout

def test_pod_network(host):
    """Test pod networking on master nodes."""
    if 'master' in host.ansible.get_variables().get('group_names', []):
        # Check if CNI is working
        cmd = host.run('kubectl get pods -n kube-system')
        assert cmd.rc == 0
        
        # Verify CNI pods are running
        cmd = host.run('kubectl get pods -n kube-system | grep -E "(calico|flannel|weave)"')
        assert cmd.rc == 0

def test_worker_nodes_joined(host):
    """Test that worker nodes have joined the cluster."""
    if 'master' in host.ansible.get_variables().get('group_names', []):
        cmd = host.run('kubectl get nodes')
        assert cmd.rc == 0
        
        # Should have at least 3 nodes (1 master + 2 workers)
        nodes = cmd.stdout.strip().split('\n')
        assert len(nodes) >= 3
        
        # All nodes should be Ready
        for line in nodes[1:]:  # Skip header
            assert 'Ready' in line
```

## Performance and Best Practices

### **1. Ansible Performance Optimization**
```yaml
# ansible.cfg
[defaults]
host_key_checking = False
gathering = smart
fact_caching = jsonfile
fact_caching_connection = /tmp/ansible_facts_cache
fact_caching_timeout = 86400
timeout = 30
forks = 20
poll_interval = 1

# Connection optimization
pipelining = True
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o PreferredAuthentications=publickey
control_path_dir = /tmp/.ansible-cp

# Callback plugins
stdout_callback = yaml
callback_whitelist = timer, profile_tasks, profile_roles

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes
pipelining = True
```

### **2. Smart Fact Gathering**
```yaml
# playbooks/optimized_facts.yml
---
- name: Optimized Infrastructure Management
  hosts: all
  gather_facts: false  # Disable automatic gathering
  
  pre_tasks:
    # Gather only essential facts
    - name: Gather minimal facts
      setup:
        gather_subset:
          - '!all'
          - '!min'
          - network
          - hardware
          - virtual
      when: inventory_hostname not in hostvars or hostvars[inventory_hostname].get('ansible_os_family') is undefined
      
    # Cache custom facts
    - name: Generate custom facts
      set_fact:
        deployment_facts:
          deployment_id: "{{ deployment_id | default(ansible_date_time.epoch) }}"
          environment: "{{ environment }}"
          cluster_name: "{{ cluster_name }}"
      cacheable: true
      
  tasks:
    - name: Use cached facts efficiently
      debug:
        msg: "Deploying {{ deployment_facts.deployment_id }} to {{ deployment_facts.environment }}"
```

## Useful Links

- [Ansible Documentation](https://docs.ansible.com/)
- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)
- [Molecule Documentation](https://molecule.readthedocs.io/)
- [Ansible Galaxy](https://galaxy.ansible.com/)
- [AWX Project](https://github.com/ansible/awx)
- [Ansible Collections](https://docs.ansible.com/ansible/latest/user_guide/collections_using.html)
