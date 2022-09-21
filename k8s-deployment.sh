#!/bin/bash

sed -i 's#replace#iamharryindoc/numeric-app:${GIT_COMMIT}#g' k8s_deployment_service.yaml
#kubectl -n default get deployment ${deploymentName} > /dev/null
kubectl apply -f k8s_deployment_service.yaml