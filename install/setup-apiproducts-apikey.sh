#!/bin/sh

pushd ..

#----------------------------------------- ApiProducts - OAuth -----------------------------------------

kubectl apply -f policies/authconfigs/apiproducts-apikey-portalauth-authconfig.yaml
kubectl apply -f policies/ratelimitconfigs/apiproducts-dynamic-rl.yaml
kubectl apply -f policies/routeoptions/routeoption-apiproducts-apikey.yaml

# kubectl apply -f routes/api-example-com-root-httproute-portalauth-apikey.yaml

popd

