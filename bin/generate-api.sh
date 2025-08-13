#! /bin/bash

echo "Generating from Mintlify scraping"
npx @mintlify/scraping@latest openapi-file ../openapi.yaml -o api-reference
