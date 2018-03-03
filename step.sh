#!/bin/bash

# $appmanager_app_id := The appmanager id of the app where the binary should be uploaded to
# $binary_path := The to be uploaded binary

set -ex
echo "This is the value specified for the input 'example_step_input': ${example_step_input}"
echo "Appmanager App Id: ${appmanager_id}"
echo "Binary Path: ${binary_path}"

postVersionPayload="{
  \"versionNr\": \"555.555.556\",
  \"app\": {
    \"id\": \"$appmanager_app_id\"
  }
}"

postVersionResponse=$(curl -s -0 -X POST \
  https://ffuf-api-services-live.azurewebsites.net/appmanager-api/apps/18/versions/ \
  -H "Cache-Control: no-cache" \
  -H "Content-Type: application/json" \
  -d "$postVersionPayload")

newVersionId=$(echo "$postVersionResponse" | jq .id | bc)
echo "New Version ID: $newVersionId"

curl -s -X POST \
  https://ffuf-api-services-live.azurewebsites.net/appmanager-api/version/$newVersionId/file/ \
  -H 'Cache-Control: no-cache' \
  -H 'Content-Type: multipart/form-data' \
  -H 'Postman-Token: 669faafe-6625-0ee1-4054-fee882074171' \
  -H 'content-type: multipart/form-data; boundary=----WebKitFormBoundary7MA4YWxkTrZu0gW' \
  -F file=@"$binary_path"

echo "Deployment done. See public page: TBA"





