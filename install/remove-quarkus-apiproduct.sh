#!/bin/sh

pushd ..

#----------------------------------------- Quarkus API Product -----------------------------------------

printf "\nDelete the Quarkus HTTPRoute (delegatee) and the Quarkus APIProduct ...\n"
kubectl delete -f apiproducts/quarkus/quarkus-apiproduct.yaml
kubectl delete -f apiproducts/quarkus/quarkus-apiproduct-httproute.yaml

printf "\nDelete Quarkus service ...\n"
kubectl delete -f apis/quarkus/quarkus-apischemadiscovery.yaml
kubectl delete -f apis/quarkus/quarkus.yaml

kubectl delete -f referencegrants/quarkus-ns/portal-quarkus-apiproduct-reference-grant.yaml

kubectl delete ns quarkus

popd

