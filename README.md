# Typesense with Healthcheck in Docker

[![Tests](https://github.com/batonogov/typesense/actions/workflows/tests.yaml/badge.svg)](https://github.com/batonogov/typesense/actions/workflows/tests.yaml)
[![Security Scan](https://github.com/batonogov/typesense/actions/workflows/security-scan.yaml/badge.svg)](https://github.com/batonogov/typesense/actions/workflows/security-scan.yaml)
[![Release](https://github.com/batonogov/typesense/actions/workflows/release.yaml/badge.svg)](https://github.com/batonogov/typesense/actions/workflows/release.yaml)

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

- Docker versions: 28.0.4 and above

## Test Suite

## Requirements

To run the tests, you need to install:

- [Task](https://taskfile.dev/) - a modern Make alternative
- [Docker](https://www.docker.com/)

### Installing Task

On macOS:

```bash
brew install go-task
```

## Usage

### Available Commands

- Run all tests:

```bash
task test
```

- Run API tests only:

```bash
task test-api
```

- Run performance tests only:

```bash
task test-performance
```

- Build test container:

```bash
task build-test-container
```

- Clean up test containers:

```bash
task clean
```

- View list of all available commands:

```bash
task --list
```

## Development Workflow

This repository includes several pipelines to streamline development:

### Local Development

Start a development environment with mounted data volume:

```bash
task dev
```

Stop the development environment:

```bash
task dev-stop
```

### Backup Data

Create a backup of data from a running development instance:

```bash
task backup
```

Backups are stored in `./backups/YYYY-MM-DD/` directory.

### Update Typesense Version

Update to a newer version of Typesense and run tests:

```bash
task update-typesense version=X.Y.Z
```

### Code Quality

Run linters and code quality checks:

```bash
task lint
```

### Documentation Generation

Generate documentation based on available tasks:

```bash
task docs
```

## CI/CD Pipelines

This repository uses GitHub Actions for CI/CD:

- **Tests**: Runs API and performance tests on all pushes and PRs to main branch
- **Security Scan**: Weekly vulnerability scanning with Trivy
- **Release**: Automatically creates releases when tags are pushed
- **Documentation**: Updates documentation when related files change
- **Update Typesense**: Checks for new Typesense versions weekly

## Test Parameters

The Taskfile.yaml defines the following variables:

- `TEST_API_KEY`: API key for testing (default: API_KEY_TEST)
- `TEST_TIMEOUT`: Container readiness timeout (default: 30 seconds)
- `TEST_CONTAINER_NAME`: Test container name (automatically generated)

### Running with Custom Parameters

```bash
TEST_API_KEY=my_custom_key TEST_TIMEOUT=60 task test
```

## Test Structure

The test suite consists of two main parts:

- `test-api`: Tests basic API functionality

  1. Collection creation
  1. Document operations
  1. Search functionality
  1. Cleanup operations

- `test-performance`: Tests system performance

  1. Search performance
  1. Document creation speed
  1. Document retrieval performance

Each test runs in a fresh container instance to ensure isolation.

## Troubleshooting

### Port Already in Use

If you get an error that port 8108 is already in use:

1. Check running containers:

```bash
docker ps
```

2. Stop the conflicting container:

```bash
docker stop <CONTAINER_ID>
```

3. Or use the cleanup command:

```bash
task clean
```

## Creating Tags

### Steps to Create a Tag

1. Ensure all changes are committed and pushed to the repository
1. Create a new tag with version:
   ```bash
   git tag -a v1.0.0 -m "Version 1.0.0"
   ```
1. Push the tag to the remote repository:
   ```bash
   git push origin v1.0.0
   ```

### Versioning Rules

Follow semantic versioning (SemVer) when creating tags:

- MAJOR version (1.0.0) - incompatible API changes
- MINOR version (0.1.0) - new functionality with backward compatibility
- PATCH version (0.0.1) - backward compatible bug fixes

## License

This project is licensed under the **MIT License**. See the [LICENSE](LICENSE) file for more details.
