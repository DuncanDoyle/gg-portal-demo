#!/bin/sh

pushd ..



#----------------------------------------- ExtAuth -----------------------------------------

# kubectl apply -f policies/opa/oauth-scope-apiproduct-opa-cm.yaml
# kubectl apply -f policies/extauth/oauth-oidc-atv-authconfig.yaml

#----------------------------------------- Portal -----------------------------------------

# kubectl apply -f referencegrant/gloo-system-ns/httproute-portal-reference-grant.yaml
# kubectl apply -f referencegrant/gloo-system-ns/portal-reference-grant.yaml

kubectl apply -f policies/authconfigs/portal-apis-authconfig.yaml
kubectl apply -f policies/authconfigs/portal-authconfig.yaml

kubectl apply -f policies/routeoptions/routeoption-portal.yaml
kubectl apply -f policies/routeoptions/routeoption-portal-apis.yaml
kubectl apply -f policies/routeoptions/routeoption-portal-cors.yaml


kubectl apply -f portal/portal.yaml
kubectl apply -f portal/portal-frontend.yaml

kubectl apply -f routes/portal-server-httproute.yaml
kubectl apply -f routes/portal-frontend-httproute.yaml

popd
