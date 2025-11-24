# Gloo Gateway - Gloo Portal demo

## Installation

Install Gloo Gateway:
```
cd install
./install-gloo-gateway-with-helm.sh
```

> [!NOTE]
> The Gloo Gateway version that will be installed is set in a variable at the top of the `install/install-gloo-edge-enterprise-with-helm.sh` installation script.

This will install:
- Keycloak
- Gloo Gateway control plane
- Gloo Gateway gateway-proxy in the `ingress-gw` namespace.

## Setup the environment

### Connfiguring K8S CoreDNS

We configure K8S CoreDNS to route `keycloak.example.com` and `developer.example.com` through the ingress-gw, so we can resovle the same hostname inside the K8S cluster and outside the K8S cluster (e.g. browser):

- Deploy the Gateway

```
./k8s-coredns-config.sh
```

### Setup Keycloak Realms
Run the following 2 scripts to setup the `gloo-demo` and `portal-mgmt` Keycloak realms. The `gloo-demo` realm holds the accounts to access the Developer Portal UI, the `portal-mgmt` realm is the realm in which we will dynamically register OAuth clients.

```
./keycloak-gloo-demo-realm.sh
./keycloak-portal-mgmt-realm.sh
```

### Setup the Portal Server and Portal Frontend

```
./setup-portal.sh
```

### Setup the HTTPBin APIProduct

```
./setup-httpbin-apiproduct.sh
```

### Setup the Tracks APIProduct

```
./setup-tracks-apiproduct.sh
```

### Configure APIProduct OAuth access

```
./setup-apiproducts-oauth.sh
```

### Configure the Gloo Portal IDP SPI

```
./install-gloo-portal-idp-connect.sh
```


## Access APIProducts with OAuth

Retrieve OAuth access-token:

```
export CLIENT_ID=493e5d54-f7d4-4dd1-afb8-372a74533394
export CLIENT_SECRET=jIM1qdNYKlxlzfMMBSMKtdivx7fhXzbp

export ACCESS_TOKEN=$(curl --request POST \
    --url 'http://keycloak.example.com/realms/portal-mgmt/protocol/openid-connect/token' \
    --header 'content-type: application/x-www-form-urlencoded' \
    --data grant_type=client_credentials \
    --data client_id=$CLIENT_ID \
    --data client_secret=$CLIENT_SECRET | jq -r '.access_token')
```

Access HTTPBin ApiProduct:

```
curl -v -X 'GET' \
  'http://api.example.com/httpbin/v1.0/get' \
  -H 'accept: */*' \
  -H "Authorization: Bearer $ACCESS_TOKEN"
```

Access Tracks ApiProduct:

```
curl -v -X 'GET' \
  'http://api.example.com/trackapi/v1.0/tracks' \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $ACCESS_TOKEN"

```