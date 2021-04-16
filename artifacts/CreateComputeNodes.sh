#!/bin/sh
aws cloudformation create-stack --stack-name OpenShiftComputeNode1 --parameters file://ComputeNodeParams.json --template-body file://ComputeNodeTemplate.yaml
while true; do aws cloudformation describe-stacks --stack-name OpenShiftComputeNode1; sleep 5; done