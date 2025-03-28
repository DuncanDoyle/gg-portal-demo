#!/bin/sh

pushd ..

#----------------------------------------- ApiProducts - OAuth -----------------------------------------

# kubectl apply -f policies/opa/portal-opa-cm.yaml
kubectl apply -f policies/authconfigs/apiproducts-atv-portalauth-authconfig.yaml
kubectl apply -f policies/ratelimitconfigs/apiproducts-dynamic-rl.yaml
kubectl apply -f policies/routeoptions/routeoption-apiproducts-oauth.yaml

# kubectl apply -f routes/api-example-com-root-httproute-oauth.yaml

popd

