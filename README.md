## Getting started with OpenShift on AWS Secure Environment Accelerator (ASEA)
This repository is developed to help you get started with Red Hat OpenShift on AWS Secure Environment Accelerator.

1. [Installing OpenShift cluster](Installing_OpenShift_SEA.md)
2. [Route external traffic to your applications](Route_External_Traffic.md)
3. [Installing OpenShift Container Storage (OCS 4.x)](Install_ocs.md)

### What is Openshift?
OpenShift is a family of containerization software products developed by Red Hat. Its flagship product is the
OpenShift Container Platform — a platform as a service built around container orchestration and
managed by Kubernetes on a foundation of Red Hat Enterprise Linux. Red Hat sponsors an open source version (community) of
OpenShift called OKD which does not come with Red Hat support.
Read more:
* https://www.openshift.com/
* https://www.okd.io/
### As an AWS Customer how do I consume OpenShift?
For AWS customers there are 3 different ways to use OpenShift on AWS.
* Customer Managed: Customer uses Red Hat provided installers to install OpenShift on AWS. The customer
has two options IPI (Terraform based) or UPI (CloudFormation based) installer. Customer is
responsible for the maintenance of the OpenShift cluster.
* OpenShift Dedicated (OSD): is a Red Hat offering. Red Hat provides OpenShift as a managed service. Red Hat
runs OSD on their own AWS infrastructure.
* Red Hat OpenShift on AWS (ROSA): New joint offering from AWS and Red Hat. Customer enables ROSA in
their account and uses the ROSA cli to provision a fully managed OpenShift cluster.
### What is the AWS Secure Environment Accelerator (ASEA)?
The AWS Accelerator is a tool designed to help deploy and operate secure multi-account, multi-region AWS
environments on an ongoing basis. The power of the solution is the configuration file that drives the
architecture deployed by the tool. This enables extensive flexibility and for the completely automated
deployment of a customized architecture within AWS without changing a single line of code.
While flexible, the AWS Accelerator is delivered with a sample configuration file which deploys an
opinionated and prescriptive architecture designed to help meet the security and operational requirements
of many governments around the world (initial focus was the Government of Canada). Tuning the
parameters within the configuration file allows for the deployment of customized architectures and enables
the solution to help meet the multitude of requirements of a broad range of governments and public sector
organizations.
The installation of the provided prescriptive architecture is reasonably simple, deploying a customized
architecture does require extensive understanding of the [AWS platform](https://github.com/aws-samples/aws-secure-environment-accelerator).  
**__NOTE:__** you must update your ASEA `config.json` to deploy three availability zones (AZ) in your shared VPCs for OpenShift. As
deployed, your OpenShift cluster architecture will look like this:
 ![Alt text](images/aws-architecture.png?raw=true "AWS Architecture")

### Why are we interested in deploying OpenShift on AWS with ASEA?
Customers want the ability to deploy containerized applications in hybrid environments. Customers can
open a new AWS Management account, deploy the ASEA and have the 12 guardails in place within a day.
Documenting how to install OpenShift on top of ASEA gets the customer that much closer to being able to deploy
containerized applications and obtain and Authority to Operate (ATO) against Canada's Protect B Medium security profile.

### What has been tested by CANPS AWS and Red Hat?
* OpenShift version 4.7, ASEA version: 1.3.2  
* OpenShift Deployment Method: UPI  

For the purposes of this document, we assume that you have a standard ASEA proscribed architecture as
defined below
![Alt text](https://github.com/aws-samples/aws-secure-environment-accelerator/blob/main/docs/operations/img/ASEA-high-level-architecture.png?raw=true "AWS PBMM")

It is assumed you have deployed ASEA following the instructions in the [installation documentation](https://github.com/aws-samples/aws-secure-environment-accelerator/blob/main/docs/installation/installation.md)