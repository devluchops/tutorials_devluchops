#!/usr/bin/python
# -*- coding: utf-8 -*-

# Custom Ansible Module: deploy_with_rollback
# Deploys application with automatic rollback capability

from ansible.module_utils.basic import AnsibleModule
import os
import shutil
import subprocess
import time
import requests
import json

DOCUMENTATION = '''
---
module: deploy_with_rollback
short_description: Deploy application with automatic rollback on failure
description:
    - Deploys application to specified directory
    - Performs health checks after deployment
    - Automatically rolls back to previous version on failure
    - Maintains deployment history
version_added: "2.9"
options:
    app_name:
        description:
            - Name of the application
        required: true
        type: str
    app_path:
        description:
            - Base path for application deployment
        required: true
        type: str
    version:
        description:
            - Version to deploy
        required: true
        type: str
    artifact_url:
        description:
            - URL to download application artifact
        required: false
        type: str
    health_check_url:
        description:
            - URL for health check after deployment
        required: false
        type: str
        default: "http://localhost:8080/health"
    health_check_timeout:
        description:
            - Timeout for health check in seconds
        required: false
        type: int
        default: 300
    rollback_on_failure:
        description:
            - Whether to rollback on deployment failure
        required: false
        type: bool
        default: true
    keep_versions:
        description:
            - Number of versions to keep
        required: false
        type: int
        default: 5
    service_name:
        description:
            - Name of systemd service to restart
        required: false
        type: str
author:
    - "DevOps Team"
'''

EXAMPLES = '''
- name: Deploy application with rollback
  deploy_with_rollback:
    app_name: "my-app"
    app_path: "/opt/my-app"
    version: "1.2.3"
    artifact_url: "https://releases.company.com/my-app-1.2.3.tar.gz"
    health_check_url: "http://localhost:3000/health"
    service_name: "my-app"

- name: Deploy without health check
  deploy_with_rollback:
    app_name: "my-app"
    app_path: "/opt/my-app"
    version: "1.2.4"
    artifact_url: "https://releases.company.com/my-app-1.2.4.tar.gz"
    health_check_url: ""
'''

RETURN = '''
changed:
    description: Whether the deployment resulted in changes
    type: bool
    returned: always
version_deployed:
    description: Version that was successfully deployed
    type: str
    returned: always
previous_version:
    description: Previous version before deployment
    type: str
    returned: when rollback occurred
rollback_occurred:
    description: Whether rollback was performed
    type: bool
    returned: always
deployment_time:
    description: Time taken for deployment in seconds
    type: float
    returned: always
health_check_status:
    description: Status of health check
    type: str
    returned: when health check is performed
'''


class ApplicationDeployer:
    def __init__(self, module):
        self.module = module
        self.params = module.params
        self.changed = False
        self.deployment_start_time = time.time()
        
    def get_current_version(self):
        """Get currently deployed version"""
        current_link = os.path.join(self.params['app_path'], 'current')
        if os.path.islink(current_link):
            target = os.readlink(current_link)
            return os.path.basename(target)
        return None
    
    def download_artifact(self):
        """Download application artifact"""
        if not self.params['artifact_url']:
            return True
            
        version_dir = os.path.join(self.params['app_path'], 'releases', self.params['version'])
        
        if os.path.exists(version_dir):
            return True
            
        os.makedirs(version_dir, exist_ok=True)
        
        try:
            # Download artifact
            cmd = ['wget', '-O', f"{version_dir}/app.tar.gz", self.params['artifact_url']]
            result = subprocess.run(cmd, capture_output=True, text=True)
            
            if result.returncode != 0:
                self.module.fail_json(msg=f"Failed to download artifact: {result.stderr}")
            
            # Extract artifact
            cmd = ['tar', '-xzf', f"{version_dir}/app.tar.gz", '-C', version_dir, '--strip-components=1']
            result = subprocess.run(cmd, capture_output=True, text=True)
            
            if result.returncode != 0:
                self.module.fail_json(msg=f"Failed to extract artifact: {result.stderr}")
            
            # Remove downloaded archive
            os.remove(f"{version_dir}/app.tar.gz")
            
            self.changed = True
            return True
            
        except Exception as e:
            self.module.fail_json(msg=f"Failed to download/extract artifact: {str(e)}")
    
    def create_symlink(self):
        """Create symlink to current version"""
        version_dir = os.path.join(self.params['app_path'], 'releases', self.params['version'])
        current_link = os.path.join(self.params['app_path'], 'current')
        
        if os.path.islink(current_link):
            os.remove(current_link)
        elif os.path.exists(current_link):
            shutil.rmtree(current_link)
            
        os.symlink(version_dir, current_link)
        self.changed = True
    
    def restart_service(self):
        """Restart application service"""
        if not self.params.get('service_name'):
            return True
            
        try:
            cmd = ['systemctl', 'restart', self.params['service_name']]
            result = subprocess.run(cmd, capture_output=True, text=True)
            
            if result.returncode != 0:
                return False
                
            # Wait for service to start
            time.sleep(5)
            
            cmd = ['systemctl', 'is-active', self.params['service_name']]
            result = subprocess.run(cmd, capture_output=True, text=True)
            
            return result.returncode == 0
            
        except Exception:
            return False
    
    def health_check(self):
        """Perform health check"""
        if not self.params.get('health_check_url'):
            return True, "No health check URL provided"
            
        timeout = self.params.get('health_check_timeout', 300)
        start_time = time.time()
        
        while time.time() - start_time < timeout:
            try:
                response = requests.get(self.params['health_check_url'], timeout=10)
                if response.status_code == 200:
                    return True, "Health check passed"
            except Exception:
                pass
            
            time.sleep(10)
        
        return False, "Health check failed"
    
    def rollback(self, previous_version):
        """Rollback to previous version"""
        if not previous_version:
            return False
            
        previous_dir = os.path.join(self.params['app_path'], 'releases', previous_version)
        if not os.path.exists(previous_dir):
            return False
            
        current_link = os.path.join(self.params['app_path'], 'current')
        
        if os.path.islink(current_link):
            os.remove(current_link)
        elif os.path.exists(current_link):
            shutil.rmtree(current_link)
            
        os.symlink(previous_dir, current_link)
        
        # Restart service
        self.restart_service()
        
        return True
    
    def cleanup_old_versions(self):
        """Cleanup old versions"""
        releases_dir = os.path.join(self.params['app_path'], 'releases')
        keep_versions = self.params.get('keep_versions', 5)
        
        if not os.path.exists(releases_dir):
            return
            
        versions = []
        for item in os.listdir(releases_dir):
            item_path = os.path.join(releases_dir, item)
            if os.path.isdir(item_path):
                stat = os.stat(item_path)
                versions.append((item, stat.st_mtime))
        
        # Sort by modification time (newest first)
        versions.sort(key=lambda x: x[1], reverse=True)
        
        # Remove old versions
        for version, _ in versions[keep_versions:]:
            version_path = os.path.join(releases_dir, version)
            shutil.rmtree(version_path)
    
    def deploy(self):
        """Main deployment logic"""
        current_version = self.get_current_version()
        rollback_occurred = False
        health_check_status = ""
        
        # Create releases directory
        releases_dir = os.path.join(self.params['app_path'], 'releases')
        os.makedirs(releases_dir, exist_ok=True)
        
        # Check if version already deployed
        version_dir = os.path.join(releases_dir, self.params['version'])
        if os.path.exists(version_dir) and current_version == self.params['version']:
            deployment_time = time.time() - self.deployment_start_time
            return {
                'changed': False,
                'version_deployed': self.params['version'],
                'rollback_occurred': False,
                'deployment_time': deployment_time,
                'health_check_status': 'Already deployed'
            }
        
        try:
            # Download and extract artifact
            self.download_artifact()
            
            # Create symlink to new version
            self.create_symlink()
            
            # Restart service
            if not self.restart_service():
                raise Exception("Failed to restart service")
            
            # Perform health check
            health_ok, health_check_status = self.health_check()
            
            if not health_ok and self.params.get('rollback_on_failure', True):
                # Rollback
                if self.rollback(current_version):
                    rollback_occurred = True
                    health_check_status += " - Rolled back to previous version"
                else:
                    health_check_status += " - Rollback failed"
                    
        except Exception as e:
            if self.params.get('rollback_on_failure', True) and current_version:
                if self.rollback(current_version):
                    rollback_occurred = True
                    health_check_status = f"Deployment failed: {str(e)} - Rolled back"
                else:
                    health_check_status = f"Deployment failed: {str(e)} - Rollback failed"
            else:
                self.module.fail_json(msg=f"Deployment failed: {str(e)}")
        
        # Cleanup old versions
        self.cleanup_old_versions()
        
        deployment_time = time.time() - self.deployment_start_time
        
        result = {
            'changed': self.changed,
            'version_deployed': current_version if rollback_occurred else self.params['version'],
            'rollback_occurred': rollback_occurred,
            'deployment_time': deployment_time,
            'health_check_status': health_check_status
        }
        
        if rollback_occurred and current_version:
            result['previous_version'] = current_version
            
        return result


def main():
    module = AnsibleModule(
        argument_spec=dict(
            app_name=dict(type='str', required=True),
            app_path=dict(type='str', required=True),
            version=dict(type='str', required=True),
            artifact_url=dict(type='str', required=False),
            health_check_url=dict(type='str', required=False, default='http://localhost:8080/health'),
            health_check_timeout=dict(type='int', required=False, default=300),
            rollback_on_failure=dict(type='bool', required=False, default=True),
            keep_versions=dict(type='int', required=False, default=5),
            service_name=dict(type='str', required=False),
        ),
        supports_check_mode=True
    )
    
    if module.check_mode:
        module.exit_json(changed=True, msg="Would deploy application")
    
    deployer = ApplicationDeployer(module)
    result = deployer.deploy()
    
    module.exit_json(**result)


if __name__ == '__main__':
    main()
