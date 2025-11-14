#!/bin/sh

# Connection parameters
HOST="localhost"
PORT="5432"
USER="user"
DB="db"

export PGPASSWORD="pass"

#------------------------------------------------------------------------------------------------------------------------
# Create User

USERNAME="user2"
# ID from Keycloak. This will change with every setup. We should probably fetch this from Keycloak, but I'm lazy.
USER_IDENTITY_PROVIDER_ID='80d74001-fe81-4128-890b-f1de8cfbba83'
NAME="User Two"
EMAIL="user2@solo.io"

# Should check if the user with the given username and ID provider ID already exists.

USER_ID=$(psql -h $HOST -p $PORT -U $USER -d $DB -t -A -c "SELECT id FROM public.users WHERE username = '$USERNAME' AND identity_provider_id = '$USER_IDENTITY_PROVIDER_ID';")

if [ -z "$USER_ID" ]; then
    export USER_ID=$(uuidgen | tr '[:upper:]' '[:lower:]')
    psql -h "$HOST" -p "$PORT" -U "$USER" -d "$DB" <<EOF
INSERT INTO public.users (
  id,
  created_at,
  updated_at,
  deleted_at,
  identity_provider_id,
  username,
  name,
  email,
  approved,
  approved_at,
  synced
)
VALUES (
  '$USER_ID',
  NOW(),                                 
  NOW(),                                 
  NULL,
  '$USER_IDENTITY_PROVIDER_ID',
  '$USERNAME',             
  '$NAME',
  '$email',
  false,
  '0001-01-01 00:00:00+00',
  true  
);
EOF
else
    printf "\nUser $USERNAME already exists. Using existing user.\n\n"
fi


#------------------------------------------------------------------------------------------------------------------------
# Create Team

TEAM_NAME="random-team-name"
TEAM_DESCRIPTION="My random team description."

export TEAM_ID=$(uuidgen | tr '[:upper:]' '[:lower:]')

psql -h "$HOST" -p "$PORT" -U "$USER" -d "$DB" <<EOF
INSERT INTO public.teams (
  id,
  created_at,
  updated_at,
  deleted_at,
  name,
  description
)
VALUES (
  '$TEAM_ID',
  NOW(),                                 
  NOW(),                                 
  NULL,
  '$TEAM_NAME',
  '$TEAM_DESCRIPTION'
);
EOF

#------------------------------------------------------------------------------------------------------------------------
# Add user to team

psql -h "$HOST" -p "$PORT" -U "$USER" -d "$DB" <<EOF
INSERT INTO public.team_members (
  joined_at,
  role,
  user_id,
  team_id,
  deleted_at
)
VALUES (
  NOW(),                                 
  '',                                 
  '$USER_ID',
  '$TEAM_ID',
  NULL
);
EOF


#------------------------------------------------------------------------------------------------------------------------
# Add application to team

APP_NAME="random-application-name"
APP_DESCRIPTION="My random application name"

export APP_ID=$(uuidgen | tr '[:upper:]' '[:lower:]')

psql -h "$HOST" -p "$PORT" -U "$USER" -d "$DB" <<EOF
INSERT INTO public.applications (
  id,
  created_at,
  updated_at,
  deleted_at,
  name,
  description,
  team_id
)
VALUES (
  '$APP_ID',
  NOW(),
  NOW(),
  NULL,
  '$APP_NAME',                                 
  '$APP_DESCRIPTION',
  '$TEAM_ID'
);
EOF


#------------------------------------------------------------------------------------------------------------------------
# Add API-Key to application

# API-Key (Secret): N2YwMDIxZTEtNGUzNS1jNzgzLTRkYjAtYjE2YzRkZGVmNjcy
API_KEY_NAME="gloo-classic-api-key"
API_KEY_HMAC="eSHRAmNyYxDkfQQ80VeJktPUXPJtenVEwC8M4hZl21w="

export API_KEY_ID=$(uuidgen | tr '[:upper:]' '[:lower:]')

psql -h "$HOST" -p "$PORT" -U "$USER" -d "$DB" <<EOF
INSERT INTO public.api_keys (
  id,
  created_at,
  updated_at,
  deleted_at,
  name,
  key,
  application_id
)
VALUES (
  '$API_KEY_ID',
  NOW(),                                 
  NOW(),                                 
  NULL,                                  
  '$API_KEY_NAME',             
  '$API_KEY_HMAC',
  '$APP_ID'
);
EOF

#------------------------------------------------------------------------------------------------------------------------
# Create application product subscription

# HTTPBin application id
API_PRODUCT_ID="d863a6e7-b924-464f-8f3d-3b81e66ef50b"
API_KEY_HMAC="eSHRAmNyYxDkfQQ80VeJktPUXPJtenVEwC8M4hZl21w="

export API_KEY_ID=$(uuidgen | tr '[:upper:]' '[:lower:]')

psql -h "$HOST" -p "$PORT" -U "$USER" -d "$DB" <<EOF
INSERT INTO public.application_product_subscriptions (
  id,
  created_at,
  updated_at,
  deleted_at,
  requested_at,
  approved,
  approved_at,
  rejected,
  rejected_at,
  application_id,
  api_product_id
)
VALUES (
  '$API_KEY_ID',
  NOW(),                                 
  NOW(),                                 
  NULL,
  NOW(), 
  true,
  NOW(),
  false,
  NULL,
  '$APP_ID',
  '$API_PRODUCT_ID'
);
EOF

printf "\nSuccessfully added user, team and application to Portal!\n"