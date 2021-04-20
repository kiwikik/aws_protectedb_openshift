## Getting started with OpenShift on AWS Secure Environment Accelerator (ASEA)
This repository is developed to help you get started with Red Hat OpenShift on AWS Secure Environment Accelerator.

1. [Installing OpenShift cluster](Installing_OpenShift_SEA.md)
2. [Configure MachineSets](Configure_machinesets.md)
3. [Route external traffic to your applications](Route_External_Traffic.md)

### What is Openshift?
OpenShift is a family of containerization software products developed by Red Hat. Its flagship product is the
OpenShift Container Platform — a platform as a service built around Docker containers orchestrated and
managed by Kubernetes on a foundation of Red Hat Enterprise Linux. RedHat has an open source variant of
OS called OKD that we can assume will not be of interest to customers because it does not come with
RedHat support.
Read more:
* https://www.openshift.com/
* https://www.okd.io/
### As an AWS Customer how do I consume OpenShift?
For AWS customers that are 3 different ways to use this project.
Customer Managed: Customer uses RedHat provided installers to install OCP on AWS. The customer
has two options IPI (Terraform based) or UPI (CloudFormation based) installer. Customer is
responsible for the maintenance of the OCP cluster.
OpenShift Dedicated: OSD is a RedHat offering. RedHat provides OCP as a managed service. RedHat
runs OSD on their own AWS infrastructure.
RedHat OpenShift on AWS: New joint offering from AWS and RedHat. Customer enables ROSA in
their account and uses the ROSA cli to provision a fully managed OCP cluster.
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
**__Note__**: that you must update your ASEA config.json to deploy 3 AZ in your shared VPCs for OpenShift. As
deployed, your OpenShift cluster architecture will look like this:
 ![Alt text](images/aws-architecture.png?raw=true "AWS Architecture")

### Why are we interested in deploying OCP on AWS with ASEA?
Customers want the ability to deploy containerized applications in hybrid environments. Customers can
open a new AWS Management account, deploy the ASEA and have the 12 guardails in place within a day.
Documenting how to install OCP on top of ASEA gets the customer that much closer to being able to deploy
containerized applications and obtain and Authority to Operate (ATO) against Canada's Protect B Medium
Medium security profile.

### What has been tested by CANPS AWS and RedHat?
OCP version: 4.7 ASEA version: 1.3.2 OCP Deployment Method: UPI
Getting started on deploying OpenShift using the UPI installer on AWS with PBMM guardrails
provided by ASEA.
For the purposes of this document, we assume that you have a standard ASEA proscribed architecture as
defined [here](https://github.com/aws-samples/aws-secure-environmentaccelerator/blob/main/docs/operations/img/ASEA-high-level-architecture.png)
It is assumed you have deployed ASEA following the instructions in the [installation documentation](https://github.com/aws-samples/aws-secure-environmentaccelerator/blob/main/docs/installation/installation.md)