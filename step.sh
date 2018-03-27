#!/bin/bash

# $base_api_url := The appmanager's base API URL
# $appmanager_app_id := The appmanager id of the app where the binary should be uploaded to
# $binary_path := The to be uploaded binary
# $binary_version_code := The version code of the new binary
# $notes := notes for this version, e.g. commit message or changelog
# $build_url := the url to the build of this version
# $identifier := the identifier of the binary

red=$'\e[1;31m'
grn=$'\e[1;32m'
yel=$'\e[1;33m'
blu=$'\e[1;34m'
mag=$'\e[1;35m'
cyn=$'\e[1;36m'
end=$'\e[0m'

while [ $# -gt 0 ]; do
   if [[ $1 == *"--"* ]]; then
        v="${1/--/}"
        declare "$v"="$2"
   fi
  shift
done

# "buildUrl": "asd",
#  "identifier": "asd.asd.asd",

m_base_api_url=${base_api_url}
m_appmanager_app_id=${appmanager_id}
m_binary_path=${binary_path}
m_binary_version_code=${binary_version_code}
m_notes=${notes}
m_build_url=${build_url} 
m_binary_identifier=${binary_identifier}


if [[ -z "$m_appmanager_app_id" ]]; then
  echo "using command line parameter"
  m_base_api_url=$base_api_url
  m_appmanager_app_id=$appmanager_app_id
  m_binary_path=$binary_path
  m_binary_version_code=$binary_version_code
  m_notes=$notes
  m_build_url=$build_url
  m_binary_identifier=$binary_identifier
fi

echo "Received Arguments:"
echo -e "* Base API URL: $m_base_api_url"
echo -e "* Appmanager App Id: $m_appmanager_app_id"
echo -e "* Binary Path: $m_binary_path"
echo -e "* Version Code: $m_binary_version_code"
echo "* Notes: $m_notes"
echo -e "------"

# Make sure to "flatten" the notes string
m_notes=$(cat  << EOF
$(echo $m_notes)
EOF
)

# Bitrise is inserting some weird whitespace after newlines, remove those.
toBePlacedString="\n "
replaceString="\n"
m_notes=${m_notes//"$toBePlacedString"/"$replaceString"}

# Escape quotes
toBePlacedString2='"'
replaceString2='\"'
m_notes=${m_notes//"$toBePlacedString2"/"$replaceString2"}

# TODO: Check if all input arguments are set
if ! type "jq" > /dev/null; then
  echo "Exit since jq not availbable" && exit 1
fi

if ! type "bc" > /dev/null; then
  echo "Exit since bc not availbable" && exit 1
fi


# send and store the new version
echo -e "\\n---------------------------POSTING NEW VERSION----------------------------------"
postVersionPayload="{ 
  \"versionNr\": \"$m_binary_version_code\",
  \"notes\": \"$m_notes\",
  \"buildUrl\": \"$m_build_url\",
  \"identifier\": \"$m_binary_identifier\",
  \"app\": {
    \"id\": \"$m_appmanager_app_id\"
  }
}"

echo "******** postVersionPayload ********"
echo $postVersionPayload
echo "************************************"

postVersionResponse=$(curl -s -S -X POST \
  "$m_base_api_url"/apps/"$m_appmanager_app_id"/versions/ \
  -H "Cache-Control: no-cache" \
  -H "Content-Type: application/json" \
  -d "$postVersionPayload")

echo "${cyn}Response:${end} "
echo "cURL exit code: $?"
echo -e "Post Version Response:"
echo "$postVersionResponse"
# parse the new version id from the response body and make the string to a number
newVersionId=$(echo "$postVersionResponse" | jq .id | bc)
echo "New Version ID: $newVersionId"

if [[ -z "$newVersionId" ]]; then
  echo "${red}Something went wrong: New version id is empty.${end}"
  exit 1
fi

echo -e "--------------------------------------------------------------------------------\\n"

# send the actual binary for the newly created version
echo -e "\\n---------------------------UPLOADING BINARY-------------------------------------"
postFileResponse=$(curl -s -S -X POST \
  "$m_base_api_url"/version/"$newVersionId"/file/ \
  -H 'Cache-Control: no-cache' \
  -H 'Content-Type: multipart/form-data' \
  -H 'Postman-Token: 669faafe-6625-0ee1-4054-fee882074171' \
  -H 'content-type: multipart/form-data; boundary=----WebKitFormBoundary7MA4YWxkTrZu0gW' \
  -F file=@"$m_binary_path")

echo "${cyn}Response:${end} "
echo "cURL exit code: $?"
echo "$postFileResponse"


fileUrl=$(echo "$postFileResponse" | jq .fileUrl | bc) 
if [[ -z "$newVersionId" ]]; then
  echo "${red}Something went wrong: Received file url is empty.${end}"
  exit 1
fi
echo -e "--------------------------------------------------------------------------------\\\n"


echo "${grn}Deployment done.${end}"