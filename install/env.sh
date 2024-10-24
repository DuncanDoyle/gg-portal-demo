#!/bin/bash

export K8S_GATEWAY_API_VERSION=v1.0.0

# export GLOO_GATEWAY_VERSION="1.18.0-beta2-bmain-4f950f1"
export GLOO_GATEWAY_VERSION="1.18.0-beta2-bportal-remove-idp-apiProduct-calls-7e61db4"
# export GLOO_GATEWAY_VERSION="1.17.0"
export DEV_VERSION=true
export GLOO_GATEWAY_HELM_VALUES_FILE="gloo-gateway-helm-values.yaml"

export GATEWAY_NAMESPACE=gloo-system

# export GATEWAY_HOST=api.example.com
export PORTAL_HOST=developer.example.com
export PARTNER_PORTAL_HOST=developer.partner.example.com
export KEYCLOAK_HOST=keycloak.example.com
export KC_ADMIN_PASS=admin

# export API_ANALYTICS_ENABLED=true
export BACKSTAGE_ENABLED=false