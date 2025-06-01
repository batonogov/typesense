# Development Guide

This guide helps you set up a development environment for the Typesense Docker project.

## Prerequisites

### Required Tools

- **Docker**: Version 20.10+ ([Install Docker](https://docs.docker.com/get-docker/))
- **Docker Compose**: Version 2.0+ (included with Docker Desktop)
- **Task**: Modern Make alternative ([Install Task](https://taskfile.dev/installation/))
- **Git**: Version control system
- **curl**: For API testing (usually pre-installed)

### Optional Tools

- **wrk**: HTTP benchmarking tool (for performance tests)
- **pre-commit**: Git hooks framework
- **hadolint**: Dockerfile linter
- **shellcheck**: Shell script analyzer

## Quick Setup

### 1. Clone Repository

```bash
git clone https://github.com/batonogov/typesense.git
cd typesense
```

### 2. Install Task (if not installed)

**macOS:**
```bash
brew install go-task
```

**Linux:**
```bash
# Install from GitHub releases
sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d
```

**Windows:**
```bash
# Using Chocolatey
choco install go-task
```

### 3. Install Development Dependencies

```bash
# Install pre-commit
pip install pre-commit

# Install pre-commit hooks
pre-commit install

# Install additional tools (macOS)
brew install hadolint shellcheck wrk

# Install additional tools (Ubuntu)
sudo apt-get update
sudo apt-get install shellcheck
```

### 4. Verify Setup

```bash
# Check all tools are available
task --version
docker --version
docker-compose --version
pre-commit --version

# Run initial tests
task test
```

## Development Workflow

### Daily Development

1. **Start Development Environment**
   ```bash
   task dev
   ```

2. **Make Changes**
   - Edit Dockerfile, scripts, or documentation
   - Test changes locally

3. **Run Tests**
   ```bash
   task test           # Run all tests
   task test-api       # API tests only
   task test-performance  # Performance tests only
   ```

4. **Validate Changes**
   ```bash
   task lint           # Run linters
   pre-commit run --all-files  # Run all hooks
   ```

5. **Stop Development Environment**
   ```bash
   task dev-stop
   ```

### Available Commands

Run `task --list` to see all available commands:

#### Development
- `task dev` - Start development environment
- `task dev-stop` - Stop development environment
- `task backup` - Backup data from running instance
- `task clean` - Clean up test containers

#### Testing
- `task test` - Run all tests
- `task test-api` - Run API functionality tests
- `task test-performance` - Run performance tests
- `task build-test-container` - Build test container

#### Code Quality
- `task lint` - Run linters and code quality checks
- `task validate-badges` - Validate README badges
- `task docs` - Generate documentation

#### Release Management
- `task create-stable VERSION=X.Y` - Create stable release
- `task create-rc VERSION=X.Y` - Create release candidate
- `task list-releases` - List recent releases

## Project Structure

```
typesense/
├── .github/                 # GitHub workflows and templates
│   ├── workflows/          # CI/CD pipelines
│   └── ISSUE_TEMPLATE/     # Issue templates
├── docs/                   # Documentation
├── examples/               # Usage examples
│   ├── docker-compose.dev.yml
│   ├── docker-compose.prod.yml
│   ├── kubernetes.yaml
│   └── api-examples.md
├── scripts/                # Utility scripts
│   ├── create-release.sh
│   ├── validate-badges.sh
│   └── validate-version.sh
├── Dockerfile             # Main Docker image definition
├── Taskfile.yaml         # Task automation
├── test_api.sh           # API test script
├── test_performance.sh   # Performance test script
├── TROUBLESHOOTING.md    # Troubleshooting guide
├── DEVELOPMENT.md        # This file
└── README.md            # Main documentation
```

## Development Environment Details

### Container Configuration

The development environment runs with:
- **API Key**: `dev-api-key-12345`
- **Port**: `8108`
- **Data Directory**: `./data` (mounted from host)
- **Log Level**: `INFO`
- **CORS**: Enabled for development

### Environment Variables

```bash
# Development defaults
TYPESENSE_API_KEY=dev-api-key-12345
TYPESENSE_DATA_DIR=/data
TYPESENSE_LISTEN_ADDRESS=0.0.0.0
TYPESENSE_LISTEN_PORT=8108
```

### Test Configuration

```bash
# Test environment variables
TEST_API_KEY=API_KEY_TEST
TEST_TIMEOUT=30
TEST_CONTAINER_NAME=typesense-test-{timestamp}
```

## Testing Guide

### Running Tests

```bash
# Full test suite
task test

# Individual test types
task test-api           # Basic API functionality
task test-performance   # Performance benchmarks

# Custom parameters
TEST_API_KEY=my_key TEST_TIMEOUT=60 task test
```

### Test Structure

**API Tests (`test_api.sh`)**:
1. Collection creation
2. Document operations (CRUD)
3. Search functionality
4. Cleanup operations

**Performance Tests (`test_performance.sh`)**:
1. Search endpoint benchmarking
2. Document creation performance
3. Document retrieval speed
4. Resource usage analysis

### Writing New Tests

1. **Add to existing scripts** for simple tests
2. **Create new test files** for complex scenarios
3. **Update Taskfile.yaml** to include new test tasks
4. **Follow naming convention**: `test_*.sh`

Example test function:
```bash
test_new_feature() {
    echo "Testing new feature..."
    
    # Setup
    local collection="test_$(date +%s)"
    
    # Test implementation
    curl -X POST -H "X-TYPESENSE-API-KEY: $API_KEY" \
         "$API_URL/collections" -d "..."
    
    # Verification
    if [ $? -eq 0 ]; then
        echo "✓ New feature test passed"
    else
        echo "✗ New feature test failed"
        return 1
    fi
    
    # Cleanup
    curl -X DELETE -H "X-TYPESENSE-API-KEY: $API_KEY" \
         "$API_URL/collections/$collection"
}
```

## Code Quality Standards

### Pre-commit Hooks

Automatic checks on every commit:
- **Dockerfile linting** (hadolint)
- **Shell script analysis** (shellcheck)
- **YAML validation** (yamllint)
- **Markdown linting** (markdownlint)
- **Security scanning** (detect-secrets)
- **Trailing whitespace removal**
- **File size checks**

### Linting Rules

**Dockerfile**:
- Use specific version tags
- Minimize layers
- Use non-root users where possible
- Include health checks

**Shell Scripts**:
- Use `set -e` for error handling
- Quote variables properly
- Use meaningful function names
- Include error messages

**Documentation**:
- Use consistent markdown formatting
- Include code examples
- Keep line length reasonable
- Update table of contents

## Debugging

### Container Debugging

```bash
# Access running container
docker exec -it typesense-dev /bin/sh

# View container logs
docker logs typesense-dev

# Monitor resource usage
docker stats typesense-dev

# Inspect container configuration
docker inspect typesense-dev
```

### API Debugging

```bash
# Test health endpoint
curl http://localhost:8108/health

# Test with verbose output
curl -v -H "X-TYPESENSE-API-KEY: dev-api-key-12345" \
     http://localhost:8108/collections

# Check API key authentication
curl -H "X-TYPESENSE-API-KEY: wrong-key" \
     http://localhost:8108/collections
```

### Development Issues

**Port Already in Use**:
```bash
# Find process using port 8108
lsof -i :8108
# or
netstat -tulpn | grep 8108

# Stop conflicting services
task clean
```

**Permission Issues**:
```bash
# Fix data directory permissions
sudo chown -R $USER:$USER ./data

# Use Docker volumes instead
docker volume create typesense_dev_data
```

**Container Won't Start**:
```bash
# Check Docker daemon
docker info

# View detailed logs
docker logs typesense-dev --details

# Run in interactive mode
docker run -it --rm ghcr.io/batonogov/typesense:latest /bin/sh
```

## Contributing Guidelines

### Branch Naming

- `feature/description` - New features
- `fix/description` - Bug fixes
- `docs/description` - Documentation updates
- `chore/description` - Maintenance tasks

### Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add new API endpoint for bulk operations
fix: resolve healthcheck timeout issue
docs: update troubleshooting guide
chore: update dependencies
```

### Pull Request Process

1. **Create Feature Branch**
   ```bash
   git checkout -b feature/my-new-feature
   ```

2. **Make Changes and Test**
   ```bash
   # Make changes
   task test
   task lint
   ```

3. **Commit Changes**
   ```bash
   git add .
   git commit -m "feat: add my new feature"
   ```

4. **Push and Create PR**
   ```bash
   git push origin feature/my-new-feature
   # Create PR via GitHub UI
   ```

### Code Review Checklist

- [ ] All tests pass
- [ ] Documentation updated
- [ ] Pre-commit hooks pass
- [ ] No security vulnerabilities
- [ ] Backward compatibility maintained
- [ ] Performance impact considered

## Release Process

### Creating Releases

```bash
# Create release candidate
task create-rc VERSION=29.1

# Create stable release
task create-stable VERSION=29.1

# List recent releases
task list-releases
```

### Version Management

- **Stable releases**: `v29.1`
- **Release candidates**: `v29.1.rc1`
- **Development**: `main` branch

### Release Checklist

- [ ] All tests pass
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
- [ ] Version bumped in Dockerfile
- [ ] Security scan passes
- [ ] Performance regression check

## IDE Configuration

### VS Code

Recommended extensions (create `.vscode/extensions.json`):
```json
{
  "recommendations": [
    "ms-azuretools.vscode-docker",
    "ms-vscode.vscode-json",
    "redhat.vscode-yaml",
    "davidanson.vscode-markdownlint",
    "timonwong.shellcheck",
    "exiasr.hadolint"
  ]
}
```

### Development Container

Create `.devcontainer/devcontainer.json`:
```json
{
  "name": "Typesense Development",
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/devcontainers/features/docker-in-docker:2": {}
  },
  "postCreateCommand": "bash .devcontainer/setup.sh",
  "forwardPorts": [8108],
  "remoteUser": "vscode"
}
```

## Performance Optimization

### Development Performance

```bash
# Use BuildKit for faster builds
export DOCKER_BUILDKIT=1

# Prune Docker system regularly
docker system prune -f

# Use multi-stage builds
docker build --target development .
```

### Resource Monitoring

```bash
# Monitor container resources
watch docker stats

# Check disk usage
docker system df

# Monitor host resources
htop  # or top
```

## Troubleshooting Development Issues

### Common Problems

**Task not found**:
```bash
# Install Task
brew install go-task
# or download from GitHub releases
```

**Docker permission denied**:
```bash
# Add user to docker group (Linux)
sudo usermod -aG docker $USER
# Log out and back in
```

**Pre-commit hooks failing**:
```bash
# Update hooks
pre-commit autoupdate

# Skip hooks temporarily
git commit --no-verify
```

**Tests timing out**:
```bash
# Increase timeout
TEST_TIMEOUT=60 task test

# Check container health
docker ps
task clean
```

### Getting Help

1. **Check logs**: Always start with container and test logs
2. **Review documentation**: Check README and troubleshooting guide
3. **Search issues**: Look through GitHub issues
4. **Ask for help**: Create a new issue with details

### Development Resources

- [Typesense Documentation](https://typesense.org/docs/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Task Documentation](https://taskfile.dev/)
- [Pre-commit Documentation](https://pre-commit.com/)

---

Happy coding! 🚀