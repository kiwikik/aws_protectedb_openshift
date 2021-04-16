## Installing OpenShift into an SEA

### Pre-requisites:
* You have a SEA environment v.1.3.2 or later 
* You have account organization admin access to this environment
* You have created your SEA environment with 3 availability zones
* You have a Red Hat account
* You are familiar with OpenShift user-provisioned infrastructure installation process

We have created a dedicated OpenShift Account called `OpenShiftInstaller` during the provisioning process of PBMM. We 
will be using this account to install Red Hat OpenShift v.4.7 into AWS Protected B environment.
You can choose to create a new account or use one of the existing SEA accounts (i.e. DEV). 

## A. Preparing for installation
1. Log into your aws account using Account Administrator role. In this example
we use SSO to easily switch between accounts

2. Assume Pipeline Role. provide Pipeline role name: PBMMAccel-PipelineRole and your the account ID of
the account that will be used to install OpenShift. In our example we use the ID of OpenShift install account.

3. Go to IAM and create a user that will be used to install openshift. In this example we call it OpenShiftInstallUser
  3a. Allow programatic access
  3b. Attach existing policy "AdministratorAccess" ^1
  3c. Record access key id and secret access key
  AKIAZIY5DBAK66NTD4P3 / +8XWe5ox5ro8yNTNZyN5Fm/mB7v0quCHgkY8TqoE NOTE^1: you can create your own role following the official documentation for Red Hat OpenShift

4. Login to OpenShift Account and verify that user was created and have the appropriate role

5. In openshift account create a public DNS zone. Note this zone is used for the installer
and will not be publicly resolved. See post-installation step on how to allow external traffic
to your cluser. In our example we use: octank-demo.ca

6. Create a small EC2 instance. It will be used to install OpenShift. In our example we use t2.xlarge but smaller instances
should work as well. The operating system type should be AWS Linux or RHEL. NOTE: if you choose RHEL you might need to isntall
management utils. They are needed in order to be able to connect to the remote shell

7. In your web-browser go to cloud.redhat.com and log in with your Red Hat credentials
7a. In Red Hat OpenShift Cluster Manager click Cluster Manager link
7b. Select create cluster. In "Run It Yourself" section select AWS and then user-provisioned infrastructure
7c. On the screen copy links for the latest version of OpenShift installer, Command line interface
7d. Download and save the pull secret. It will be used to pull images from internal red hat registries
https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-install-linux.tar.gz
https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux.tar.gz
7e. Close this tab

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

11. Clone the current git current repository
`$ git clone THIS_REPO
`
12. Create a folder for storing OpenShift configuration. We call ours "clusterconfigs".
### B. Generate OpenShift cluster configs
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

### C. Create a private DNS zone.
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

## D. Update SCP



## E. Installing OpenShift

