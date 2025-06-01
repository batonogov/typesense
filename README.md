# Typesense Docker with Healthcheck

[![Tests](https://github.com/batonogov/typesense/actions/workflows/tests.yaml/badge.svg?style=flat-square)](https://github.com/batonogov/typesense/actions/workflows/tests.yaml)
[![Security Scan](https://github.com/batonogov/typesense/actions/workflows/security-scan.yaml/badge.svg?style=flat-square)](https://github.com/batonogov/typesense/actions/workflows/security-scan.yaml)
[![Release](https://github.com/batonogov/typesense/actions/workflows/release-publisher.yaml/badge.svg?style=flat-square)](https://github.com/batonogov/typesense/actions/workflows/release-publisher.yaml)

[![Latest Release](https://img.shields.io/github/v/release/batonogov/typesense?style=flat-square)](https://github.com/batonogov/typesense/releases/latest)
[![Docker Image Size](https://img.shields.io/docker/image-size/ghcr.io/batonogov/typesense/latest?style=flat-square&label=image%20size)](https://github.com/batonogov/typesense/pkgs/container/typesense)
[![License](https://img.shields.io/github/license/batonogov/typesense?style=flat-square)](LICENSE)

## Overview

Production-ready Docker image for Typesense with built-in healthcheck

## About

This project provides a Docker image based on the official
[Typesense](https://typesense.org/) search engine with added health monitoring
capabilities. It's designed for production environments where container health
monitoring is essential.

### Key Features

- 🏥 **Built-in Healthcheck** - Automatic health monitoring via `/health`
  endpoint
- 🐳 **Production Ready** - Optimized for container orchestration systems
- 🔒 **Security Focused** - Regular vulnerability scanning and signed images
- 🏗️ **Multi-Platform** - Supports AMD64 and ARM64 architectures
- ⚡ **Lightweight** - Minimal overhead with only curl added for healthcheck

## Quick Start

### Docker Run

```bash
docker run -d \
  --name typesense \
  -p 8108:8108 \
  -e TYPESENSE_API_KEY=your-secret-key \
  -v typesense_data:/data \
  ghcr.io/batonogov/typesense:latest
```

### Docker Compose

```yaml
version: '3.8'
services:
  typesense:
    image: ghcr.io/batonogov/typesense:latest
    ports:
      - "8108:8108"
    environment:
      - TYPESENSE_API_KEY=your-secret-key
    volumes:
      - typesense_data:/data
    restart: unless-stopped

volumes:
  typesense_data:
```

### Verify Setup

```bash
# Check health
curl http://localhost:8108/health

# Test API
curl -H "X-TYPESENSE-API-KEY: your-secret-key" \
     http://localhost:8108/collections
```

## Configuration

### Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `TYPESENSE_API_KEY` | API key for authentication | - | ✅ |
| `TYPESENSE_DATA_DIR` | Data directory path | `/data` | ❌ |
| `TYPESENSE_LISTEN_PORT` | Server port | `8108` | ❌ |

### Healthcheck

The container includes automatic health monitoring:

- **Endpoint**: `GET /health`
- **Interval**: Every 30 seconds
- **Timeout**: 10 seconds
- **Retries**: 3 attempts before marking unhealthy

## Available Images

### Tags

- `latest` - Latest stable release
- `v29.0` - Specific version
- `v29.0.rc1` - Release candidates

### Registries

```bash
# GitHub Container Registry (recommended)
ghcr.io/batonogov/typesense:latest

# Docker Hub
batonogov/typesense:latest
```

## Development

### Prerequisites

- [Docker](https://www.docker.com/)
- [Task](https://taskfile.dev/) (optional, for automation)

### Available Commands

```bash
# Start development environment
task dev

# Run tests
task test

# Build and test locally
task build-test-container
task test-api

# View all commands
task --list
```

## Documentation

- 🔧 [Troubleshooting](TROUBLESHOOTING.md) - Common issues and solutions
- 🛠 [Development Guide](DEVELOPMENT.md) - Contributing and development
  setup

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE)
file for details.

## Acknowledgments

- [Typesense Team](https://github.com/typesense/typesense) for the excellent
  search engine
- Community contributors for feedback and improvements

---

**[⭐ Star this repo](https://github.com/batonogov/typesense/stargazers)**
if you found it helpful!
