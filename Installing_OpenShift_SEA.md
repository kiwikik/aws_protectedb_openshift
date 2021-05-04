## Installing OpenShift 4.7 into AWS Protected B environment
**__NOTE:__** These instructions are provided for product evaluation only and should not 
be used in any **PRODUCTION** type of the environment without further review. 
### Pre-requisites:
* You have a SEA environment v.1.3.2 or later 
* You have account organization admin access to this environment
* You have created your SEA environment with 3 availability zones
* You have a Red Hat account
* You are familiar with OpenShift user-provisioned infrastructure installation process

We have created a dedicated OpenShift Account called `OpenShiftInstaller` during the provisioning process of PBMM. We 
will be using this account to install Red Hat OpenShift v.4.7 into AWS Protected B environment.
You can choose to create a new account or use one of the existing SEA accounts (i.e. DEV). 

**__NOTE:__** You must complete this installation within 24hrs. Otherwise OpenShift certificates will expire and you will have
to regenerate ignition files and update your code to include the new infrastructure ID.

## A. Preparing for installation
1. Log into your aws account using Account Administrator role. In this example
we use SSO to easily switch between accounts

2. Assume `PBMMAccel-PipelineRole`. In the switch role menu provide Pipeline role name: PBMMAccel-PipelineRole and the
   account ID that will be used to install OpenShift. In our example we use the ID of `OpenShiftInstaller` account.
   ![Alt text](images/switch_roles_aws.png?raw=true "Switch Roles")

3. Go to IAM and create a user that will be used to install OpenShift. In this example we call it `OpenShiftInstallUser`
   1. Allow programmatic access
   2. Attach existing policy and choose `AdministratorAccess`
      **_NOTE:_** you can choose to create your own role following the official [Red Hat documentation](https://docs.openshift.com/container-platform/latest/installing/installing_aws/installing-aws-account.html#installation-aws-permissions_installing-aws-account)

   3. Record `access_key_id` and `secret_access_key`  

   4. Login to `OpenShiftInstaller` Account and verify that the user was created and has correct permissions

5. In `OpenShiftInstaller` account create a public DNS zone. Note this zone is used for the installer
and will not be publicly resolved. See post-installation step on how to allow external traffic
to your cluster. In our example we use: `octank-demo.ca`

6. Create a small EC2 instance. It will be used to install OpenShift. Here we used `t2.xlarge` but smaller
   instances should work as well. The operating system type should be AWS Linux or RHEL. Please attach `EC2-Default-SSM-AD-Role`
   role to this instance.
   **_NOTE:_** if you choose RHEL you might need to install
   management utils in order to be able to connect to the remote console

7. In your web-browser go to https://cloud.redhat.com and log in with your Red Hat credentials
    1. In Red Hat OpenShift Cluster Manager click Cluster Manager link
       ![Alt text](images/cluster-manager.png?raw=true "Red Hat Cluster Manager")
    2. Select `Create Cluster`. In "Run It Yourself" section select AWS and then user-provisioned infrastructure
    3. Copy links for the latest version of **OpenShift** installer and **Command line interface**
    4. Download and save the **Pull Secret**. It will be used to pull images from internal Red Hat registries
    5. Close this tab/window
       ![Alt text](images/upi-manager.png?raw=true "Red Hat Cluster Manager UPI")

8. Connect to your EC2 instance that you created in Step.5 via Session Manager. Download `openshift-install-linux.tar.gz`
and `openshift-client-linux.tar.gz` using links from the previous step
9. Extract the binaries   
    ```
    $ wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-install-linux.tar.gz
    $ wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux.tar.gz
    $ tar xfv openshift-install-linux.tar.gz
    $ tar xfv openshift-client-linux.tar.gz
    ``` 
    __OPTIONAL__: For your convenience move these binaries to your system path  
    `$ sudo mv oc openshift-install /usr/local/bin/`
9. Install AWS cli command following [AWS instructions](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-linux.html)

10. Run `$ aws configure`  
For `AWS Access Key ID` provide the access key id of OpenShiftInstall user that you created  
For `AWS Secret Access Key` provide secret access key for OpenShiftInstall user that you created  
For `Default region` type in `ca-central-1`  
For `Default output format` type in `json`  

11. Clone this repository  
    `$ git clone https://github.com/kiwikik/aws_protectedb_openshift.git`
    Checkout the branch you want to use i.e.
    ```
    $ git fetch
    $ git checkout -t <remote_name>/<branch_name>
    ```
    
12. Create a folder for storing OpenShift configuration. We call ours `clusterconfigs`.   
    `$ mkdir ~/clusterconfigs`

### B. Generating OpenShift cluster configs
### Pre-requirements
Please collect and have the following values ready:
* ARN of your EBS key
* VPC CIDR of the VPC you will be installing OpenShift into
* Base Domain Name (Route 53 Hosted Zone)
* Red Hat OpenShift PullSecret (from cloud.redhat.com)
* Your public SSH key

For more information refer to: https://docs.openshift.com/container-platform/4.7/installing/installing_aws/installing-aws-user-infra.html
1. Retrieve install-config.yaml  
`$ cp ./aws_protectedb_openshift/artifacts/install-config.yaml ./clusterconfigs/`  
2. Generate private and public ssh key pairs  
`ssh-keygen -t ed25519 -N '' -f ~/.ssh/openshift`  
3. Update your `install-config.yaml` file. You need to make sure your `baseDomain` matches your public Route53 hosted
zone. In metadata field specify the name of your cluster(you can choose this name). We use `seaocp` in this example. 
For `machineNetwork` specify the cidr of your shared VPC(i.e. Dev_vpc). In our example we use cidr: `10.2.0.0/16`
Provide your pull secret that you downloaded earlier from cloud.redhat.com. Provide your ssh public key that you
generated earlier.
4. Backup `install-config.yaml` file. The file will be consumed and transformed into installation artifacts  
`$ cp install-config.yaml ~/install-config.yaml.backup`  
5. Make sure you are in the directory where `install-config.yaml` is located.
6. Verify you're logged in with the correct AWS credentials:  
` $ aws sts get-caller-identity`  
 Create cluster manifests  
`$ openshift-install create manifests --dir=<path to your clusterconfigs dir>`
7. Remove manifests for **Control** machines  
    ```
    rm -f ~/clusterconfigs/openshift/99_openshift-cluster-api_master-machines-*.yaml
    ```
      
8. Verify that the `mastersSchedulable` parameter in `~/clusterconfigs/manifests/cluster-scheduler-02-config.yml`
file is set to `false`.
9. Create ignition bootstrap files:  
    `$ openshift-install create ignition-configs --dir=<path to your clusterconfigs dir>`  

    You should see `*.ign` files and an `auth` directory are created

10. Extract the infrastructure name  
    `$ jq -r .infraID ~/clusterconfigs/metadata.json`  
    Please save `infraID`. In our example it will be `seaocp-2mtml`

### C. Creating a private DNS zone.

_Why are we doing this?_ Due to the recent changes to AWS it's no longer possible to associate a private VPC (shared) from 
`Account A` to a private Hosted Zone in `Account B`. This change will prevent OpenShift ingress operator from creating
Private Hosted Zone required for OpenShift to operate. In the future versions of OpenShift it might be possible to use
the existing Private Hosted Zone but is not supported in v.4.7.

1. Log in as Account Organization Admin and then switch roles. For the `Account` specify the accountID 
of `OpenShiftInstaller` account and for the `Role` type in `PBMMAccel-PipelineRole` 
 ![Alt text](images/assume-role.png?raw=true "Assume Role")	
2. Create a temporary vpc in your OpenShift install account
 ![Alt text](images/create_vpc.png?raw=true "Create VPC")	
3. Create a private DNS zone in the format  

     `<cluster_name>.<base_domain>  `
 
	Zone name should match the cluster name we provided in `install-config.yaml` file. In our example it will be:
	`seaocp.octank-demo.ca`. Select the temp VPC that we created in step #2.  
	Apply the TAGs in the following format:  
    ```
    Key: "kubernetes.io/cluster/{infraID}" Value: "owned"
    Key: "Name" Value: {infraID}-int
    ```

    ![Alt text](images/p_dns_1.png?graw=true "DNS 1")	
    ![Alt text](images/p_dns_2.png?raw=true "DNS 2")	
 
4. We will need to create a VPC association for DNS with our existing shared VPC.
Refer to [AWS documentation.](https://aws.amazon.com/premiumsupport/knowledge-center/private-hosted-zone-different-account/)

    1. Switch back to OpenShiftInstaller account and connect to your running EC2 instance where we had AWS cli installed
and run the following commands:
    ```
    $ aws route53 list-hosted-zones 
    $ aws route53 create-vpc-association-authorization --hosted-zone-id /hostedzone/Z027XXXXXXXX --vpc VPCRegion=ca-central-1,VPCId=vpc-09820xxxxx 
    ```  
    **__NOTE:__**
    * `VPCId` - is your existing private VPC shared from another account  
    * `hosted-zone-id` - is the id of your private hosted zone

6. Approve the association using the role that has permission to run Route 53 APIs in the Account.
In our example we use `SharedNetwork` account to approve it. 
   ![Alt text](images/shared-network.png?raw=true "Shared Network Account")
   We can simply set environment variables on your EC2 instance
to do that.
    ```
    $ export AWS_ACCESS_KEY_ID="ASIXXXXXXX"
    $ export AWS_SECRET_ACCESS_KEY="XXXXXXXXXX"
    $ export AWS_SESSION_TOKEN="FXXXSSDFXXXXX"
    ```  
    ```$ aws route53 associate-vpc-with-hosted-zone --hosted-zone-id /hostedzone/Z027XXXXXXXX --vpc VPCRegion=ca-central-1,VPCId=vpc-09820xxxxx```
7. You can now delete the temp VPC. 
   1. Go to edit your Private Hosted Zone and remove `temp` VPC from the Associated list. You should have your shared VPC
    be still shown.
   2. Delete `temp` VPC. You will need to login with the account that created OR have permissions to delete this VPC in order to delete it.   
    **__NOTE:__** that `VPCId` is now the id of the temp network. 

8. **IMPORTANT:** Exit EC2 session manager to remove ENV variables we just added

## D. Updating SCP
### Pre-requirements
* You created an IAM user to run the installation (i.e.OpenShiftInstallUser)
* You created ignition configuration files for OpenShift
* You have the `infraID` for your future cluster
* You have the ARN for the `OpenShiftInstallUser` 

### Updating the policy
Download the latest `ASEA-Guardrails-Sensitive.json` policy from the [Official AWS Sea Repo](https://github.com/aws-samples/aws-secure-environment-accelerator/tree/main/reference-artifacts/SCPs).
Note: _file name might be different for the future releases of SEA. The sample of updated policy for this example
can be located [here](./scps/Sample.ASEA-Guardrails-Sensitive.json).

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
   (i.e. ` "central-bucket": "sea-aws-redhat-config"`). Select the `scp` directory. If you don't have this directory,
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
* You have 3 App and 3 Web subnets in your PBMM environment
* You completed all previous steps
* You have your `infraID` parameter value

The `artifacts` directory of this repository contains the following:
 * CloudFormation templates (.yaml)
 * Parameter Files (.json) 
 * Executable scripts (.sh)

You should not normally need to change any of the provided CloudFormation templates.  
Your environment parameters will be specified in the corresponding `.json` file. These templates need to be run in the 
specific order outlined here. For the full explanation of the parameter values please refer to [OpenShift Documentation](https://docs.openshift.com/container-platform/4.7/installing/installing_aws/installing-aws-user-infra.html)

### OpenShift Installation
1. Login to AWS Management Console using `OpenShiftInstaller` account and connect to the Session Manager of EC2
that you set up to run OpenShift installation
![Alt text](images/aws-session-manager.png?raw=true "Verify SCP")
   
2. Verify your AWS identity  
   
    ![Alt text](images/aws-caller-identity.png?raw=true "Verify AWS Identity")
 
3. Switch to the `aws_protectedb_openshift/artifacts` directory. (_This is the directory you cloned from Git_).
    ![Alt text](images/artifacts-dir.png?raw=true "Verify AWS Identity")
   
4. Create Network Components 
   1. Update `NetworkParams.json` file according to your environment. **__Where:__** `HostedZoneId` is your public Route 53
      Zone and `IntDns` is your Private Route 53 zone we created earlier. We chose `App_Dev_azX_net` as our PrivateSubnet
      and `Web_Dev_azX_net` as our Public Subnets.
      
   2. Run the Network script  
       `$ ./CreateOpenshiftNetwork.sh`
       
   3. Wait until `OpenShiftNetwork` stack is completed. You can also use AWS Web-UI to check for progress.

5. Create Security Groups
   1. Update `SGParams.json` file according to your environment    
   2. Run: `$ ./CreateSG.sh`
   3. Wait until `OpenShiftSecurityGroups` stack is completed
    
6. Upload your boostrap config file to an AWS S3 bucket
    1. Create an AWS S3 bucket  
    `$ aws s3 mb s3://<cluster-name>-infra`
    2. Copy boostrap.ign file to the bucket. `boostrap.ign` file can be located in the `~/clusterconfigs` directory  
    `$ aws s3 cp ~/clusterconfigs/bootstrap.ign s3://<cluster-name>-infra/bootstrap.ign`
    3. Verify the file has been uploaded  
    `$ aws s3 ls s3://<cluster-name>-infra`
       
7. Create Bootstrap Node
   1. Update `BootstrapParams.json` file according to your environment. You will need the values from the outputs
   of `Network` and `Security Groups` stacks. You can use AWS Web Console to retrieve them.
   3. Run: `$ ./CreateBootstrap.sh`
   4. Wait until `OpenShiftBootstrapNode` Stack is completed
    
8. Create Control Plane Nodes.
    1. Update `ControlPlaneParams.json`. You will need the values from the outputs
   of `Network` and `Security Groups` stacks. `CertificateAuthorities` can be retrieved 
       from `master.ign` file by copying the `"data:text/plain..."` section
    2. Run `$ ./CreateControlPlane.sh` 
    4. Wait until the Stack is completed
    
9. Switch to `clusterconfigs`directory and run:  
    ```
    $ cd ~/clusterconfigs
    $ openshift-install wait-for bootstrap-complete --dir=<path to your clusterconfigs dir> 
    ```
    Once you see the message that Boostrap is completed you can delete Bootstrap EC2 instance  
    ![Alt text](images/bootstrap-completed.png?raw=true "Bootstrap Completed")
    `$ aws cloudformation delete-stack --stack-name OpenShiftBootstrapNode` 
   
11. Login to OpenShift via CLI. 
    Make sure you have downloaded 'oc' cli tool.
    ```
    $ export KUBECONFIG=~/clusterconfigs/auth/kubeconfig  
    $ oc whoami
    ```  
    ![Alt text](images/ocwhoami.png?raw=true "Verify you logged in to OpenShift via CLI")
10. Create Compute Nodes. In this example we utilize OpenShift MachineSets to create compute nodes. MachineSets should
    have already been created during the installation process. You can also create your own MachineSets using
    [machineSets/machineSet.yaml](machineSets/machineSet.yaml) template
    
    1. Verify that you have 3 MachineSets available:  
    
    `$ oc get machinesets -n openshift-machine-api`  
    
    ![Alt text](images/default-machinesets.png?raw=true "MachineSets")
    
    2. Before updating your MachineSets you will need the values for:
        * 'WorkerInstanceProfile' from the OpenShiftSecurityGroups CloudFormation stack output 
        * 'WorkerSecurityGroupId' from the OpenShiftSecurityGroups CloudFormation stack output
        * CoreOS `ami` for your region. You can obtain the latest AMI [here](https://docs.openshift.com/container-platform/latest/installing/installing_aws/installing-restricted-networks-aws.html#installation-aws-user-infra-rhcos-ami_installing-restricted-networks-aws)
        * Names of your Compute subnetes i.e. App_Dev_aza_net, App_Dev_azb_net, App_Dev_azd_net
       
       We will be editing 3 MachineSets one per availability zone. Please make sure you select the correct subnet based 
       on the MachineSet you are editing. Edit each of the existing MachineSets one-by-one and update the following:
    
        `$ oc edit machineset <machineset name> -n openshift-machine-api`
    ```
    spec:
      metadata:
        labels: <-- add me
          node-role.kubernetes.io/worker: ""    <-- add me
      providerSet: ...
    ``` 
    ```
          iamInstanceProfile:
            id: OpenShiftSecurityGroups-WorkerInstanceProfile-ZXXXX <-- replace me with WorkerInstanceProfile
    ```      

    ```
      providerSpec:
        value:
          ami:
            id: ami-01284e5815ce66a95 <-- replace me
    ```
    ```
          securityGroups:
            - filters:
                - name: group-id <-- use group-id istead of tag:Name
                  values:
                    - sg-0180e9c119047e8b7 <-- replace me
          subnet:
            filters:
              - name: tag:Name
                values:
                  - App_Dev_aza_net <-- replace me based on AZ   
    ```
    **__NOTE:__** You can refer to [this sample](machineSets/machineSet-1a.example.yaml)
  
    3. Scale your MachineSets by running:  
    `oc scale --replicas=1 machineset <machineset name> -n openshift-machine-api`  
       Repeat for the remaining 2 MachineSets
    4. After a few minutes you should see compute machines being created.
     ![Alt text](images/compute-machines.png?raw=true "Compute Machines")
    5. Verify that you have 3 Control (Master) and 3 Compute (Worker) nodes
    ![Alt text](images/all-nodes-completed.png?raw=true "All Nodes Completed")

    
11. Verify that all the cluster operators are `Running` and are NOT in `Degraded` state `$ oc get co`  
    
    ![Alt text](images/operators-ready.png?raw=true "Operators are healthy")

12. Complete the installation. Please save your `kubeadmin` password!  

`$ openshift-install wait-for install-complete --dir=<path to your clusterconfigs dir>`

##Next Steps

* [Route external Application traffic into the cluste](./Route_External_Traffic.md)