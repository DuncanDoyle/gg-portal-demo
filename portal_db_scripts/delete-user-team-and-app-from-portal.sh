#!/bin/sh

# Connection parameters
HOST="localhost"
PORT="5432"
USER="user"
DB="db"

export PGPASSWORD="pass"

#------------------------------------------------------------------------------------------------------------------------

USERNAME="user2"

# Explanation of psql flags.
# -t → no headers/footers (“tuples only”)
# -A → unaligned mode (no spaces, clean output)
# -c → run a single SQL command
USER_ID=$(psql -h $HOST -p $PORT -U $USER -d $DB -t -A -c "SELECT id FROM public.users WHERE username = '$USERNAME';")

printf "\nID for user with username $USERNAME is: $USER_ID"


# Find all the teams of this user
# Note: be careful here, we assume that these teams only have the user as a member.

# 'mapfile' works in Bash4+, but macOS runs with Bash 3, so we need to use  another command.
# mapfile -t TEAM_IDS < <(psql -h $HOST -p $PORT -U $USER -d $DB -t -A -c "
#     SELECT team_id FROM public.team_members WHERE user_id = '$USER_ID';
# ")

TEAM_IDS=($(psql -h $HOST -p $PORT -U $USER -d $DB -t -A -c "SELECT team_id FROM public.team_members WHERE user_id = '$USER_ID';"))

printf "\nFound Team IDs:\n"
printf "%s\n" "${TEAM_IDS[@]}"

APPLICATION_IDS=()

for teamId in "${TEAM_IDS[@]}"; do
  # Query that returns multiple IDs for this ID
  RESULT_IDS=$(psql -h $HOST -p $PORT -U $USER -d $DB -t -A -c "SELECT id FROM public.applications WHERE team_id = '$teamId';")
  
  # Convert newline-separated IDs into space-separated, then append to ALL_IDS
  for rid in $RESULT_IDS; do
      APPLICATION_IDS+=("$rid")
  done
done

# Step 4: Print all Application IDs

printf "\nThe IDs of all the applications that are owned by teams of which user $USERNAME is a member:\n"
printf "%s\n" "${APPLICATION_IDS[@]}"
echo "Total IDs: ${#APPLICATION_IDS[@]}"


# Get all API_KEY_IDS for all our applications.

API_KEY_IDS=()

for applicationId in "${APPLICATION_IDS[@]}"; do
  # Query that returns multiple IDs for this ID
  RESULT_IDS=$(psql -h $HOST -p $PORT -U $USER -d $DB -t -A -c "SELECT id FROM public.api_keys WHERE application_id = '$applicationId';")
  
  # Convert newline-separated IDs into space-separated, then append to ALL_IDS
  for rid in $RESULT_IDS; do
      API_KEY_IDS+=("$rid")
  done
done


# Find Application Product Subscriptions
APP_PRODUCT_SUBSCRIPTION_IDS=()

for applicationId in "${APPLICATION_IDS[@]}"; do
  # Query that returns multiple IDs for this ID
  RESULT_IDS=$(psql -h $HOST -p $PORT -U $USER -d $DB -t -A -c "SELECT id FROM public.application_product_subscriptions WHERE application_id = '$applicationId';")
  
  # Convert newline-separated IDs into space-separated, then append to ALL_IDS
  for rid in $RESULT_IDS; do
      APP_PRODUCT_SUBSCRIPTION_IDS+=("$rid")
  done
done


#------------------------------------------------------------------------------------------------------------------------------------

# We have collected all the IDs we need for now. We can now delete the applications, teams, and users.

# Delete api_keys
for apikeyId in "${API_KEY_IDS[@]}"; do
  # Query that returns multiple IDs for this ID
  psql -h $HOST -p $PORT -U $USER -d $DB -t -A -c "DELETE FROM public.api_keys WHERE id = '$apikeyId';"
done

# Delete app product subscriptions
for appProductSubscriptionId in "${APP_PRODUCT_SUBSCRIPTION_IDS[@]}"; do
  # Query that returns multiple IDs for this ID
  psql -h $HOST -p $PORT -U $USER -d $DB -t -A -c "DELETE FROM public.application_product_subscriptions WHERE id = '$appProductSubscriptionId';"
done

# Delete applications
for applicationId in "${APPLICATION_IDS[@]}"; do
  # Query that returns multiple IDs for this ID
  psql -h $HOST -p $PORT -U $USER -d $DB -t -A -c "DELETE FROM public.applications WHERE id = '$applicationId';"
done

# Delete team_members
for teamId in "${TEAM_IDS[@]}"; do
  # Query that returns multiple IDs for this ID
  psql -h $HOST -p $PORT -U $USER -d $DB -t -A -c "DELETE FROM public.team_members WHERE team_id = '$teamId';"
done

# Delete teams
for teamId in "${TEAM_IDS[@]}"; do
  # Query that returns multiple IDs for this ID
  psql -h $HOST -p $PORT -U $USER -d $DB -t -A -c "DELETE FROM public.teams WHERE id = '$teamId';"
done

# Delete users
psql -h $HOST -p $PORT -U $USER -d $DB -t -A -c "DELETE FROM public.users WHERE id = '$USER_ID';"

printf "\n\nDatabase operations completed successfully. Deleted applications, teams and user for user with username $USERNAME.\n"