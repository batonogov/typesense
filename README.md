# Typesense with Healthcheck in Docker

<div align="center">

[![Tests](https://github.com/batonogov/typesense/actions/workflows/tests.yaml/badge.svg?style=flat-square)](https://github.com/batonogov/typesense/actions/workflows/tests.yaml)
[![Security Scan](https://github.com/batonogov/typesense/actions/workflows/security-scan.yaml/badge.svg?style=flat-square)](https://github.com/batonogov/typesense/actions/workflows/security-scan.yaml)
[![Release](https://github.com/batonogov/typesense/actions/workflows/release-publisher.yaml/badge.svg?style=flat-square)](https://github.com/batonogov/typesense/actions/workflows/release-publisher.yaml)

[![License](https://img.shields.io/github/license/batonogov/typesense?style=flat-square)](LICENSE)
[![Latest Release](https://img.shields.io/github/v/release/batonogov/typesense?style=flat-square)](https://github.com/batonogov/typesense/releases/latest)
[![Docker Image Size](https://img.shields.io/docker/image-size/ghcr.io/batonogov/typesense/latest?style=flat-square&label=image%20size)](https://github.com/batonogov/typesense/pkgs/container/typesense)

**Production-ready Docker image for Typesense with built-in healthcheck and monitoring**

[🚀 Quick Start](#-quick-start) • [📚 Documentation](#-documentation) • [💡 Examples](#-examples) • [🔧 Troubleshooting](#-troubleshooting) • [🛠 Development](#-development)

</div>

---

## ✨ Features

- 🔥 **Official Typesense Base** - Built on top of the official typesense/typesense image
- 🩺 **Built-in Healthcheck** - Automatic health monitoring with `/health` endpoint
- 🐳 **Production Ready** - Optimized for both development and production environments
- 📊 **Monitoring Ready** - Compatible with container orchestration systems
- 🏗️ **Multi-Platform** - Supports linux/amd64 and linux/arm64 architectures
- 🔒 **Security Focused** - Regular security scanning and updates

## 🚀 Quick Start

### One-line Docker Run

```bash
docker run -p 8108:8108 -e TYPESENSE_API_KEY=your-api-key ghcr.io/batonogov/typesense:latest
```

### Docker Compose (Recommended)

Create `docker-compose.yml`:

```yaml
version: '3.8'
services:
  typesense:
    image: ghcr.io/batonogov/typesense:latest
    ports:
      - "8108:8108"
    environment:
      - TYPESENSE_API_KEY=your-secret-api-key
      - TYPESENSE_DATA_DIR=/data
    volumes:
      - typesense_data:/data
    restart: unless-stopped
    deploy:
      resources:
        limits:
          memory: 1G
        reservations:
          memory: 512M

volumes:
  typesense_data:
```

Then run:

```bash
docker-compose up -d
```

### Verify Installation

```bash
# Check health
curl http://localhost:8108/health

# Test API
curl -H "X-TYPESENSE-API-KEY: your-api-key" http://localhost:8108/collections
```

## 📚 Documentation

### Configuration

#### Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `TYPESENSE_API_KEY` | Your Typesense API key | - | ✅ |
| `TYPESENSE_DATA_DIR` | Data directory path | `/data` | ❌ |
| `TYPESENSE_LISTEN_ADDRESS` | Listen address | `0.0.0.0` | ❌ |
| `TYPESENSE_LISTEN_PORT` | Listen port | `8108` | ❌ |

#### Advanced Configuration

```bash
docker run \
  -p 8108:8108 \
  -e TYPESENSE_API_KEY=your-api-key \
  -e TYPESENSE_DATA_DIR=/custom/data \
  -e TYPESENSE_LISTEN_PORT=8108 \
  -v /host/data:/custom/data \
  ghcr.io/batonogov/typesense:latest
```

### Healthcheck Details

The container includes a built-in healthcheck that:

- **Interval**: Runs every 30 seconds
- **Timeout**: 10 seconds per check
- **Retries**: 3 attempts before marking unhealthy
- **Start Period**: 30 seconds initial grace period
- **Endpoint**: `GET /health` on port 8108

You can customize healthcheck in docker-compose:

```yaml
healthcheck:
  test: ["CMD", "curl", "--fail", "http://localhost:8108/health"]
  interval: 15s
  timeout: 5s
  retries: 5
  start_period: 60s
```

## 💡 Examples

### Ready-to-Use Examples

- **[Development Setup](examples/docker-compose.dev.yml)** - Complete development environment with test data
- **[Production Setup](examples/docker-compose.prod.yml)** - Production-ready configuration with monitoring
- **[Kubernetes Deployment](examples/kubernetes.yaml)** - Complete K8s manifests with autoscaling
- **[API Usage Guide](examples/api-examples.md)** - Comprehensive API examples and code samples

### Development Setup

```yaml
# docker-compose.dev.yml
version: '3.8'
services:
  typesense:
    image: ghcr.io/batonogov/typesense:latest
    ports:
      - "8108:8108"
    environment:
      - TYPESENSE_API_KEY=dev-api-key
    volumes:
      - ./data:/data
    command: --data-dir /data --api-key=dev-api-key --enable-cors
```

### Production Setup with Monitoring

```yaml
# docker-compose.prod.yml
version: '3.8'
services:
  typesense:
    image: ghcr.io/batonogov/typesense:latest
    ports:
      - "8108:8108"
    environment:
      - TYPESENSE_API_KEY_FILE=/run/secrets/api_key
    volumes:
      - typesense_data:/data
    secrets:
      - api_key
    restart: unless-stopped
    deploy:
      resources:
        limits:
          memory: 2G
          cpus: '1.0'
        reservations:
          memory: 1G
          cpus: '0.5'
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

secrets:
  api_key:
    external: true

volumes:
  typesense_data:
    driver: local
```

### Kubernetes Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: typesense
spec:
  replicas: 1
  selector:
    matchLabels:
      app: typesense
  template:
    metadata:
      labels:
        app: typesense
    spec:
      containers:
      - name: typesense
        image: ghcr.io/batonogov/typesense:latest
        ports:
        - containerPort: 8108
        env:
        - name: TYPESENSE_API_KEY
          valueFrom:
            secretKeyRef:
              name: typesense-secret
              key: api-key
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8108
          initialDelaySeconds: 30
        readinessProbe:
          httpGet:
            path: /health
            port: 8108
          initialDelaySeconds: 10
```

## 🛠 Development

### Quick Links

- **[API Examples](examples/api-examples.md)** - Code samples in multiple languages
- **[Development Environment](examples/docker-compose.dev.yml)** - Ready-to-use dev setup
- **[Troubleshooting Guide](TROUBLESHOOTING.md)** - Common issues and solutions

### Prerequisites

- [Docker](https://www.docker.com/)
- [Task](https://taskfile.dev/) (for task automation)

### Quick Development Setup

```bash
# Clone repository
git clone https://github.com/batonogov/typesense.git
cd typesense

# Start development environment
task dev

# Run tests
task test

# View all available commands
task --list
```

### Available Commands

#### Testing
- `task test` - Run all tests (API + performance)
- `task test-api` - Run API functionality tests
- `task test-performance` - Run performance benchmarks
- `task build-test-container` - Build test container

#### Development
- `task dev` - Start development environment
- `task dev-stop` - Stop development environment
- `task backup` - Backup data from running instance
- `task clean` - Clean up test containers

#### Release Management
- `task create-stable VERSION=29.0` - Create stable release
- `task create-rc VERSION=29.0` - Create release candidate
- `task list-releases` - List recent releases
- `task release-help` - Show release commands help

#### Code Quality
- `task lint` - Run linters and code quality checks
- `task validate-badges` - Validate README badges
- `task docs` - Generate documentation

### Running Tests

```bash
# Run all tests
task test

# Run with custom parameters
TEST_API_KEY=my_key TEST_TIMEOUT=60 task test

# Run specific test type
task test-api
task test-performance
```

## 🔧 Troubleshooting

### Common Issues

#### Container Won't Start

**Symptoms**: Container exits immediately or fails to start

**Solutions**:
1. Check if API key is provided:
   ```bash
   docker logs your-container-name
   ```
2. Verify port 8108 is available:
   ```bash
   lsof -i :8108
   # or
   netstat -tulpn | grep 8108
   ```
3. Ensure sufficient disk space for data directory

#### Healthcheck Failing

**Symptoms**: Container shows as unhealthy in `docker ps`

**Diagnosis**:
```bash
# Check healthcheck status
docker inspect --format='{{.State.Health.Status}}' container-name

# View healthcheck logs
docker inspect --format='{{range .State.Health.Log}}{{.Output}}{{end}}' container-name
```

**Solutions**:
- Wait for start period (30s by default)
- Check if service is listening: `docker exec container-name netstat -tlnp`
- Verify API key is correct
- Check container logs for errors

#### Permission Denied

**Symptoms**: Permission errors when mounting volumes

**Solutions**:
```bash
# Fix volume permissions
sudo chown -R 1001:1001 /path/to/data

# Or use Docker volume instead of bind mount
docker volume create typesense_data
```

#### Performance Issues

**Symptoms**: Slow search responses or high resource usage

**Solutions**:
1. Monitor resource usage:
   ```bash
   docker stats container-name
   ```
2. Increase memory limits:
   ```yaml
   deploy:
     resources:
       limits:
         memory: 2G
   ```
3. Check disk I/O performance
4. Consider SSD storage for data directory

#### Connection Refused

**Symptoms**: Cannot connect to Typesense API

**Checklist**:
- [ ] Container is running: `docker ps`
- [ ] Container is healthy: `docker ps` (healthy status)
- [ ] Port mapping is correct: `-p 8108:8108`
- [ ] Firewall allows connections to port 8108
- [ ] Using correct API key in requests
- [ ] Service is bound to correct interface (0.0.0.0, not 127.0.0.1)

### Getting Help

For detailed troubleshooting steps, see our **[Comprehensive Troubleshooting Guide](TROUBLESHOOTING.md)**.

1. Check the [GitHub Issues](https://github.com/batonogov/typesense/issues)
2. Review [Typesense documentation](https://typesense.org/docs/)
3. Join the community discussions

## 🏗 Architecture

### Image Composition

```dockerfile
FROM typesense/typesense:29.0.rc4
COPY --from=ghcr.io/tarampampam/curl:8.13.0 /bin/curl /bin/curl
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD [ "curl", "--fail", "http://localhost:8108/health" ]
```

### Security Features

- Based on official Typesense image
- Minimal additional dependencies (only curl for healthcheck)
- Regular security scanning with Trivy
- Signed container images with Cosign
- No unnecessary network ports exposed

### Multi-Platform Support

Images are built for:
- `linux/amd64` (Intel/AMD 64-bit)
- `linux/arm64` (ARM 64-bit, Apple Silicon, etc.)

## 📦 Version Compatibility

| Typesense Version | Docker Image | Notes |
|-------------------|--------------|-------|
| 29.0.rc4 | `v29.0.rc4` | Latest RC |
| 28.0 | `v28.0` | Stable |
| 27.1 | `v27.1` | Previous stable |

### Docker Tags

- `latest` - Latest stable release
- `v29.0` - Specific stable version
- `v29.0.rc1` - Release candidate
- `main` - Development builds (not recommended for production)

## 🚀 CI/CD Pipeline

This project uses automated workflows for:

- **Continuous Testing**: API and performance tests on every PR
- **Security Scanning**: Weekly vulnerability scans with Trivy
- **Automated Releases**: Tag-based releases with GitHub Actions
- **Multi-Platform Builds**: Automatic ARM64 and AMD64 image builds
- **Documentation Updates**: Automatic badge and docs synchronization

### Release Process

1. **Release Candidates**: Created weekly or manually
2. **Stable Releases**: Created when RC testing is complete
3. **Automated Tagging**: Based on Dockerfile version changes
4. **Security Validation**: All releases are scanned for vulnerabilities

## 🤝 Contributing

We welcome contributions! Here's how to get started:

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/amazing-feature`
3. **Make your changes**
4. **Run tests**: `task test`
5. **Commit changes**: `git commit -m 'Add amazing feature'`
6. **Push to branch**: `git push origin feature/amazing-feature`
7. **Open a Pull Request**

### Development Guidelines

- Follow existing code style
- Add tests for new features
- Update documentation as needed
- Ensure all CI checks pass

## 📄 License

This project is licensed under the **MIT License**. See the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Typesense Team](https://github.com/typesense/typesense) for the excellent search engine
- [Community Contributors](https://github.com/batonogov/typesense/contributors) for improvements and feedback

---

<div align="center">

**Made with ❤️ by [Fedor Batonogov](https://github.com/batonogov)**

[⭐ Star this repo](https://github.com/batonogov/typesense/stargazers) if you found it helpful!

</div>