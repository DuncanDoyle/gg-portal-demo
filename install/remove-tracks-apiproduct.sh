#!/bin/sh

pushd ..

#----------------------------------------- Tracks API Product -----------------------------------------

printf "\nDelete the Tracks HTTPRoute (delegatee) and the HTTP APIProduct ...\n"
kubectl delete -f apiproducts/tracks/tracks-apiproduct.yaml
kubectl delete -f apiproducts/tracks/tracks-v2-apiproduct-httproute.yaml
kubectl delete -f apiproducts/tracks/tracks-v1-apiproduct-httproute.yaml
kubectl delete -f apiproducts/tracks/tracks-httproute.yaml

printf "\nDelete Tracks service ...\n"
kubectl apply -f apis/tracks/tracks-api-1.0.yaml

kubectl delete -f referencegrants/tracks-ns/portal-tracks-apiproduct-reference-grant.yaml

kubectl delete ns tracks

popd

