#!/bin/sh

pushd ..

#----------------------------------------- Petstore API Product -----------------------------------------

# Create httpbin namespace if it does not exist yet
kubectl create namespace petstore --dry-run=client -o yaml | kubectl apply -f -

printf "\nDeploy Petstore services ...\n"
kubectl apply -f apis/petstore/pets-api.yaml
kubectl apply -f apis/petstore/store-api.yaml
kubectl apply -f apis/petstore/users-api.yaml

printf "\nDeploy the Petstore HTTPRoutes (delegatee) and the HTTP APIProduct ...\n"

kubectl apply -f referencegrants/petstore-ns/portal-gloo-system-apiproduct-rg.yaml
kubectl apply -f apiproducts/petstore/petstore-apiproduct-httproute.yaml
kubectl apply -f apiproducts/petstore/petstore-apiproduct.yaml

#----------------------------------------- api.example.com route -----------------------------------------

printf "\nDeploy the api.example.com HTTPRoute ...\n"
kubectl apply -f routes/api-example-com-root-httproute.yaml

popd

