# Typesense API Examples

This guide provides practical examples for using the Typesense API with the Docker image.

## Prerequisites

Ensure your Typesense container is running:

```bash
docker run -p 8108:8108 -e TYPESENSE_API_KEY=your-api-key ghcr.io/batonogov/typesense:latest
```

## Basic Configuration

All API requests require authentication via the `X-TYPESENSE-API-KEY` header:

```bash
export TYPESENSE_HOST="http://localhost:8108"
export TYPESENSE_API_KEY="your-api-key"
```

## Health Check

Verify your Typesense instance is running:

```bash
curl "$TYPESENSE_HOST/health"
```

Expected response:
```json
{"ok": true}
```

## Collections

### Create a Collection

```bash
curl -X POST \
  -H "X-TYPESENSE-API-KEY: $TYPESENSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "books",
    "fields": [
      {"name": "title", "type": "string"},
      {"name": "authors", "type": "string[]"},
      {"name": "publication_year", "type": "int32"},
      {"name": "ratings_count", "type": "int32"},
      {"name": "average_rating", "type": "float"},
      {"name": "image_url", "type": "string", "optional": true}
    ],
    "default_sorting_field": "ratings_count"
  }' \
  "$TYPESENSE_HOST/collections"
```

### List Collections

```bash
curl -H "X-TYPESENSE-API-KEY: $TYPESENSE_API_KEY" \
  "$TYPESENSE_HOST/collections"
```

### Get Collection Details

```bash
curl -H "X-TYPESENSE-API-KEY: $TYPESENSE_API_KEY" \
  "$TYPESENSE_HOST/collections/books"
```

### Delete a Collection

```bash
curl -X DELETE \
  -H "X-TYPESENSE-API-KEY: $TYPESENSE_API_KEY" \
  "$TYPESENSE_HOST/collections/books"
```

## Documents

### Add a Single Document

```bash
curl -X POST \
  -H "X-TYPESENSE-API-KEY: $TYPESENSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "1",
    "title": "The Great Gatsby",
    "authors": ["F. Scott Fitzgerald"],
    "publication_year": 1925,
    "ratings_count": 2165,
    "average_rating": 3.9,
    "image_url": "https://example.com/gatsby.jpg"
  }' \
  "$TYPESENSE_HOST/collections/books/documents"
```

### Add Multiple Documents (Bulk Import)

Create a file `books.jsonl` with one JSON object per line:

```jsonl
{"id": "1", "title": "The Great Gatsby", "authors": ["F. Scott Fitzgerald"], "publication_year": 1925, "ratings_count": 2165, "average_rating": 3.9}
{"id": "2", "title": "To Kill a Mockingbird", "authors": ["Harper Lee"], "publication_year": 1960, "ratings_count": 4912, "average_rating": 4.3}
{"id": "3", "title": "1984", "authors": ["George Orwell"], "publication_year": 1949, "ratings_count": 4780, "average_rating": 4.2}
{"id": "4", "title": "Pride and Prejudice", "authors": ["Jane Austen"], "publication_year": 1813, "ratings_count": 3456, "average_rating": 4.1}
{"id": "5", "title": "The Catcher in the Rye", "authors": ["J.D. Salinger"], "publication_year": 1951, "ratings_count": 2890, "average_rating": 3.8}
```

Import the documents:

```bash
curl -X POST \
  -H "X-TYPESENSE-API-KEY: $TYPESENSE_API_KEY" \
  -H "Content-Type: application/json" \
  --data-binary @books.jsonl \
  "$TYPESENSE_HOST/collections/books/documents/import"
```

### Get a Document

```bash
curl -H "X-TYPESENSE-API-KEY: $TYPESENSE_API_KEY" \
  "$TYPESENSE_HOST/collections/books/documents/1"
```

### Update a Document

```bash
curl -X PATCH \
  -H "X-TYPESENSE-API-KEY: $TYPESENSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "average_rating": 4.0,
    "ratings_count": 2200
  }' \
  "$TYPESENSE_HOST/collections/books/documents/1"
```

### Delete a Document

```bash
curl -X DELETE \
  -H "X-TYPESENSE-API-KEY: $TYPESENSE_API_KEY" \
  "$TYPESENSE_HOST/collections/books/documents/1"
```

## Search

### Basic Search

```bash
curl -H "X-TYPESENSE-API-KEY: $TYPESENSE_API_KEY" \
  "$TYPESENSE_HOST/collections/books/documents/search?q=gatsby&query_by=title"
```

### Multi-field Search

```bash
curl -H "X-TYPESENSE-API-KEY: $TYPESENSE_API_KEY" \
  "$TYPESENSE_HOST/collections/books/documents/search?q=fitzgerald&query_by=title,authors"
```

### Search with Filters

```bash
# Find books published after 1950
curl -H "X-TYPESENSE-API-KEY: $TYPESENSE_API_KEY" \
  "$TYPESENSE_HOST/collections/books/documents/search?q=*&query_by=title&filter_by=publication_year:>1950"

# Find books with high ratings
curl -H "X-TYPESENSE-API-KEY: $TYPESENSE_API_KEY" \
  "$TYPESENSE_HOST/collections/books/documents/search?q=*&query_by=title&filter_by=average_rating:>=4.0"

# Multiple filters
curl -H "X-TYPESENSE-API-KEY: $TYPESENSE_API_KEY" \
  "$TYPESENSE_HOST/collections/books/documents/search?q=*&query_by=title&filter_by=publication_year:>1900&&average_rating:>=4.0"
```

### Search with Sorting

```bash
# Sort by publication year (descending)
curl -H "X-TYPESENSE-API-KEY: $TYPESENSE_API_KEY" \
  "$TYPESENSE_HOST/collections/books/documents/search?q=*&query_by=title&sort_by=publication_year:desc"

# Sort by rating then by ratings count
curl -H "X-TYPESENSE-API-KEY: $TYPESENSE_API_KEY" \
  "$TYPESENSE_HOST/collections/books/documents/search?q=*&query_by=title&sort_by=average_rating:desc,ratings_count:desc"
```

### Pagination

```bash
# Get first page (10 results per page)
curl -H "X-TYPESENSE-API-KEY: $TYPESENSE_API_KEY" \
  "$TYPESENSE_HOST/collections/books/documents/search?q=*&query_by=title&page=1&per_page=10"

# Get second page
curl -H "X-TYPESENSE-API-KEY: $TYPESENSE_API_KEY" \
  "$TYPESENSE_HOST/collections/books/documents/search?q=*&query_by=title&page=2&per_page=10"
```

### Faceted Search

```bash
curl -H "X-TYPESENSE-API-KEY: $TYPESENSE_API_KEY" \
  "$TYPESENSE_HOST/collections/books/documents/search?q=*&query_by=title&facet_by=authors,publication_year"
```

## Advanced Search Features

### Typo Tolerance

```bash
# Search with typo tolerance (default: 2 typos allowed)
curl -H "X-TYPESENSE-API-KEY: $TYPESENSE_API_KEY" \
  "$TYPESENSE_HOST/collections/books/documents/search?q=gatsbby&query_by=title&num_typos=2"
```

### Prefix Matching

```bash
# Find books starting with "great"
curl -H "X-TYPESENSE-API-KEY: $TYPESENSE_API_KEY" \
  "$TYPESENSE_HOST/collections/books/documents/search?q=great&query_by=title&prefix=true"
```

### Highlighting

```bash
curl -H "X-TYPESENSE-API-KEY: $TYPESENSE_API_KEY" \
  "$TYPESENSE_HOST/collections/books/documents/search?q=gatsby&query_by=title&highlight_fields=title,authors&highlight_start_tag=<mark>&highlight_end_tag=</mark>"
```

### Geosearch (if you have location fields)

First, create a collection with geo fields:

```bash
curl -X POST \
  -H "X-TYPESENSE-API-KEY: $TYPESENSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "stores",
    "fields": [
      {"name": "name", "type": "string"},
      {"name": "location", "type": "geopoint"}
    ]
  }' \
  "$TYPESENSE_HOST/collections"
```

Add a document with location:

```bash
curl -X POST \
  -H "X-TYPESENSE-API-KEY: $TYPESENSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "1",
    "name": "Downtown Bookstore",
    "location": [40.7128, -74.0060]
  }' \
  "$TYPESENSE_HOST/collections/stores/documents"
```

Search by proximity:

```bash
# Find stores within 5km of coordinates
curl -H "X-TYPESENSE-API-KEY: $TYPESENSE_API_KEY" \
  "$TYPESENSE_HOST/collections/stores/documents/search?q=*&query_by=name&filter_by=location:(40.7128,-74.0060,5km)"
```

## Analytics and Insights

### Popular Queries

```bash
curl -H "X-TYPESENSE-API-KEY: $TYPESENSE_API_KEY" \
  "$TYPESENSE_HOST/analytics/queries?source=search_result"
```

### No Results Queries

```bash
curl -H "X-TYPESENSE-API-KEY: $TYPESENSE_API_KEY" \
  "$TYPESENSE_HOST/analytics/queries?source=search_result&filter_by=count:0"
```

## Error Handling

### Common HTTP Status Codes

- `200` - Success
- `201` - Created (for new documents/collections)
- `400` - Bad Request (invalid JSON or missing fields)
- `401` - Unauthorized (invalid API key)
- `404` - Not Found (collection or document doesn't exist)
- `409` - Conflict (document with same ID already exists)
- `422` - Unprocessable Entity (validation errors)

### Example Error Response

```json
{
  "message": "Bad JSON: Expected comma after object member"
}
```

## JavaScript Examples

### Using Fetch API

```javascript
const TYPESENSE_HOST = 'http://localhost:8108';
const API_KEY = 'your-api-key';

// Search function
async function searchBooks(query) {
  const response = await fetch(
    `${TYPESENSE_HOST}/collections/books/documents/search?q=${encodeURIComponent(query)}&query_by=title,authors`,
    {
      headers: {
        'X-TYPESENSE-API-KEY': API_KEY
      }
    }
  );
  
  if (!response.ok) {
    throw new Error(`HTTP error! status: ${response.status}`);
  }
  
  return await response.json();
}

// Add document function
async function addBook(book) {
  const response = await fetch(
    `${TYPESENSE_HOST}/collections/books/documents`,
    {
      method: 'POST',
      headers: {
        'X-TYPESENSE-API-KEY': API_KEY,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(book)
    }
  );
  
  if (!response.ok) {
    throw new Error(`HTTP error! status: ${response.status}`);
  }
  
  return await response.json();
}

// Usage examples
searchBooks('gatsby')
  .then(results => console.log('Search results:', results))
  .catch(error => console.error('Search error:', error));

addBook({
  id: '10',
  title: 'New Book',
  authors: ['New Author'],
  publication_year: 2024,
  ratings_count: 0,
  average_rating: 0
})
.then(result => console.log('Book added:', result))
.catch(error => console.error('Add error:', error));
```

### Using TypeScript Client

```typescript
import { Client } from 'typesense';

const client = new Client({
  nodes: [{
    host: 'localhost',
    port: 8108,
    protocol: 'http'
  }],
  apiKey: 'your-api-key',
  connectionTimeoutSeconds: 2
});

interface Book {
  id: string;
  title: string;
  authors: string[];
  publication_year: number;
  ratings_count: number;
  average_rating: number;
}

// Search with TypeScript
async function searchBooksTyped(query: string): Promise<Book[]> {
  const searchResults = await client
    .collections('books')
    .documents()
    .search({
      q: query,
      query_by: 'title,authors'
    });
  
  return searchResults.hits?.map(hit => hit.document as Book) || [];
}
```

## Python Examples

```python
import requests
import json

TYPESENSE_HOST = 'http://localhost:8108'
API_KEY = 'your-api-key'

headers = {
    'X-TYPESENSE-API-KEY': API_KEY,
    'Content-Type': 'application/json'
}

def search_books(query):
    """Search for books"""
    response = requests.get(
        f'{TYPESENSE_HOST}/collections/books/documents/search',
        params={
            'q': query,
            'query_by': 'title,authors'
        },
        headers={'X-TYPESENSE-API-KEY': API_KEY}
    )
    response.raise_for_status()
    return response.json()

def add_book(book):
    """Add a new book"""
    response = requests.post(
        f'{TYPESENSE_HOST}/collections/books/documents',
        json=book,
        headers=headers
    )
    response.raise_for_status()
    return response.json()

# Usage
try:
    results = search_books('gatsby')
    print(f"Found {len(results['hits'])} books")
    
    new_book = {
        'id': '20',
        'title': 'Python Guide',
        'authors': ['John Doe'],
        'publication_year': 2024,
        'ratings_count': 1,
        'average_rating': 5.0
    }
    
    added = add_book(new_book)
    print(f"Added book: {added['title']}")
    
except requests.exceptions.RequestException as e:
    print(f"API error: {e}")
```

## Performance Tips

1. **Use bulk import** for adding many documents
2. **Index only searchable fields** to reduce memory usage
3. **Use appropriate field types** (int32 instead of string for numbers)
4. **Set default_sorting_field** for better performance
5. **Use filters** to narrow down search results
6. **Implement pagination** for large result sets
7. **Cache frequent searches** on the client side

## Testing Your Setup

Use this comprehensive test to verify your Typesense setup:

```bash
#!/bin/bash

# Test script for Typesense
set -e

API_KEY="your-api-key"
HOST="http://localhost:8108"

echo "Testing Typesense API..."

# Test 1: Health check
echo "1. Health check..."
curl -f "$HOST/health" > /dev/null
echo "✓ Health check passed"

# Test 2: Create collection
echo "2. Creating test collection..."
curl -X POST \
  -H "X-TYPESENSE-API-KEY: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"name": "test", "fields": [{"name": "title", "type": "string"}]}' \
  "$HOST/collections" > /dev/null
echo "✓ Collection created"

# Test 3: Add document
echo "3. Adding test document..."
curl -X POST \
  -H "X-TYPESENSE-API-KEY: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"id": "1", "title": "Test Document"}' \
  "$HOST/collections/test/documents" > /dev/null
echo "✓ Document added"

# Test 4: Search
echo "4. Testing search..."
RESULT=$(curl -s -H "X-TYPESENSE-API-KEY: $API_KEY" \
  "$HOST/collections/test/documents/search?q=test&query_by=title")
FOUND=$(echo "$RESULT" | grep -o '"found":[0-9]*' | cut -d: -f2)
if [ "$FOUND" -gt 0 ]; then
  echo "✓ Search working (found $FOUND results)"
else
  echo "✗ Search failed"
  exit 1
fi

# Test 5: Cleanup
echo "5. Cleaning up..."
curl -X DELETE \
  -H "X-TYPESENSE-API-KEY: $API_KEY" \
  "$HOST/collections/test" > /dev/null
echo "✓ Cleanup completed"

echo "All tests passed! 🎉"
```

Save this as `test-typesense.sh`, make it executable, and run it to verify your setup is working correctly.