#!/bin/sh

pushd ..

#----------------------------------------- Lambda API Product -----------------------------------------

# Label the default namespace, so the gateway will accept the HTTPRoute from that namespace.
printf "\nLabel default namespace ...\n"
kubectl label namespaces default --overwrite shared-gateway-access="true"

printf "\nDeploy Lambda Upstream ...\n"
kubectl apply -f upstreams/lambda-upstream.yaml

printf "\nDeploy Lambda APISchemaDiscovery ...\n"
kubectl apply -f apis/lambda/lambda-apischemadiscovery.yaml

printf "\nDeploy the Lambda HTTPRoute and Lambda APIProduct ...\n"
kubectl apply -f apiproducts/lambda/lambda-apiproduct-httproute.yaml
kubectl apply -f apiproducts/lambda/lambda-apiproduct.yaml

#----------------------------------------- api.example.com route -----------------------------------------

printf "\nDeploy the api.example.com HTTPRoute ...\n"
kubectl apply -f routes/api-example-com-root-httproute.yaml

popd

