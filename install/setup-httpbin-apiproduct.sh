#!/bin/sh

pushd ..

#----------------------------------------- HTTPBin API Product -----------------------------------------

# Create httpbin namespace if it does not exist yet
kubectl create namespace httpbin --dry-run=client -o yaml | kubectl apply -f -

printf "\nDeploy HTTPBin service ...\n"
kubectl apply -f apis/httpbin/httpbin.yaml

printf "\nDeploy HTTPBin APISchemaDiscovery ...\n"
kubectl apply -f apis/httpbin/httpbin-apischemadiscovery.yaml

printf "\nDeploy the HTTPBin HTTPRoute (delegatee) and the HTTP APIProduct ...\n"
kubectl apply -f apiproducts/httpbin/httpbin-apiproduct-httproute.yaml
kubectl apply -f apiproducts/httpbin/httpbin-apiproduct.yaml
kubectl apply -f referencegrants/httpbin-ns/portal-gloo-system-apiproduct-rg.yaml

#----------------------------------------- api.example.com route -----------------------------------------

printf "\nDeploy the api.example.com HTTPRoute ...\n"
kubectl apply -f routes/api-example-com-root-httproute.yaml

popd

