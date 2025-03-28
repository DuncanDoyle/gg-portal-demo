#!/bin/bash

set +x -e
source ./env.sh

export KEYCLOAK_URL=http://$KEYCLOAK_HOST
echo "Keycloak URL: $KEYCLOAK_URL"
export APP_URL=http://$PORTAL_HOST

export REALM="gloo-demo"

[[ -z "$KC_ADMIN_PASS" ]] && { echo "You must set KC_ADMIN_PASS env var to the password for a Keycloak admin account"; exit 1;}

# Set the Keycloak admin token
export KEYCLOAK_TOKEN=$(curl -k -d "client_id=admin-cli" -d "username=admin" -d "password=$KC_ADMIN_PASS" -d "grant_type=password" "$KEYCLOAK_URL/realms/master/protocol/openid-connect/token" | jq -r .access_token)

[[ -z "$KEYCLOAK_TOKEN" ]] && { echo "Failed to get Keycloak token - check KEYCLOAK_URL and KC_ADMIN_PASS"; exit 1;}


################################################ Create Realm ################################################

printf "\nCreating new Realm: $REALM\n"
CREATE_REALM_JSON=$(cat <<- EOM
{
  "realm": "$REALM",
  "enabled": true
}
EOM
)
curl -k -X POST -H "Authorization: Bearer $KEYCLOAK_TOKEN" -H "Content-Type: application/json" -d "$CREATE_REALM_JSON" $KEYCLOAK_URL/admin/realms

# Set the Unmanaged Atttributed setting
export USERS_PROFILE=$(curl -k -X GET -H "Authorization: Bearer $KEYCLOAK_TOKEN" -H "Accept: application/json" $KEYCLOAK_URL/admin/realms/$REALM/users/profile | jq '. += {"unmanagedAttributePolicy":"ENABLED"}')

curl -k -X PUT -H "Authorization: Bearer $KEYCLOAK_TOKEN" -H "Content-Type: application/json" -d "$USERS_PROFILE" $KEYCLOAK_URL/admin/realms/$REALM/users/profile

################################################ Create Admin User ################################################

printf "\nCreating new Admin user in realm: $REALM\n"
CREATE_ADMIN_USER_JSON=$(cat <<EOM
{
  "username": "admin", 
  "email": "admin@example.com",
  "firstName": "admin",
  "lastName": "example",
  "enabled": true,
  "emailVerified": true,
  "attributes": {
    "group": "admin",
    "show_personal_data": "false"
  },
  "credentials": [
    {
      "type": "password", 
      "value": "admin",
      "temporary": false
    }
  ]
}
EOM
)
curl -k -H "Authorization: Bearer ${KEYCLOAK_TOKEN}" -X POST -H "Content-Type: application/json" -d "$CREATE_ADMIN_USER_JSON" "$KEYCLOAK_URL/admin/realms/$REALM/users"

# Get the User-ID
export ADMIN_USER_ID=$(curl -k -H "Authorization: Bearer ${KEYCLOAK_TOKEN}" -X GET -H "Accept: application/json" "$KEYCLOAK_URL/admin/realms/$REALM/users?username=admin" | jq -r '.[0].id')

# Get the Client-ID of the realm-management client
export REALM_MANAGEMENT_CLIENT_ID=$(curl -k -H "Authorization: Bearer ${KEYCLOAK_TOKEN}" -X GET -H "Accept: application/json" "$KEYCLOAK_URL/admin/realms/$REALM/clients?clientId=realm-management" | jq -r '.[0].id')

# Get the Create Client role
export CREATE_CLIENT_ROLE_ID=$(curl -k -H "Authorization: Bearer ${KEYCLOAK_TOKEN}" -X GET -H "Accept: application/json" "$KEYCLOAK_URL/admin/realms/$REALM/clients/$REALM_MANAGEMENT_CLIENT_ID/roles/create-client" | jq -r '.id')

# Add role mapping to user
ADMIN_USER_ADD_ROLE_MAPPING_JSON=$(cat <<EOM
[
 {
    "id": "$CREATE_CLIENT_ROLE_ID",
    "name":"create-client",
    "description":"${role_create-client}"
  }
]
EOM
)

# Needed to use the Dynamic Client Registration endpoint, which can't be used with the admin user from the master realm.
printf "\nCreating Admin user role-mappings\n"
curl -k -H "Authorization: Bearer ${KEYCLOAK_TOKEN}" -X POST -H "Content-Type: application/json" -d "$ADMIN_USER_ADD_ROLE_MAPPING_JSON" "$KEYCLOAK_URL/admin/realms/$REALM/users/$ADMIN_USER_ID/role-mappings/clients/$REALM_MANAGEMENT_CLIENT_ID"

################################################ Scopes: API Product scopes. ################################################

## declare an array variable
declare -a API_PRODUCTS=("Catstronauts" "Petstore")

## now loop through the above array
for API_PRODUCT in "${API_PRODUCTS[@]}"
do
  echo "Registering scope for API-Product: $API_PRODUCT"
  API_PRODUCT_SCOPE_JSON=$(cat <<- EOM
  {
    "name": "$API_PRODUCT",
    "description": "Adds Tracks API to the product claims",
    "protocol": "openid-connect",
    "attributes": {
      "include.in.token.scope": "true",
      "display.on.consent.screen": "true",
      "gui.order": "",
      "consent.screen.text": ""
    }
  }
EOM
  )
  curl -k -X POST -H "Authorization: Bearer $KEYCLOAK_TOKEN" -H "Content-Type: application/json" -d "$API_PRODUCT_SCOPE_JSON" $KEYCLOAK_URL/admin/realms/$REALM/client-scopes
done

################################################ Retrieve Realm Admin token ################################################
printf "\nFetch realm admin token.\n"
curl -k -d "client_id=admin-cli" -d "username=admin" -d "password=admin" -d "grant_type=password" "$KEYCLOAK_URL/realms/$REALM/protocol/openid-connect/token"

export KEYCLOAK_NEW_REALM_TOKEN=$(curl -k -d "client_id=admin-cli" -d "username=admin" -d "password=admin" -d "grant_type=password" "$KEYCLOAK_URL/realms/$REALM/protocol/openid-connect/token" | jq -r .access_token)

[[ -z "$KEYCLOAK_NEW_REALM_TOKEN" ]] && { echo "Failed to get Keycloak token for new Realm - check KEYCLOAK_URL and KC_ADMIN_PASS"; exit 1;}

################################################ Portal Client: portal-client ################################################
# Register the portal-client
export PORTAL_CLIENT_ID=portal-client

CREATE_PORTAL_CLIENT_JSON=$(cat <<EOM
{
  "clientId": "$PORTAL_CLIENT_ID"
}
EOM
)

read -r regid secret <<<$(curl -k -X POST -H "Authorization: bearer ${KEYCLOAK_NEW_REALM_TOKEN}" -H "Content-Type:application/json" -d "$CREATE_PORTAL_CLIENT_JSON"  ${KEYCLOAK_URL}/realms/$REALM/clients-registrations/default |  jq -r '[.id, .secret] | @tsv')

export PORTAL_CLIENT_SECRET=${secret}
export REG_ID=${regid}

[[ -z "$PORTAL_CLIENT_SECRET" || $PORTAL_CLIENT_SECRET == null ]] && { echo "Failed to create client in Keycloak"; exit 1;}

# Create a oauth K8S secret with from the portal-client's secret. 
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: oauth
  namespace: gloo-system
type: extauth.solo.io/oauth
data:
  client-secret: $(echo -n ${PORTAL_CLIENT_SECRET} | base64)
EOF

# Configure the Portal Client we've just created.
CONFIGURE_PORTAL_CLIENT_JSON=$(cat <<EOM
{
  "publicClient": true, 
  "serviceAccountsEnabled": true, 
  "directAccessGrantsEnabled": true, 
  "authorizationServicesEnabled": true, 
  "redirectUris": [
    "http://developer.example.com/*", 
    "https://developer.example.com/*", 
    "http://localhost:7007/gloo-platform-portal/*", 
    "http://localhost:4000/*", 
    "http://localhost:3000/*"
  ], 
  "webOrigins": ["*"]
}
EOM
)
curl -k -X PUT -H "Authorization: Bearer ${KEYCLOAK_TOKEN}" -H "Content-Type: application/json" -d "$CONFIGURE_PORTAL_CLIENT_JSON" $KEYCLOAK_URL/admin/realms/$REALM/clients/${REG_ID}

# Add the group attribute in the JWT token returned by Keycloak
CONFIGURE_GROUP_CLAIM_IN_JWT_JSON=$(cat <<EOM
{
  "name": "group", 
  "protocol": "openid-connect", 
  "protocolMapper": "oidc-usermodel-attribute-mapper", 
  "config": {
    "claim.name": "group", 
    "jsonType.label": "String", 
    "user.attribute": "group", 
    "id.token.claim": "true", 
    "access.token.claim": "true"
  }
}
EOM
)
curl -k -X POST -H "Authorization: Bearer ${KEYCLOAK_TOKEN}" -H "Content-Type: application/json" -d "$CONFIGURE_GROUP_CLAIM_IN_JWT_JSON" $KEYCLOAK_URL/admin/realms/$REALM/clients/${REG_ID}/protocol-mappers/models


# ################################################ WebApp Client: webapp-client ################################################
# # Register the webapp-client
# export WEBAPP_CLIENT_ID=webapp-client

# CREATE_WEBAPP_CLIENT_JSON=$(cat <<EOM
# {
#   "clientId": "$WEBAPP_CLIENT_ID"
# }
# EOM
# )
# read -r regid secret <<<$(curl -k -X POST -H "Authorization: bearer ${KEYCLOAK_NEW_REALM_TOKEN}" -H "Content-Type:application/json" -d "$CREATE_WEBAPP_CLIENT_JSON"  ${KEYCLOAK_URL}/realms/$REALM/clients-registrations/default |  jq -r '[.id, .secret] | @tsv')

# export WEBAPP_CLIENT_SECRET=${secret}
# export REG_ID=${regid}

# [[ -z "$WEBAPP_CLIENT_SECRET" || $WEBAPP_CLIENT_SECRET == null ]] && { echo "Failed to create client in Keycloak"; exit 1;}

# # Create a oauth K8S secret with from the webapp-client's secret. 
# kubectl apply -f - <<EOF
# apiVersion: v1
# kind: Secret
# metadata:
#   name: oauth
#   namespace: gloo-system
# type: extauth.solo.io/oauth
# data:
#   client-secret: $(echo -n ${WEBAPP_CLIENT_SECRET} | base64)
# EOF

# # Configure the WebApp Client we've just created.
# CONFIGURE_WEBAPP_CLIENT_JSON=$(cat <<EOM
# {
#   "publicClient": false, 
#   "serviceAccountsEnabled": true, 
#   "directAccessGrantsEnabled": true, 
#   "authorizationServicesEnabled": true, 
#   "redirectUris": [
#     "http://api.example.com/callback",
#     "http://httpbin.example.com/callback"
#   ], 
#   "webOrigins": ["*"]
# }
# EOM
# )
# curl -k -X PUT -H "Authorization: Bearer ${KEYCLOAK_TOKEN}" -H "Content-Type: application/json" -d "$CONFIGURE_WEBAPP_CLIENT_JSON" $KEYCLOAK_URL/admin/realms/$REALM/clients/${REG_ID}

# # Add the group attribute in the JWT token returned by Keycloak
# CONFIGURE_GROUP_CLAIM_IN_JWT_JSON=$(cat <<EOM
# {
#   "name": "group", 
#   "protocol": "openid-connect", 
#   "protocolMapper": "oidc-usermodel-attribute-mapper", 
#   "config": {
#     "claim.name": "group", 
#     "jsonType.label": "String", 
#     "user.attribute": "group", 
#     "id.token.claim": "true", 
#     "access.token.claim": "true"
#   }
# }
# EOM
# )
# curl -k -X POST -H "Authorization: Bearer ${KEYCLOAK_TOKEN}" -H "Content-Type: application/json" -d "$CONFIGURE_GROUP_CLAIM_IN_JWT_JSON" $KEYCLOAK_URL/admin/realms/$REALM/clients/${REG_ID}/protocol-mappers/models


################################################ User One: user1@example.com ################################################

# Create first user        
CREATE_USER_ONE_JSON=$(cat <<EOM
{
  "username": "user1", 
  "email": "user1@example.com", 
  "firstName": "User",
  "lastName": "One",
  "emailVerified": true,
  "enabled": true, 
  "attributes": {
    "group": "users",
    "subscription": "enterprise"
  },
  "credentials": [
    {
      "type": "password", 
      "value": "password",
      "temporary": false
    }
  ]
}
EOM
)
curl -k -H "Authorization: Bearer ${KEYCLOAK_TOKEN}" -X POST -H "Content-Type: application/json" -d "$CREATE_USER_ONE_JSON" $KEYCLOAK_URL/admin/realms/$REALM/users


################################################ User Two: user2@solo.io ################################################

# Create second user
CREATE_USER_TWO_JSON=$(cat <<EOM
{
  "username": "user2",
  "email": "user2@solo.io",
  "firstName": "User",
  "lastName": "Two",
  "emailVerified": true,
  "enabled": true, 
  "attributes": {
    "group": "users",
    "subscription": "free",
    "show_personal_data": "false"
  }, 
  "credentials": [
    {
      "type": "password",
      "value": "password",
      "temporary": false
    }
  ]
}
EOM
)
curl -k -X POST -H "Authorization: Bearer ${KEYCLOAK_TOKEN}"  -H "Content-Type: application/json" -d "$CREATE_USER_TWO_JSON" $KEYCLOAK_URL/admin/realms/$REALM/users



################################################ Admin One: admin1@solo.io ################################################

# Create second user
CREATE_ADMIN_ONE_JSON=$(cat <<EOM
{
  "username": "admin1",
  "email": "admin1@solo.io",
  "enabled": true,
  "attributes": {
    "group": "users"
  }, 
  "credentials": [
    {
      "type": "password",
      "value": "password",
      "temporary": false
    }
  ]
}
EOM
)
curl -k -X POST -H "Authorization: Bearer ${KEYCLOAK_TOKEN}"  -H "Content-Type: application/json" -d "$CREATE_ADMIN_ONE_JSON" $KEYCLOAK_URL/admin/realms/$REALM/users

################################################ Portal Service Account: portal-sa ################################################

# Register Portal Service Account Client
export PORTAL_SA_CLIENT_ID=portal-sa
CREATE_PORTAL_SA_CLIENT_JSON=$(cat <<EOM
{ 
  "clientId": "$PORTAL_SA_CLIENT_ID" 
}
EOM
)
read -r regid secret <<<$(curl -k -X POST  -H "Authorization: bearer ${KEYCLOAK_NEW_REALM_TOKEN}" -H "Content-Type:application/json" -d "$CREATE_PORTAL_SA_CLIENT_JSON" ${KEYCLOAK_URL}/realms/$REALM/clients-registrations/default |  jq -r '[.id, .secret] | @tsv')

export PORTAL_SA_CLIENT_SECRET=${secret}
export REG_ID=${regid}
[[ -z "$PORTAL_SA_CLIENT_SECRET" || $PORTAL_SA_CLIENT_SECRET == null ]] && { echo "Failed to create client in Keycloak"; exit 1;}

printf "\nCreated service account:\n"
printf "Client-ID: $PORTAL_SA_CLIENT_ID\n"
printf "Client-Secret: $PORTAL_SA_CLIENT_SECRET\n\n"
export CLIENT_ID=$PORTAL_SA_CLIENT_ID
export CLIENT_SECRET=$PORTAL_SA_CLIENT_SECRET

if [ "$BACKSTAGE_ENABLED" = true ] ; then
  printf "\nCreating K8S Secret for PORTAL_SA_CLIENT_SECRET in backstage namespace.\n"
  
  kubectl apply -f - <<EOF
  apiVersion: v1
  kind: Secret
  metadata:
    name: portal-sa-client-secret
    namespace: backstage
  type: extauth.solo.io/oauth
  data:
    SA_CLIENT_SECRET: $(echo -n ${PORTAL_SA_CLIENT_SECRET} | base64)
EOF
fi

#Configure the Portal Service Account
CONFIGURE_CLIENT_SERVICE_ACCOUNT_JSON=$(cat <<EOM
{
  "publicClient": false, 
  "standardFlowEnabled": false, 
  "serviceAccountsEnabled": true, 
  "directAccessGrantsEnabled": false, 
  "authorizationServicesEnabled": false
}
EOM
)
curl -k -X PUT  -H "Authorization: Bearer ${KEYCLOAK_TOKEN}" -H "Content-Type: application/json" -d "$CONFIGURE_CLIENT_SERVICE_ACCOUNT_JSON" $KEYCLOAK_URL/admin/realms/$REALM/clients/${REG_ID}

# Add the group attribute to the JWT token returned by Keycloak
curl -k -H "Authorization: Bearer ${KEYCLOAK_TOKEN}" -X POST -H "Content-Type: application/json" -d "$CONFIGURE_GROUP_CLAIM_IN_JWT_JSON" $KEYCLOAK_URL/admin/realms/$REALM/clients/${REG_ID}/protocol-mappers/models

# Add the usagePlan attribute to the JWT token returned by Keycloak
CONFIGURE_USAGE_PLAN_CLAIM_IN_JWT_JSON=$(cat <<EOM
{
  "name": "usagePlan", 
  "protocol": "openid-connect", 
  "protocolMapper": 
  "oidc-usermodel-attribute-mapper", 
  "config": {
    "claim.name": "usagePlan", 
    "jsonType.label": "String", 
    "user.attribute": "usagePlan", 
    "id.token.claim": "true", 
    "access.token.claim": "true"
  }
}
EOM
)
curl -k -X POST -H "Authorization: Bearer ${KEYCLOAK_TOKEN}" -H "Content-Type: application/json" -d "$CONFIGURE_USAGE_PLAN_CLAIM_IN_JWT_JSON" $KEYCLOAK_URL/admin/realms/$REALM/clients/${REG_ID}/protocol-mappers/models

# TODO: We should actually loop a couple of times. I.e. retry till the entity is created.
# printf "Wait till the user is created."
# sleep 2

# Retrieve the user-id of the user we've just created.
export userResponse=$(curl -k -X GET -H "Accept:application/json" -H "Authorization: Bearer ${KEYCLOAK_TOKEN}" ${KEYCLOAK_URL}/admin/realms/$REALM/users?username=service-account-${PORTAL_SA_CLIENT_ID}&exact=true)
export userid=$(echo $userResponse | jq -r '.[0].id')
# Set the extra group attribute on the user.

CONFIGURE_GROUP_ATTRIBUTE_ON_USER_JSON=$(cat <<EOM
{
  "email": "${PORTAL_SA_CLIENT_ID}@example.com", 
  "attributes": {
    "group": "users",
    "usagePlan": "silver"
  }
}
EOM
)
curl -k -H "Authorization: Bearer ${KEYCLOAK_TOKEN}" -X PUT -H "Content-Type: application/json" -d "$CONFIGURE_GROUP_ATTRIBUTE_ON_USER_JSON" $KEYCLOAK_URL/admin/realms/$REALM/users/$userid

# Add the Catstronauts API-Product Scope
# TODO: there must be a way to select just a single scope and fetch it's ID ....
CLIENT_SCOPE_ID=$(curl -k -H "Authorization: Bearer ${KEYCLOAK_TOKEN}" $KEYCLOAK_URL/admin/realms/$REALM/client-scopes | jq -r ".[] | select(.name==\"Catstronauts\") | .id") 

curl -k -H "Authorization: Bearer ${KEYCLOAK_TOKEN}" -X PUT "$KEYCLOAK_URL/admin/realms/$REALM/clients/${REG_ID}/default-client-scopes/$CLIENT_SCOPE_ID"

# ################################################ Parnter Portal Client Account: partner-portal-sa ################################################

# #### Creating a second OIDC Client for another portal.

# export PARTNER_PORTAL_CLIENT_ID=partner-portal-client
# export PARTNER_APP_URL=http://$PARTNER_PORTAL_HOST

# # Register the client
# CREATE_PARTNER_PORTAL_CLIENT_JSON=$(cat <<EOM
# {
#   "clientId": "$PARTNER_PORTAL_CLIENT_ID" 
# }
# EOM
# )
# read -r regid secret <<<$(curl -k -X POST -H "Authorization: bearer ${KEYCLOAK_NEW_REALM_TOKEN}" -H "Content-Type:application/json" -d "$CREATE_PARTNER_PORTAL_CLIENT_JSON" ${KEYCLOAK_URL}/realms/$REALM/clients-registrations/default |  jq -r '[.id, .secret] | @tsv')

# export PARTNER_PORTAL_CLIENT_SECRET=${secret}
# export REG_ID=${regid}

# [[ -z "$PARTNER_PORTAL_CLIENT_SECRET" || $PARTNER_PORTAL_CLIENT_SECRET == null ]] && { echo "Failed to create client in Keycloak"; exit 1;}

# kubectl apply -f - <<EOF
# apiVersion: v1
# kind: Secret
# metadata:
#   name: partner-oauth
#   namespace: gloo-system
# type: extauth.solo.io/oauth
# data:
#   client-secret: $(echo -n ${PARTNER_PORTAL_CLIENT_SECRET} | base64)
# EOF

# # Configure the Portal Client we've just created.
# CONFIGURE_PARTNER_PORTAL_CLIENT_JSON=$(cat <<EOM
# {
#   "publicClient": true,
#   "serviceAccountsEnabled": true,
#   "directAccessGrantsEnabled": true,
#   "authorizationServicesEnabled": true,
#   "redirectUris": [
#     "http://developer.example.com/*",
#     "https://developer.example.com/*",
#     "http://localhost:7007/gloo-platform-portal/*",
#     "http://localhost:4000/*",
#     "http://localhost:3000/*"
#   ],
#   "webOrigins": ["*"]
# }
# EOM
# )
# curl -k -X PUT -H "Authorization: Bearer ${KEYCLOAK_TOKEN}" -H "Content-Type: application/json" -d "$CONFIGURE_PARTNER_PORTAL_CLIENT_JSON" $KEYCLOAK_URL/admin/realms/$REALM/clients/${REG_ID}

# # Add the group attribute in the JWT token returned by Keycloak
# curl -k -X POST -H "Authorization: Bearer ${KEYCLOAK_TOKEN}" -H "Content-Type: application/json" -d "$CONFIGURE_GROUP_CLAIM_IN_JWT_JSON" $KEYCLOAK_URL/admin/realms/$REALM/clients/${REG_ID}/protocol-mappers/models


# kubectl apply -f - <<EOF
# apiVersion: security.policy.gloo.solo.io/v2
# kind: ExtAuthPolicy
# metadata:
#   name: oidc-auth
#   namespace: gloo-mesh
# spec:
#   applyToRoutes:
#     - route:
#         labels:
#           oidc-auth-code-flow: "true"
#   config:
#     server:
#       name: ext-auth-server
#       namespace: gloo-mesh-addons
#       cluster: ${CLUSTER_NAME}
#     glooAuth:
#       configs:
#         - oauth2:
#             oidcAuthorizationCode:
#               appUrl: $APP_URL
#               callbackPath: /portal-server/v1/login
#               clientId: ${KEYCLOAK_CLIENT_ID}
#               clientSecretRef:
#                 name: oauth
#                 namespace: gloo-mesh-addons
#               issuerUrl: $KEYCLOAK_URL/realms/master/
#               logoutPath: /portal-server/v1/logout
#               scopes:
#                 - email
#               # you can change the session config to use redis if you want
#               session:
#                 failOnFetchFailure: true
#                 cookie:
#                   allowRefreshing: true
#                 cookieOptions:
#                   notSecure: true
#                   maxAge: 3600
#               headers:
#                 idTokenHeader: id_token
# EOF


# kubectl apply -f - <<EOF
# apiVersion: security.policy.gloo.solo.io/v2
# kind: ExtAuthPolicy
# metadata:
#   name: partner-oidc-auth
#   namespace: gloo-mesh
# spec:
#   applyToRoutes:
#     - route:
#         labels:
#           partner-oidc-auth-code-flow: "true"
#   config:
#     server:
#       name: ext-auth-server
#       namespace: gloo-mesh-addons
#       cluster: ${CLUSTER_NAME}
#     glooAuth:
#       configs:
#         - oauth2:
#             oidcAuthorizationCode:
#               appUrl: $PARTNER_APP_URL
#               callbackPath: /portal-server/v1/login
#               clientId: ${PARTNER_KEYCLOAK_CLIENT_ID}
#               clientSecretRef:
#                 name: partner-oauth
#                 namespace: gloo-mesh-addons
#               issuerUrl: $KEYCLOAK_URL/realms/master/
#               logoutPath: /portal-server/v1/logout
#               scopes:
#                 - email
#               # you can change the session config to use redis if you want
#               session:
#                 failOnFetchFailure: true
#                 cookie:
#                   allowRefreshing: true
#                 cookieOptions:
#                   notSecure: true
#                   maxAge: 3600
#               headers:
#                 idTokenHeader: id_token
# EOF