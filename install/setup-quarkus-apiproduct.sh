#!/bin/sh

pushd ..

#----------------------------------------- Quarkus API Product -----------------------------------------

kubectl create namespace quarkus --dry-run=client -o yaml | kubectl apply -f -

printf "\nDeploy Quarkus service ...\n"
kubectl apply -f apis/quarkus/quarkus.yaml
# kubectl apply -f apis/quarkus/quarkus-apischemadiscovery.yaml

printf "\nDeploy the Quarkus HTTPRoute (delegatee) and the Quarkus APIProduct ...\n"
kubectl apply -f apiproducts/quarkus/quarkus-apiproduct-httproute.yaml
kubectl apply -f apiproducts/quarkus/quarkus-apiproduct.yaml

kubectl apply -f referencegrants/quarkus-ns/portal-quarkus-apiproduct-reference-grant.yaml

#----------------------------------------- api.example.com route -----------------------------------------

printf "\nDeploy the api.example.com HTTPRoute ...\n"
kubectl apply -f routes/api-example-com-root-httproute.yaml

popd

