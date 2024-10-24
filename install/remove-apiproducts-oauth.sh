#!/bin/sh

pushd ..

#----------------------------------------- ApiProducts - Remove OAuth -----------------------------------------

# Revert the route to one without RouteOptions
kubectl apply -f routes/api-example-com-root-httproute.yaml

kubectl delete -f policies/routeoptions/routeoption-apiproducts-oauth.yaml
kubectl delete -f policies/ratelimitconfigs/apiproducts-dynamic-rl.yaml
kubectl delete -f policies/authconfigs/apiproducts-atv-opa-authconfig.yaml
kubectl delete -f policies/opa/portal-opa-cm.yaml

popd

