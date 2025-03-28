#!/bin/sh

if [ -z "$AWS_ACCESS_KEY" ]
then
   echo "AWS access-key not specified. Please configure the environment variable 'AWS_ACCESS_KEY' with your AWS access-key."
   exit 1
fi

if [ -z "$AWS_SECRET ACCESS_KEY" ]
then
   echo "AWS secret-access-key not specified. Please configure the environment variable 'AWS_SECRET_ACCESS_KEY' with your AWS secret-access-key."
   exit 1
fi

printf "\nCreating AWS Credentials secret in the 'gloo-system' namespace."

glooctl create secret aws \
   --name aws-creds \
   --namespace gloo-system \
   --access-key $AWS_ACCESS_KEY \
   --secret-key $AWS_SECRET_ACCESS_KEY