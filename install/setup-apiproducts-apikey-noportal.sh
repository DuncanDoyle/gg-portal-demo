#!/bin/sh

pushd ..

#----------------------------------------- ApiProducts - APIKey without Portal -----------------------------------------

kubectl apply -f policies/authconfigs/apiproducts-apikey-authconfig.yaml
# kubectl apply -f policies/ratelimitconfigs/apiproducts-dynamic-rl.yaml
kubectl apply -f policies/routeoptions/routeoption-apiproducts-apikey-noportal.yaml

popd

