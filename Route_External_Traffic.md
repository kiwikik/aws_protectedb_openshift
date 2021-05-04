## Route External Application Traffic (ingress)

In this section we are going to route external (outside your AWS VPC) application
traffic to OpenShift compute nodes. The architectural diagram is shown below.

![Alt text](images/external-traffic-arhitecture.png?raw=true "Architecture")

## A. Configure AWS Load Balancer
Log in as an administrator into an AWS `Perimeter` account.
### Pre-reqs
* Obtain your Private IP addresses for both of your Firewall instances. It's the Private IPv4 address of the ENI that
also has a Public IP address associated to it.
  

1. Create a new Target Group as follows:
    1. Choose a target type: IP addresses
    2. Protocol: TCP
    3. Port: 443
    4. VPC: select your perimeter VPC
    5. Health check protocol: TCP
    6. Overwrite Health Check port to: 8008
       ![Alt text](images/tg-health-check.png?raw=true "AWS Target Group Health Check")
   Click NEXT. On the Register Targets screen
    1. Type in the IPs for Firewall A and Firewall B instances.
    2. Ports for the selected instances: 7043 (you can choose any other unused port of your choice)
    3. Click `Include as pending below`
    4. Click `Create Target Group`
2. Create a new Network Load Balancer
    ![Alt text](images/lb-info.png?raw=true "AWS Load Balancer")
    1. Scheme: Internet Facing
    2. IP address type: IPv4
    3. VPC: your perimeter VPC
    4. For mappings select both: `ca-central-1a` and `ca-central-1a`
    5. For subnets use: `Public_Perimeter_aza_net` and `Public_Perimeter_azb_net`
    5. Listener: TCP
    6. Listener Port: 443
    7. Forward to the target group you created in the previous step
    ![Alt text](images/lb-listener.png?raw=true "AWS Load Balancer Listener")
    8. Record the DNS name `lbDNSname`   
3. Verify the status of Registered Targets is `Healthy` 
![Alt text](images/tg-healthy.png?raw=true "AWS Target Group")


## B. Configure Fortinet Fortigate Firewall
Before you start. Login into the OpenShiftInstaller account. Go to `EC2` -> `Load Balancers` and 
record the DNS name of the internal OpenShift load balancer (AWS LB type: `classic`). You can identify it by
looking at the `Instances`. It should show your OpenShift compute nodes as targets. Record the value `internalLB`

1. Log in as an administrator to FW instance A
2. Switch your routing domain to `FG-traffic`  
   ![Alt text](images/route-domain.png?raw=true "Fortigate Route Domain")

3. Go to `Policy & Object` -> `Addresses` and either create or re-use one of the addresses. In this example we use one
   of the default SEA addresses which is called `Test1-ALB-FQDN`
   
4. Edit the address and replace the FQDN with the DNS name of the internal OpenShift load balancer (`internalLB`). 
   Change the interface to `any`
    ![Alt text](images/fw-address.png?raw=true "Fortigate Address")
5. In your Fortigate console go to `Policy & Object` -> `Virtual IPs` and create or re-use one of the existing addresses.  In this example we use one of the
default SEA addresses which is called `Test1-ALB`.
   
6. Edit your VIP as follows:
   1. External IP address: is the IP of your `public (port1)` Interface
   2. Mapped Address: Address from step.3 i.e. `Test1-ALB-FQDN`
   3. Protocol: TCP   
   4. Update your external service port to 7043
   5. Map to port: 443
   6. Save the changes
   7. Hoover over the VIP and record the IP values for the `Resolved To`.
       ![Alt text](images/fw-resolve-ip.png?raw=true "Fortigate Resolve IP")
7. Create or make sure you have a static route to the destinations recorded in step.6
   1. To verify go to `Monitor` -> `Routing Monitor` and make sure the subnet (`Resolved To`) has a gateway attached to it.
      ![Alt text](images/route-monitor.png?raw=true "Fortigate Route Monitor")

   2. If you do not have a gateway attached you will need to create a static route in `Network` -> `Static Routes`
8. Create a new Firewall policy
   1. Go to `Policy & Objects` -> `IPv4 Policy` and click `Create New`
   2. Incoming interface: `public(port1)` 
   3. Outgoing interface: `tgw-vpn1`   
   4. Source: ideally we'd use your two AZ ranges for the public subnets. But in our POC environment we use `all`
   5. Destination: will be your address. In our example it's `Test1-ALB`
   6. Service: HTTPS
   7. SSL inspection: no-inspection. We let OpenShift handle the SSL
   8. For NAT: Use Dynamic IP pool and choose `cluster-ippool`
   ![Alt text](images/fw-policy-example.png?raw=true "Fortigate Policy Example")
   **__NOTE:__** You might want to either upvote your policy or modify the other existing policies to exclude `Test1-ALB`.
Otherwise, Fortigate will present it's certificate instead of passing it to OpenShift
      
9. If added Firewall B to your target group then you must repeat the same steps for your Firewall B instance.

## C. Update your route 53
Add a wildcard CNAME in the format of *.apps.<cluster_name> and point it to the DNS of your ELB (`lbDNSname`).

   ![Alt text](images/public-dns-cname.png?raw=true "Public Hosted Zone")

## D. Verify

In your web-browser go to https://console-openshift-console.apps.<cluster_name>.<your_public_domain>
and verify that you can access OpenShift login screen

   ![Alt text](images/OpenShift-login.png?raw=true "Fortigate Policy Example")
