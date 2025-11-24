# Monitoring


## Kube Prometheus Stack

Install Prometheus Operator

```
cd monitoring-stack/prometheus
./install-kube-prometheus-stack.sh
```

Check installation:

```
kubectl --namespace monitoring get pods -l "release=kube-prometheus-stack"
```

Access Prometheus UI:

```
kubectl -n monitoring port-forward svc/kube-prometheus-stack-prometheus 9090:9090
```