#!/bin/bash

# $base_api_url := The appmanager's base API URL
# $appmanager_app_id := The appmanager id of the app where the binary should be uploaded to
# $binary_path := The to be uploaded binary
# $binary_version_code := The version code of the new binary

while [ $# -gt 0 ]; do
   if [[ $1 == *"--"* ]]; then
        v="${1/--/}"
        declare "$v"="$2"
   fi
  shift
done

m_base_api_url=${base_api_url}
m_appmanager_app_id=${appmanager_id}
m_binary_path=${binary_path}
m_binary_version_code=${binary_version_code}

if [[ -z "$m_appmanager_app_id" ]]; then
  echo "using command line parameter"
  m_base_api_url=$base_api_url
  m_appmanager_app_id=$appmanager_app_id
  m_binary_path=$binary_path
  m_binary_version_code=$binary_version_code
fi


echo "Received Arguments:"
echo "* Base API URL: $m_base_api_url"
echo "* Appmanager App Id: $m_appmanager_app_id"
echo "* Binary Path: ${binary_path}"
echo "* Version Code: ${binary_version_code}"

# TODO: Check if all input arguments are set

if ! type "jq" > /dev/null; then
  echo "Exit since jq not availbable" && exit 1
fi

if ! type "bc" > /dev/null; then
  echo "Exit since bc not availbable" && exit 1
fi


# send and store the new version
postVersionPayload="{
  \"versionNr\": \"$m_binary_version_code\",
  \"app\": {
    \"id\": \"$m_appmanager_app_id\"
  }
}"
postVersionResponse=$(curl -s -0 -X POST \
  "$m_base_api_url"/apps/"$m_appmanager_app_id"/versions/ \
  -H "Cache-Control: no-cache" \
  -H "Content-Type: application/json" \
  -d "$postVersionPayload")

echo -e "\\nPost Version Response:"
echo "$postVersionResponse" | jq -C

# parse the new version id from the response body and make the string to a number
newVersionId=$(echo "$postVersionResponse" | jq .id | bc)
echo "New Version ID: $newVersionId"

# send the actual binary for the newly created version
postFileResponse=$(curl -s -X POST \
  "$m_base_api_url"/version/"$newVersionId"/file/ \
  -H 'Cache-Control: no-cache' \
  -H 'Content-Type: multipart/form-data' \
  -H 'Postman-Token: 669faafe-6625-0ee1-4054-fee882074171' \
  -H 'content-type: multipart/form-data; boundary=----WebKitFormBoundary7MA4YWxkTrZu0gW' \
  -F file=@"$m_binary_path")

echo -e "\\nUpload File Response"
echo "$postFileResponse" | jq -C
echo "Deployment done."