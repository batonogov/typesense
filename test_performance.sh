#!/bin/bash

set -e

API_KEY=$1
if [ -z "$API_KEY" ]; then
    echo "API key is required"
    exit 1
fi

# Check if wrk is installed
if ! command -v wrk &> /dev/null; then
    echo "wrk is not installed. Please install it first."
    echo "On macOS: brew install wrk"
    echo "On Ubuntu: sudo apt-get install wrk"
    exit 1
fi

# Base URL for tests
BASE_URL="http://localhost:8108"

# Create test collection
echo "Creating test collection..."
curl -X POST \
    -H "X-TYPESENSE-API-KEY: $API_KEY" \
    -H "Content-Type: application/json" \
    -d '{
        "name": "books",
        "fields": [
            {"name": "title", "type": "string"},
            {"name": "authors", "type": "string[]"},
            {"name": "publication_year", "type": "int32"}
        ]
    }' \
    "$BASE_URL/collections"

# Add test document
echo "Adding test document..."
curl -X POST \
    -H "X-TYPESENSE-API-KEY: $API_KEY" \
    -H "Content-Type: application/json" \
    -d '{"id": "1", "title": "Test Book", "authors": ["Test Author"], "publication_year": 2023}' \
    "$BASE_URL/collections/books/documents"

# Function to run tests
run_test() {
    local endpoint=$1
    local method=$2
    local body=$3
    local threads=$4
    local connections=$5
    local duration=$6
    local description=$7

    echo "Running test: $description"
    echo "Endpoint: $endpoint"
    echo "Method: $method"
    echo "Threads: $threads"
    echo "Connections: $connections"
    echo "Duration: ${duration}s"
    echo "----------------------------------------"

    if [ "$method" = "POST" ] && [ -n "$body" ]; then
        wrk -t"$threads" -c"$connections" -d"${duration}"s \
            -H "X-TYPESENSE-API-KEY: $API_KEY" \
            -H "Content-Type: application/json" \
            -s <(echo "wrk.method = \"$method\"") \
            -s <(echo "wrk.body = '$body'") \
            "$BASE_URL$endpoint"
    else
        wrk -t"$threads" -c"$connections" -d"${duration}"s \
            -H "X-TYPESENSE-API-KEY: $API_KEY" \
            "$BASE_URL$endpoint"
    fi

    echo -e "\n"
}

# Search test
run_test "/collections/books/documents/search?q=test&query_by=title" "GET" "" 4 100 30 "Search endpoint test"

# Document creation test
SAMPLE_DOC='{"id": "2", "title": "Another Test Book", "authors": ["Another Author"], "publication_year": 2024}'
run_test "/collections/books/documents" "POST" "$SAMPLE_DOC" 4 50 30 "Document creation test"

# Document retrieval test
run_test "/collections/books/documents/1" "GET" "" 4 100 30 "Document retrieval test"

# Clean up test collection
echo "Cleaning up test collection..."
curl -X DELETE \
    -H "X-TYPESENSE-API-KEY: $API_KEY" \
    "$BASE_URL/collections/books"

echo "Performance tests completed successfully!"
