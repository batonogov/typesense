#!/bin/bash

set -e

API_KEY=$1
API_URL="http://localhost:8108"

# Function for making API requests
api_request() {
    local method=$1
    local endpoint=$2
    local data=$3

    curl -s -X "$method" \
        -H "X-TYPESENSE-API-KEY: $API_KEY" \
        -H "Content-Type: application/json" \
        "$API_URL$endpoint" \
        ${data:+--data "$data"}
}

# Test collection creation
echo "Testing collection creation..."
COLLECTION_NAME="test_collection_$(date +%s)"
api_request "POST" "/collections" "{
    \"name\": \"$COLLECTION_NAME\",
    \"fields\": [
        {\"name\": \"title\", \"type\": \"string\"},
        {\"name\": \"description\", \"type\": \"string\"}
    ]
}"

# Test document addition
echo "Testing document addition..."
api_request "POST" "/collections/$COLLECTION_NAME/documents" "{
    \"title\": \"Test Document\",
    \"description\": \"This is a test document\"
}"

# Test search
echo "Testing search..."
api_request "GET" "/collections/$COLLECTION_NAME/documents/search?q=test"

# Test collection deletion
echo "Testing collection deletion..."
api_request "DELETE" "/collections/$COLLECTION_NAME"

echo "All API tests completed successfully!"
