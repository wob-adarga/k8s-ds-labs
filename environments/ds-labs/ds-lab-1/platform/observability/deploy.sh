#!/bin/bash

set -x
set -c

# quick and dirty setup of default in-cluster observability stack
# in lieu of working terraform for ds-labs which will replace it

# setup namespace

kubectl create ns observability
kubectl config set-context --current --namespace=observability

# prometheus; all defaults all the way

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add kube-state-metrics https://kubernetes.github.io/kube-state-metrics
helm repo update
helm install prometheus prometheus-community/prometheus

# grafana

helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm install grafana grafana/grafana --set persistence.enabled=true

# jaegar

helm repo add jaegertracing https://jaegertracing.github.io/helm-charts
helm repo update
helm install jaeger jaegertracing/jaeger --set cassandra.persistence.enabled=true
