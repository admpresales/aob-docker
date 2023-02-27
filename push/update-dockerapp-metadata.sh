#!/usr/bin/env bash

UNAME=$1
UPASS=$2
IMAGE=$3
TAG=$4

FILE=$(echo $IMAGE | awk -F'/' '{print $2}')

# get token to be able to talk to Docker Hub
echo "Logging into Docker"
TOKEN=$(curl -s -H "Content-Type: application/json" -X POST -d '{"username": "'${UNAME}'", "password": "'${UPASS}'"}' https://hub.docker.com/v2/users/login/ | jq -r .token)
sed -i -e "s,<tag>,${TAG},g" ${FILE}.md

echo "Updating README for ${IMAGE}"
RETURNCODE=$(jq -n --arg msg "$(<${FILE}.md)" \
    '{"registry":"registry-1.docker.io","full_description": $msg }' | \
        curl -s -o /dev/null -L -w "%{http_code}" \
           https://hub.docker.com/v2/repositories/${IMAGE}/ \
           -d @- -X PATCH \
           -H "Content-Type: application/json" \
           -H "Authorization: JWT ${TOKEN}")

if [ "$RETURNCODE" != "200" ]; then
    return 1
fi