#!/bin/sh
aws cloudformation create-stack --stack-name OpenShiftSecurityGroups --template-body file://SGTemplate.yaml --parameters file://SGParams.json --capabilities CAPABILITY_NAMED_IAM
while true; do aws cloudformation describe-stacks --stack-name OpenShiftSecurityGroups; sleep 5; done