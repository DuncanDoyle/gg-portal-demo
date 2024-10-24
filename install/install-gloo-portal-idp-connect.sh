#!/bin/sh

source ./env.sh

#----------------------------------------- Install the IPDConnect component that integrate Portal with Keycloak for dynamic OAuth client registration -----------------------------------------
printf "\nInstall Gloo Portal IDP connector ...\n"
helm repo add gloo-portal-idp-connect https://storage.googleapis.com/gloo-mesh-enterprise/gloo-portal-idp-connect

helm upgrade -i -n gloo-system \
  portal-idp gloo-portal-idp-connect/gloo-portal-idp-connect \
  --version 0.0.0-dev-remove-api-products-from-idp-79268a3 \
  -f -<<EOF
connector: keycloak
keycloak:
  realm: http://keycloak.keycloak.svc.cluster.local/realms/portal-mgmt
  mgmtClientId: gloo-portal-idp
  mgmtClientSecret: gloo-portal-idp-secret
EOF

# Wait for the rollout to finish
kubectl -n gloo-system rollout status deploy gloo-portal-idp-connect

# #----------------------------------------- Update Portal to integrate with the IDP Connector -----------------------------------------
# printf "\nInstalling Gloo Gateway $GLOO_GATEWAY_VERSION ...\n"
# if [ "$DEV_VERSION" = false ] ; then
#   helm upgrade -i -n gloo-system \
#     gloo glooe/gloo-ee \
#     --create-namespace \
#     --version $GLOO_GATEWAY_VERSION \
#     --set-string license_key=$GLOO_GATEWAY_LICENSE_KEY \
#     --reuse-values \
#     -f -<<EOF
# gateway-portal-web-server:
#   enabled: true
#   glooPortalServer:
#     idpServerUrl: http://idp-connect.gloo-system.svc.cluster.local
# EOF
# else
#   helm upgrade -i -n gloo-system \
#     gloo gloo-ee-test/gloo-ee \
#     --create-namespace \
#     --version $GLOO_GATEWAY_VERSION \
#     --set-string license_key=$GLOO_GATEWAY_LICENSE_KEY \
#     --reuse-values \
#     -f -<<EOF
# gateway-portal-web-server:
#   enabled: true
#   glooPortalServer:
#     idpServerUrl: http://idp-connect.gloo-system.svc.cluster.local
# EOF
# fi
# printf "\n"

# # Wait for the rollout to finish
# kubectl -n gloo-system rollout status deploy gateway-portal-web-server