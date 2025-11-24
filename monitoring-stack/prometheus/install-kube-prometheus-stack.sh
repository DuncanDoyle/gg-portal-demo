#!/bin/sh

export KUBE_PROMETHEUS_STACK_CHART_VERSION="62.6.0"
export KUBE_PROMETHEUS_STACK_HELM_VALUES_FILE="kube-prometheus-stack-helm-values.yaml"

helm upgrade --install kube-prometheus-stack \
    prometheus-community/kube-prometheus-stack \
    --version $KUBE_PROMETHEUS_STACK_CHART_VERSION \
    --namespace monitoring \
    --create-namespace \
    -f $KUBE_PROMETHEUS_STACK_HELM_VALUES_FILE