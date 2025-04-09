# Typesense with Healthcheck in Docker

[![Tests](https://github.com/batonogov/typesense/actions/workflows/tests.yaml/badge.svg)](https://github.com/batonogov/typesense/actions/workflows/tests.yaml)

This repository provides a Docker image based on Typesense with an integrated healthcheck.
The healthcheck uses the curl utility to verify the service's health by pinging its endpoint.

## Features

- **Official Typesense Image**: Built on top of the official typesense Docker image
- **Healthcheck**: Built-in healthcheck performs requests to <http://localhost:8108/health> to ensure service availability
- **Production-Ready**: Suitable for both development and production environments
- **Easy Configuration**: Simple environment variables for customization
- **Monitoring Ready**: Healthcheck endpoint for container orchestration systems

## Quick Start

### Prerequisites

- Docker installed on your system
- Basic understanding of Docker concepts

### Installation

Pull the latest image:

```bash
docker pull ghcr.io/batonogov/typesense:latest
```

### Basic Usage

Run the container:

```bash
docker run \
  -p 8108:8108 \
  -e TYPESENSE_API_KEY=your-api-key \
  ghcr.io/batonogov/typesense:latest
```

### Configuration

Available environment variables:

- `TYPESENSE_API_KEY`: Your Typesense API key (required)
- `TYPESENSE_DATA_DIR`: Data directory path (default: /data)
- `TYPESENSE_LISTEN_ADDRESS`: Listen address (default: 0.0.0.0)
- `TYPESENSE_LISTEN_PORT`: Listen port (default: 8108)

Example with custom configuration:

```bash
docker run \
  -p 8108:8108 \
  -e TYPESENSE_API_KEY=your-api-key \
  -e TYPESENSE_DATA_DIR=/custom/data \
  -v /path/to/data:/custom/data \
  ghcr.io/batonogov/typesense:latest
```

## Healthcheck Details

The container includes a healthcheck that:

- Runs every 30 seconds
- Has a timeout of 10 seconds
- Retries 3 times before marking as unhealthy
- Uses the `/health` endpoint to verify service status

## Contributing

We welcome contributions! Please feel free to submit a Pull Request.
For major changes, please open an issue first to discuss what you would like to change.

## Version Compatibility

This image is compatible with:

- Typesense versions: 0.28.0 and above
- Docker versions: 28.0.4 and above

## License

This project is licensed under the **MIT License**. See the [LICENSE](LICENSE) file for more details.
