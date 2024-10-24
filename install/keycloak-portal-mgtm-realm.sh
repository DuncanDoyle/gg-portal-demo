#!/bin/bash

set +x -e
source ./env.sh

export KEYCLOAK_URL=http://$KEYCLOAK_HOST
echo "Keycloak URL: $KEYCLOAK_URL"
export APP_URL=http://$PORTAL_HOST

export REALM="portal-mgmt"

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
    "group": "admin"
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


################################################ Retrieve Realm Admin token ################################################
printf "\nFetch realm admin token.\n"
curl -k -d "client_id=admin-cli" -d "username=admin" -d "password=admin" -d "grant_type=password" "$KEYCLOAK_URL/realms/$REALM/protocol/openid-connect/token"

export KEYCLOAK_NEW_REALM_TOKEN=$(curl -k -d "client_id=admin-cli" -d "username=admin" -d "password=admin" -d "grant_type=password" "$KEYCLOAK_URL/realms/$REALM/protocol/openid-connect/token" | jq -r .access_token)

[[ -z "$KEYCLOAK_NEW_REALM_TOKEN" ]] && { echo "Failed to get Keycloak token for new Realm - check KEYCLOAK_URL and KC_ADMIN_PASS"; exit 1;}

################################################ Portal Client: portal-client ################################################
# Register the portal-client
export PORTAL_CLIENT_ID=gloo-portal-idp

CREATE_PORTAL_CLIENT_JSON=$(cat <<EOM
{
  "clientId": "$PORTAL_CLIENT_ID",
  "name": "Solo.io Portal IdP Client",
  "enabled": true,
  "clientAuthenticatorType": "client-secret",
  "secret": "gloo-portal-idp-secret"
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
  name: portal-idp-oauth
  namespace: gloo-system
type: extauth.solo.io/oauth
data:
  client-secret: $(echo -n ${PORTAL_CLIENT_SECRET} | base64)
EOF

# Configure the Portal Client we've just created.
CONFIGURE_PORTAL_CLIENT_JSON=$(cat <<EOM
{
  "publicClient": false, 
  "standardFlowEnabled": true,
  "serviceAccountsEnabled": true, 
  "directAccessGrantsEnabled": false, 
  "authorizationServicesEnabled": true,
  "redirectUris": [
    "http://developer.example.com/*"
  ], 
  "attributes": {
    "post.logout.redirect.uris": "+"
  },
  "webOrigins": ["*"]
}
EOM
)
curl -k -X PUT -H "Authorization: Bearer ${KEYCLOAK_TOKEN}" -H "Content-Type: application/json" -d "$CONFIGURE_PORTAL_CLIENT_JSON" $KEYCLOAK_URL/admin/realms/$REALM/clients/${REG_ID}

# Get the User-ID of the Service Account of the Portal Client we've just created.
export SERVICE_ACCOUNT_PORTAL_CLIENT_USER_ID=$(curl -k -H "Authorization: Bearer ${KEYCLOAK_TOKEN}" -X GET -H "Accept: application/json" "$KEYCLOAK_URL/admin/realms/$REALM/users?username=service-account-gloo-portal-idp" | jq -r '.[0].id')

# Get the Client-ID of the realm-management client
export REALM_MANAGEMENT_CLIENT_ID=$(curl -k -H "Authorization: Bearer ${KEYCLOAK_TOKEN}" -X GET -H "Accept: application/json" "$KEYCLOAK_URL/admin/realms/$REALM/clients?clientId=realm-management" | jq -r '.[0].id')

# Get the Create Client role
export MANAGE_CLIENTS_ROLE_ID=$(curl -k -H "Authorization: Bearer ${KEYCLOAK_TOKEN}" -X GET -H "Accept: application/json" "$KEYCLOAK_URL/admin/realms/$REALM/clients/$REALM_MANAGEMENT_CLIENT_ID/roles/manage-clients" | jq -r '.id')

# Add role mapping to user
SERVICE_ACCOUNT_PORTAL_CLIENT_USER_ADD_ROLE_MAPPING_JSON=$(cat <<EOM
[
 {
    "id": "$MANAGE_CLIENTS_ROLE_ID",
    "name":"manage-clients",
    "description":"${role_manage-clients}"
  }
]
EOM
)

# Needed to use the Dynamic Client Registration endpoint, which can't be used with the admin user from the master realm.
printf "\nCreating Portal Client Service Account user role-mappings\n"
curl -k -H "Authorization: Bearer ${KEYCLOAK_TOKEN}" -X POST -H "Content-Type: application/json" -d "$SERVICE_ACCOUNT_PORTAL_CLIENT_USER_ADD_ROLE_MAPPING_JSON" "$KEYCLOAK_URL/admin/realms/$REALM/users/$SERVICE_ACCOUNT_PORTAL_CLIENT_USER_ID/role-mappings/clients/$REALM_MANAGEMENT_CLIENT_ID"

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