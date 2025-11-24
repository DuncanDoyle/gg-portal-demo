#!/bin/sh

pushd ..

#----------------------------------------- ApiProducts - Remove RouteOption (AuthN/AuthZ/RL) -----------------------------------------

kubectl -n gloo-system delete routeoption routeoption-apiproducts

popd

