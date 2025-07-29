Steps
-----

### Installing GitLab Runner Operator

Perform the following steps to install GitLab Runner Operator:

1.  Search for **GitLab Runner** Operator in the OperatorHub section on your ppc64le cluster and click **Install** to install it.
    
    ![image1](https://developer.ibm.com/developer/default/tutorials/gitlab-runner-operator-on-ibm-power/images/img1.jpg)
    
2.  Notice that within a few seconds, the GitLab Runner Operator get installed.
    
    ![image2](https://developer.ibm.com/developer/default/tutorials/gitlab-runner-operator-on-ibm-power/images/img2.jpg)
    

### Create GitLab Runner

Perform the following steps to create a GitLab Runner:

1.  Create a namespace for your project.
    
    `oc new-project gitlab-runner-system`
    
2.  Create the secret file with your GitLab project's runner token:
    
    In your GitLab project, click **Settings** \-> **CI/CD**. Then expand **Runners**. Copy your registration token.
    
    ![image3](https://developer.ibm.com/developer/default/tutorials/gitlab-runner-operator-on-ibm-power/images/img3.jpg)
    
    In the gitlab-runner-secret.yml file, replace your project runner secret with the registration token that you just copied.
    
        cat > gitlab-runner-secret.yml << EOF
        apiVersion: v1
        kind: Secret
        metadata:
          name: gitlab-runner-secret
        type: Opaque
        stringData:
          runner-registration-token: <REPLACE_ME> # your project runner secret
        EOF
        
        oc apply -f gitlab-runner-secret.yml
        
    
    Show more
    
3.  Create the runner from the custom resource definition (CRD) file.
    
    Create a CRD file with the following information. The `tags` value must be **openshift** for the job to run.
    
        cat > gitlab-runner.yml << EOF
        apiVersion: apps.gitlab.com/v1beta2
        kind: Runner
        metadata:
          name: gitlab-runner
        spec:
          gitlabUrl: <YOUR GITLAB INSTANCE URL>
          buildImage: alpine
          token: gitlab-runner-secret
          tags: openshift
        EOF
        
        oc apply -f gitlab-runner.yml
        
    
    Show more
    
4.  Confirm that GitLab Runner is installed by running the following command:
    
        oc get runners
        
        NAME               AGE
        
        gitlab-runner      14d
        
    
    Show more
    
    You can also check the runner and controller pods as shown below:
    
    ![image4](https://developer.ibm.com/developer/default/tutorials/gitlab-runner-operator-on-ibm-power/images/img4.jpg)
    
5.  Verify that runner is listed in the **Available specific runners** list for the GitLab project. In your GitLab project, click **Settings** \-> **CI/CD**. Then expand **Runners**.
    
    ![image5](https://developer.ibm.com/developer/default/tutorials/gitlab-runner-operator-on-ibm-power/images/img5.jpg)
    
6.  Configure the code to use the new runner.
    
    Modify the tag field in the **.gitlab-ci.yaml** file to use the newly available runner. Refer to the [sample repository](https://gitlab.com/skanekar1/myfirstproject/) used in this tutorial.
    
    ![image6](https://developer.ibm.com/developer/default/tutorials/gitlab-runner-operator-on-ibm-power/images/img6.jpg)
    
    A new build will now use the '**openshift**' runner. It will create a new pod to run the build.
    
    ![image7](https://developer.ibm.com/developer/default/tutorials/gitlab-runner-operator-on-ibm-power/images/img7new.png)
    

You have now configured your GitLab project to use GitLab Runner for Power. The GitLab Runner Operator will manage the lifecycle of your runners.