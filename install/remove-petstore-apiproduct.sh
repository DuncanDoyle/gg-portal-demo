#!/bin/sh

pushd ..

#----------------------------------------- Petstore API Product -----------------------------------------

printf "\nDelete the Petstore HTTPRoutes (delegatee) and the HTTP APIProduct ...\n"
kubectl delete -f referencegrants/petstore-ns/portal-gloo-system-apiproduct-rg.yaml
kubectl delete -f apiproducts/petstore/petstore-apiproduct-httproute.yaml
kubectl delete -f apiproducts/petstore/petstore-apiproduct.yaml

printf "\nDelete Petstore services ...\n"
kubectl delete -f apis/petstore/pets-api.yaml
kubectl delete -f apis/petstore/store-api.yaml
kubectl delete -f apis/petstore/users-api.yaml

kubectl delete ns petstore

popd