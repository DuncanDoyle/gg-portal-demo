#!/bin/sh

##################################################################
#
# Generates a Kubernetes secret with HTTPS certificate.
#
##################################################################

printf "\nTemp dir: $TMPDIR\n"

pushd $TMPDIR
mkdir tls
pushd tls

# Generate root cert
# root cert
printf "\nGenerate the root certificate.\n"
openssl req -new -newkey rsa:4096 -x509 -sha256 \
    -days 3650 -nodes -out root.crt -keyout root.key \
    -subj "/CN=*/O=root" \
    -addext "subjectAltName = DNS:*"

# server cert
printf "\nGenerate the server certificate.\n"
cat > "gateway.conf" <<EOF
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth, serverAuth
subjectAltName = @alt_names
[alt_names]
DNS = *
EOF

openssl genrsa -out "gateway.key" 2048
openssl req -new -key "gateway.key" -out gateway.csr -subj "/CN=*/O=gateway" -config "gateway.conf"

printf "\nSign the server certificate.\n"
openssl x509 -req \
  -days 3650 \
  -CA root.crt -CAkey root.key \
  -set_serial 0 \
  -in gateway.csr -out gateway.crt \
  -extensions v3_req -extfile "gateway.conf"


# Create HTTPS K8S secret
printf "\nCreate the K8S HTTPS secret.\n"
kubectl create secret generic https \
  --from-file=tls.key=gateway.key \
  --from-file=tls.crt=gateway.crt \
  --dry-run=client -oyaml | kubectl apply -f- \
  --namespace gloo-system
kubectl label secret https gateway=https --namespace gloo-system

# ddoyle: Using "tls" instead of "generic"
printf "\nCreate the K8S HTTPS secret.\n"
kubectl create secret tls https \
  --from-file=tls.key=gateway.key \
  --from-file=tls.crt=gateway.crt \
  --dry-run=client -oyaml | kubectl apply -f- \
  --namespace ingress-gw
kubectl label secret https gateway=https --namespace ingress-gw





popd
rm -rf tls

popd