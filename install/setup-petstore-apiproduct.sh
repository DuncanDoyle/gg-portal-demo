#!/bin/sh

pushd ..

#----------------------------------------- Petstore API Product -----------------------------------------

# Create httpbin namespace if it does not exist yet
kubectl create namespace petstore --dry-run=client -o yaml | kubectl apply -f -


printf "\nDeploy Petstore services ...\n"


printf "\nDeploy the Petstore HTTPRoutes (delegatee) and the HTTP APIProduct ...\n"

#----------------------------------------- api.example.com route -----------------------------------------

printf "\nDeploy the api.example.com HTTPRoute ...\n"
kubectl apply -f routes/api-example-com-root-httproute.yaml

popd

