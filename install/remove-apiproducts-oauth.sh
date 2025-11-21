#!/bin/sh

pushd ..

#----------------------------------------- ApiProducts - Remove OAuth -----------------------------------------

kubectl delete -f policies/routeoptions/routeoption-apiproducts-oauth.yaml
kubectl delete -f policies/ratelimitconfigs/apiproducts-dynamic-rl.yaml
kubectl delete -f policies/authconfigs/apiproducts-atv-portalauth-authconfig.yaml

popd

