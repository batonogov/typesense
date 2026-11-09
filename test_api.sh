#!/bin/bash

set -euo pipefail

API_KEY=${1:?"Usage: $0 API_KEY"}
API_URL="${API_URL:-http://localhost:8108}"

api_request() {
    local method=$1
    local endpoint=$2
    local data=${3:-}
    local args=(
        --fail-with-body
        --silent
        --show-error
        --connect-timeout 5
        --max-time 30
        --request "$method"
        --header "X-TYPESENSE-API-KEY: $API_KEY"
        --header "Content-Type: application/json"
    )

    if [[ -n "$data" ]]; then
        args+=(--data "$data")
    fi

    curl "${args[@]}" "$API_URL$endpoint"
}

echo "Testing collection creation..."
COLLECTION_NAME="test_collection_$(date +%s)"
CREATE_RESPONSE=$(api_request "POST" "/collections" "{
    \"name\": \"$COLLECTION_NAME\",
    \"fields\": [
        {\"name\": \"title\", \"type\": \"string\"},
        {\"name\": \"description\", \"type\": \"string\"}
    ]
}")
RESPONSE="$CREATE_RESPONSE" python3 -c '
import json
import os
import sys

response = json.loads(os.environ["RESPONSE"])
if response.get("name") != sys.argv[1]:
    raise SystemExit(f"Unexpected collection response: {response}")
' "$COLLECTION_NAME"

echo "Testing document addition..."
DOCUMENT_RESPONSE=$(api_request "POST" "/collections/$COLLECTION_NAME/documents" "{
    \"title\": \"Test Document\",
    \"description\": \"This is a test document\"
}")
RESPONSE="$DOCUMENT_RESPONSE" python3 -c '
import json
import os

response = json.loads(os.environ["RESPONSE"])
if not response.get("id"):
    raise SystemExit(f"Document response has no ID: {response}")
'

echo "Testing search..."
SEARCH_RESPONSE=$(api_request "GET" "/collections/$COLLECTION_NAME/documents/search?q=test&query_by=title")
RESPONSE="$SEARCH_RESPONSE" python3 -c '
import json
import os

response = json.loads(os.environ["RESPONSE"])
hits = response.get("hits", [])
if response.get("found", 0) < 1 or not any(
    hit.get("document", {}).get("title") == "Test Document" for hit in hits
):
    raise SystemExit(f"Expected document was not found: {response}")
'

echo "Testing collection deletion..."
DELETE_RESPONSE=$(api_request "DELETE" "/collections/$COLLECTION_NAME")
RESPONSE="$DELETE_RESPONSE" python3 -c '
import json
import os
import sys

response = json.loads(os.environ["RESPONSE"])
if response.get("name") != sys.argv[1]:
    raise SystemExit(f"Unexpected deletion response: {response}")
' "$COLLECTION_NAME"

echo "All API tests completed successfully!"
