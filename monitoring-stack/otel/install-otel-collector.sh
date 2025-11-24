#!/bin/sh

# export OTEL_COLLECTOR_CHART_VERSION="0.106.1"
export OTEL_COLLECTOR_CHART_VERSION="0.126.0"
export OTEL_COLLECTOR_HELM_VALUES_FILE="otel-collector-helm-values.yaml"

helm upgrade --install opentelemetry-collector-gloo-gateway open-telemetry/opentelemetry-collector \
    --version $OTEL_COLLECTOR_CHART_VERSION \
    --namespace monitoring \
    --create-namespace \
    -f $OTEL_COLLECTOR_HELM_VALUES_FILE

kubectl rollout status -n monitoring deploy/opentelemetry-collector-gloo-gateway

kubectl apply -f otel-servicemonitor.yaml
