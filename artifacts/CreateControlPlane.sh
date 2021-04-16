#!/bin/sh
aws cloudformation create-stack --stack-name OpenShiftControlPlane --parameters file://ControlPlaneParams.json --template-body file://ControlPlaneTemplate.yaml --capabilities CAPABILITY_NAMED_IAM
while true; do aws cloudformation describe-stacks --stack-name OpenShiftControlPlane; sleep 5; done