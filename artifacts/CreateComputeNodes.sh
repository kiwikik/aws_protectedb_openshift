#!/bin/sh
aws cloudformation create-stack --stack-name OpenShiftComputeNodes--parameters file://ComputeNodeParams.json --template-body file://ComputeNodeTemplate.yaml
while true; do aws cloudformation describe-stacks --stack-name OpenShiftComputeNodes; sleep 5; done