#!/bin/sh

pushd ..

#----------------------------------------- HTTPBin API Product -----------------------------------------

printf "\nDelete the HTTPBin HTTPRoute (delegatee) and the HTTP APIProduct ...\n"
kubectl delete -f referencegrants/httpbin-ns/portal-gloo-system-apiproduct-rg.yaml
kubectl delete -f apiproducts/httpbin/httpbin-apiproduct.yaml
kubectl delete -f apiproducts/httpbin/httpbin-apiproduct-httproute.yaml

printf "\nDelete HTTPBin APISchemaDiscovery ...\n"
kubectl delete -f apis/httpbin/httpbin-apischemadiscovery.yaml

printf "\nDelete HTTPBin service ...\n"
kubectl delete -f apis/httpbin/httpbin.yaml

kubectl delete ns httpbin

popd

