#!/bin/bash

# export K8S_GATEWAY_API_VERSION=v1.1.0
export K8S_GATEWAY_API_VERSION=v1.2.1

export GLOO_GATEWAY_VERSION="1.19.8"
# export GLOO_GATEWAY_VERSION="1.18.8"
# export GLOO_GATEWAY_VERSION="1.17.5"

export DEV_VERSION=false
export GLOO_GATEWAY_HELM_VALUES_FILE="gloo-gateway-helm-values.yaml"

export GATEWAY_NAMESPACE=gloo-system

CLUSTER_NAME="gg-demo-single"
# GLOO_PLATFORM_VERSION="2.7.0-rc2"
GLOO_PLATFORM_VERSION="2.10.1"
GLOO_PLATFORM_HELM_VALUES_FILE="gloo-platform-helm-values.yaml"

# export GATEWAY_HOST=api.example.com
export PORTAL_HOST=developer.example.com
export PARTNER_PORTAL_HOST=developer.partner.example.com
export KEYCLOAK_HOST=keycloak.example.com
export KC_ADMIN_PASS=admin

# export API_ANALYTICS_ENABLED=true
export BACKSTAGE_ENABLED=true