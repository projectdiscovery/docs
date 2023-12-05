#! /bin/bash

echo "Downloading file"
wget -O openapi.yaml https://stoplight.io/api/v1/projects/projectdiscovery/pdcp-api-new/nodes/openapi.yaml\?fromExportButton\=true\&snapshotType\=http_service

echo "Generating from Mintlify scraping"
npx @mintlify/scraping@latest openapi-file openapi.yaml -o api-reference
