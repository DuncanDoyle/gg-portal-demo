#!/bin/sh

pushd ..

#----------------------------------------- Portal-Postgres -----------------------------------------

kubectl apply -f portal/portal-db-pv.yaml
kubectl apply -f portal/portal-postgres-secret.yaml
kubectl apply -f portal/portal-postgres.yaml

export POSTGRES_CONNECTION_URL=$(printf "dsn: host=portal-postgres.gloo-system.svc.cluster.local port=5432 user=user password=pass dbname=db sslmode=disable" | base64)

kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: portal-database-config
  namespace: gloo-system
type: Opaque
data:
  config.yaml: |
    $POSTGRES_CONNECTION_URL
EOF

popd

