## Installing OpenShift 4.7 into AWS Protected B environment

### Pre-requisites:
* You have a SEA environment v.1.3.2 or later 
* You have account organization admin access to this environment
* You have created your SEA environment with 3 availability zones
* You have a Red Hat account
* You are familiar with OpenShift user-provisioned infrastructure installation process

We have created a dedicated OpenShift Account called `OpenShiftInstaller` during the provisioning process of PBMM. We 
will be using this account to install Red Hat OpenShift v.4.7 into AWS Protected B environment.
You can choose to create a new account or use one of the existing SEA accounts (i.e. DEV). 

You must complete this installation within 24hrs. Otherwise OpenShift certificates will expire and you will have
to regenerate ignition files and update your code to include the new infrastructure ID.

## A. Preparing for installation
1. Log into your aws account using Account Administrator role. In this example
we use SSO to easily switch between accounts

2. Assume `PBMMAccel-PipelineRole`. In the switch role menu provide Pipeline role name: PBMMAccel-PipelineRole and your the account ID of
the account that will be used to install OpenShift. In our example we use the ID of OpenShift install account.

3. Go to IAM and create a user that will be used to install OpenShift. In this example we call it OpenShiftInstallUser
   1. Allow programatic access
   2. Attach existing policy "AdministratorAccess" ^1
   3. Record access key id and secret access key  
      NOTE: you can create your own role following the official documentation for Red Hat OpenShift

4. Login to `OpenShiftInstaller` Account and verify that the user was created and have correct permissions

5. In `OpenShiftInstaller` account create a public DNS zone. Note this zone is used for the installer
and will not be publicly resolved. See post-installation step on how to allow external traffic
to your cluser. In our example we use: octank-demo.ca

6. Create a small EC2 instance. It will be used to install OpenShift. In our example we use t2.xlarge but smaller instances
should work as well. The operating system type should be AWS Linux or RHEL.  
   NOTE: if you choose RHEL you might need to isntall
   management utils. They are needed in order to be able to connect to the remote shell

7. In your web-browser go to https://cloud.redhat.com and log in with your Red Hat credentials
    7. In Red Hat OpenShift Cluster Manager click Cluster Manager link
    7. Select create cluster. In "Run It Yourself" section select AWS and then user-provisioned infrastructure
    7. On the screen copy links for the latest version of OpenShift installer and Command line interface
    7. Download and save the pull secret. It will be used to pull images from internal red hat registries
    7. Close this tab

8. Connect to your EC2 instance that you created in step.X. In the console download openshift-install-linux.tar.gz
and openshift-client-linux.tar.gz using links from the previous steps and extract them 
    ```
    $ wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-install-linux.tar.gz
    $ wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux.tar.gz
    $ tar xfv openshift-install-linux.tar.gz
    $ tar xfv openshift-client-linux.tar.gz
    ``` 
    For your convenience move these binaries to your system path  
    `$ cp oc openshift-install /usr/local/bin/`
9. Install AWS cli command following the instructions
https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-linux.html

10. Run `$ aws configure`  
For `AWS Access Key ID` provide the access key id of OpenShiftInstall user that you created  
For `AWS Secret Access Key` provide secret access key for OpenShiftInstall user that you created  
For `Default region` type in `ca-central-1`  
For `Default output format` type in `json`  

11. Clone this repository  
`$ git clone https://github.com/kiwikik/protectedb_openshift.git
`
12. Create a folder for storing OpenShift configuration. We call ours "clusterconfigs".
### B. Generating OpenShift cluster configs
For more information refer to: https://docs.openshift.com/container-platform/4.7/installing/installing_aws/installing-aws-user-infra.html
1. Retrieve install-config.yaml  
`$ cp ./openshift_aws_sea/install-config.yaml ./clusterconfigs/`  
2. Generate private and public ssh key pairs  
`ssh-keygen -t ed25519 -N '' -f ~/.ssh/openshift`  
3. Update your `install-config.yaml` file. You need to make sure your `baseDomain` matches your public Route53 hosted
zone. In metadata field specify the name of your cluster(you can choose this name). We use `seaocp` in this example. 
For `machineNetwork` specify the cidr of your shared VPC(i.e. Dev_vpc). In our example we use cidr: `10.2.0.0/16`
Provide your pull secret that you downloaded earlier from cloud.redhat.com. Provide your ssh public key that you
generated earlier.
4. Backup `install-config.yaml` file. This file will be deleted after manifests are created  
`$ cp install-config.yaml ~/install-config.yaml.backup`  
5. Make sure you are in the directory where `install-config.yaml` is located.
6. Verify you're logged in with the correct AWS credentials:  
` $ aws sts get-caller-identity`  
 Run openshift-install commands to create manifests  
`openshift-install create manifests`
7. Remove manifests for Control and Compute machines  
    ```
    rm -f ~/clusterconfigs/openshift/99_openshift-cluster-api_master-machines-*.yaml
    rm -f ~/clusterconfigs/openshift/99_openshift-cluster-api_worker-machineset-*.yaml
    ```  
8. Check that the `mastersSchedulable` parameter in the ~/clusterconfigs/manifests/cluster-scheduler-02-config.yml
file is set to `false`.
9. Create ignition bootstrap files:  
    `$ openshift-install create ignition-configs`  

    You should see *.ign files and an auth directory created

10. Extract the infrastructure name  
    `jq -r .infraID ~/clusterconfigs/metadata.json`  
    Please save `infraID`. In our example it will be `seaocp-2mtml`

### C. Creating a private DNS zone.
1. Log in as Account Organization Admin and then switch roles. For the `Account` specify the accountID 
of OpenShiftInstall account (OpenShiftInstaller) and for the `Role` type in `PBMMAccel-PipelineRole` 
 ![Alt text](images/switch_roles_aws.png?raw=true "Switch Roles")	
2. Create a temporary vpc in your OpenShift install account
 ![Alt text](images/create_vpc.png?raw=true "Create VPC")	
3. Create a private DNS zone in the format  

     `<cluster_name>.<base_domain>  `
 
	Zone name should match the cluster name we provided in install-config.yaml file. In our example it will be:
	seaocp.octank-demo.ca. Select the temp VPC that we created in step #2.  
	Apply the TAGs in the following format:  
    ```
    Key: "kubernetes.io/cluster/{InfrastructureName} Value: owned
    Key: "Name" Value: {InfrastructureName}-int
    ```
    i.e.  
    Name = seapoc-2mtml-int  
    kubernetes.io/cluster/seapoc-2mtml = owned  

    ![Alt text](images/p_dns_1.png?graw=true "Title")	
    ![Alt text](images/p_dns_2.png?raw=true "Title")	
 
4. Now we will need to create a VPC association for this DNS with our existing shared VPC.
Refer to [AWS documentation.](https://aws.amazon.com/premiumsupport/knowledge-center/private-hosted-zone-different-account/)

5. Switch back to OpenShiftInstaller account and connect to your running EC2 instance where we had AWS cli installed
and run the following commands:
    ```
    $ aws route53 list-hosted-zones 
    $ aws route53 create-vpc-association-authorization --hosted-zone-id /hostedzone/Z027XXXXXXXX --vpc VPCRegion=ca=central-1,VPCId=vpc-09820xxxxx 
    ```
    Were:  
    `VPCId` - is your existing private VPC shared from another account  
    `hosted-zone-id` - is the id of your private hosted zone

6. Now we'll need to approve the association using the role that has permission to run Route 53 APIs in the Account.
In our example we use SharedNetwork account to approve it. You can simply set env variables on your EC2 instance
to do that. 
    ```
    export AWS_ACCESS_KEY_ID="ASIXXXXXXX"
    export AWS_SECRET_ACCESS_KEY="XXXXXXXXXX"
    export AWS_SESSION_TOKEN="FXXXSSDFXXXXX"
    ```  
    ```$ aws route53 associate-vpc-with-hosted-zone --hosted-zone-id /hostedzone/Z027XXXXXXXX --vpc VPCRegion=ca-central-1,VPCId=VPCId=vpc-09820xxxxx```  
    
    You can now delete the temp VPC. Note that VPCId is now the id of the temp network. 

7. IMPORTANT: Exit EC2 console to remove ENV variables we just added

## D. Updating SCP
### Pre-requirements
* You created an IAM user to run the installation (i.e.OpenShiftInstallUser)
* You created ignition configuration files for OpenShift
* You have the `infraID` for your future cluster
* You have the ARN for the `OpenShiftInstallUser` 

### Updating the policy
Download the latest `ASEA-Guardrails-Sensitive.json` policy from the [Official AWS Sea Repo](https://github.com/aws-samples/aws-secure-environment-accelerator/tree/main/reference-artifacts/SCPs).
Note: _file name might be different for the future releases of SEA. The sample of updated policy for this example
can be located [here](./scps/Sample.ASEA-Guardrails-Sensitive.json)._

1. Update the policy to allow OpenShiftInstallerUser to perform required operations in AWS.
   1. For `"Sid": "DenyNetworkSensitive"` add ARN of your `OpenShiftInstallUser`
      ![Alt text](images/scp-1.png?raw=true "AWS SCP 1")
    2. For `"Sid": "DenyAllOutsideCanadaSensitive"` add ARN of your `infraID` in following format
    `arn:aws:iam::637326xxxxx:user/<infraID>-*`  
       Note: _OpenShift Cluster Credential operator will create additional IAM users to perform cluster tasks. Such as
       update your private DNS zone records._
       ![Alt text](images/scp-2.png?raw=true "AWS SCP 2")
2. Login to AWS console as Account Organization Admin. Go to S3 console and select your SEA's central bucket. This was
specified in your `config.json` file that you used to create your PBMM environment
   (i.e. ` "central-bucket": "sea-aws-redhat-config"`). Select the `scp` folder. If you don't have this directory,
   you need to create it.
![Alt text](images/s3-bucket.png?raw=true "S3 Bucket") 
3. Upload your modified `ASEA-Guardrails-Sensitive.json` policy file into the scp directory. Keep other options at their 
defaults.
   ![Alt text](images/upload-policy.png?raw=true "Policy Upload")
   
4. Re-run your Main State Machine 
 ![Alt text](images/run-step-function.png?raw=true "Run Step Function")
   
5. Wait for approximately 20 minutes and verify that all the steps have completed successfully.
![Alt text](images/state-machine-completed.png?raw=true "Step Function Completed")

6. **Optional:** In your `AWS Organizations` Console verify that the policy was applied to the account
![Alt text](images/verify-scp.png?raw=true "Verify SCP")
   Select the `PBMMAccel-Guardrails-Sensitive` policy and inspect the content to make sure the two users were added.

## E. Installing OpenShift

### Pre-requirements
* You have 3 App and 3 Web subnets in your accelerator environment
* You cloned this repository to your EC2 instance

The `artifacts` directory of this repository provides required CloudFormation templates, Parameter Files and Shell
Script that you can use for UPI installation of OpenShift. Normally, you should not need to change any of the templates
and will only be updating parameters `.json` files specific to your environment. The templates need to be run in the 
specific order outlined here. For the full explanation of the parameter please refer to [OpenShift Documentation](https://docs.openshift.com/container-platform/4.7/installing/installing_aws/installing-aws-user-infra.html)

### OpenShift Installation
1. Login to AWS Management Console using `OpenShiftInstaller` account and connect to the Session Manager of EC2
that you set up to run OpenShift installation
![Alt text](images/aws-session-manager.png?raw=true "Verify SCP")
   
2. Verify your AWS identity  
   
    ![Alt text](images/aws-caller-identity.png?raw=true "Verify AWS Identity")
 
3. Switch to the `protectedb_openshift/artifacts` directory. (_This is the directory you cloned from Git_).
    ![Alt text](images/artifacts-dir.png?raw=true "Verify AWS Identity")
   
4. Create Network Components 
   1. Update `NetworkParams.json` file according to your environment. Note that `HostedZoneId` is your public Route 53
      Zone and `IntDns` is your Private Route 53 zone we created earlier. We chose `App_Dev_azX_net` as our PrivateSubnet
      and `Web_Dev_azX_net` as our Public Subnets.
      
   2. Run the Network script  
       `$ ./CreateOpenshiftNetwork.sh`
       
   3. Wait until `OpenShiftNetwork` stack is complete. You can also use AWS Web-UI to check for progress.

5. Create Security Groups
   0. Update `SGParams.json` file according to your environment    
   1. Run: `$ ./CreateSG.sh`
   2. Wait until `OpenShiftSecurityGroups` stack is completed
    
6. Upload your boostrap config file to an AWS S3 bucket
    1. Create an AWS S3 bucket  
  ` $ aws s3 mb s3://<cluster-name>-infra`
    2. Copy boostrap.ign file to the bucket. `boostrap.ign` file can be located in the `clusterconfigs` directory  
    `$ aws s3 cp ~/clusterconfigs/bootstrap.ign s3://<cluster-name>-infra/bootstrap.ign`
    3. Verify the file has been uploaded  
    `$ aws s3 ls s3://<cluster-name>-infra`
       
7. Create Bootstrap Node
   1. Update `BootstrapParams.json` file according to your environment. You will need the values from the outputs
   of `Network` and `Security Groups` stacks. You can use AWS Web Console to retrieve them.
   3. Run: `$ ./CreateBootstrap.sh`
   4. Wait until `OpenShiftBootstrapNode` Stack is completed
    
8. Create Control Plane Nodes
    1. Update `ControlPlaneParams.json`. You will need the values from the outputs
   of `Network` and `Security Groups` stacks. `CertificateAuthorities` can be retrieved 
       from `master.ign` file by copying the `"data:text/plain..."` section
    2. Run `$ ./CreateControlPlane.sh` 
    4. Wait until the Stack is completed
    
9. Create Compute Nodes
    1. Compute Node 1
         1. Update `ComputeNodeParams.json`. Please select one of your Availability zones. We use the id of `Web_Dev_aza_net` in 
            this example. You will also need the values 
            from the outputs of `Network` and `Security Groups` stacks. `CertificateAuthorities` can be retrieved 
            from `worker.ign` file by copying the `"data:text/plain..."` section
         2. Run `$ ./CreateComputeNodes.sh`   
    2. Compute Node 2
         1. Update `ComputeNodeParams.json`. Please select one of your other Availability zones. We use the id of `Web_Dev_azb_net` in 
            this example. You do not need to change anything else.
         2. Run `$ aws cloudformation create-stack --stack-name OpenShiftComputeNode2 --parameters file://ComputeNodeParams.json --template-body file://ComputeNodeTemplate.yaml`  
    3. Wait until both stacks are completed
    4. Login to OpenShift and approve CSRs fo worker nodes  
       ```
       $ export KUBECONFIG=~/clusteconfigs/auth/kubeconfig  
       $ oc get csr
       $ oc get csr -o go-template='{{range .items}}{{if not .status}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}' | xargs --no-run-if-empty oc adm certificate approve
       ``` 
       Verify that you have all nodes in READY state. It might take a few minutes before all the nodes become ready.
       You might also need to approve any additional CSR. 
       ```
       $ oc get csr
       $ oc get nodes
       ```
11. Switch to `clusterconfigs`directory and run:  
    `$ openshift-install wait-for bootstrap-complete`  
    Once you see the message that Boostrap is completed you can  delete Bootstrap EC2 instance  
    ![Alt text](images/bootstrap-completed.png?raw=true "Bootstrap Completed")
    `$ aws cloudformation delete-stack --stack-name OpenShiftBootstrapNode`
    
12. Verify all cluster operators are `Running` and Not in Degraded state  
`$ oc get co`
