# Troubleshooting Guide

This guide helps you diagnose and resolve common issues with the Typesense Docker image.

## Quick Diagnosis

### Check Container Status

```bash
# View running containers
docker ps

# Check container logs
docker logs typesense-container-name

# Inspect container health
docker inspect --format='{{.State.Health.Status}}' typesense-container-name

# View detailed container information
docker inspect typesense-container-name
```

### Check System Resources

```bash
# Monitor resource usage
docker stats typesense-container-name

# Check disk space
df -h

# Check memory usage
free -h

# Check available ports
netstat -tulpn | grep 8108
```

## Common Issues

### 1. Container Won't Start

#### Symptoms
- Container exits immediately after start
- Exit code 1 or 125
- "Container failed to start" messages

#### Diagnosis Steps

```bash
# Check container logs
docker logs typesense-container-name

# Try running with interactive mode for debugging
docker run -it --rm -e TYPESENSE_API_KEY=test ghcr.io/batonogov/typesense:latest /bin/sh
```

#### Common Causes & Solutions

**Missing API Key**
```bash
# Error: API key is required
# Solution: Provide API key
docker run -e TYPESENSE_API_KEY=your-api-key ghcr.io/batonogov/typesense:latest
```

**Port Already in Use**
```bash
# Error: bind: address already in use
# Check what's using the port
lsof -i :8108
netstat -tulpn | grep 8108

# Solution: Stop conflicting service or use different port
docker run -p 8109:8108 -e TYPESENSE_API_KEY=your-key ghcr.io/batonogov/typesense:latest
```

**Insufficient Memory**
```bash
# Error: Cannot allocate memory
# Solution: Increase available memory or set limits
docker run --memory=1g -e TYPESENSE_API_KEY=your-key ghcr.io/batonogov/typesense:latest
```

**Permission Issues**
```bash
# Error: Permission denied accessing data directory
# Solution: Fix data directory permissions
sudo chown -R 1001:1001 /path/to/data
# Or use Docker volumes instead of bind mounts
docker volume create typesense_data
```

### 2. Healthcheck Failing

#### Symptoms
- Container status shows as "unhealthy"
- Health status is "starting" for extended periods
- Healthcheck timeouts

#### Diagnosis Steps

```bash
# Check current health status
docker inspect --format='{{.State.Health.Status}}' container-name

# View healthcheck logs
docker inspect --format='{{range .State.Health.Log}}{{.Output}}{{end}}' container-name

# Test healthcheck manually
docker exec container-name curl -f http://localhost:8108/health

# Check if service is listening
docker exec container-name netstat -tlnp | grep 8108
```

#### Solutions

**Service Not Ready**
```bash
# Wait for the start period (default 30 seconds)
# Or increase start period in docker-compose:
healthcheck:
  start_period: 60s
```

**Wrong Health Endpoint**
```bash
# Verify the health endpoint is accessible
docker exec container-name curl -v http://localhost:8108/health

# Check if API key is required for health endpoint
docker exec container-name curl -H "X-TYPESENSE-API-KEY: your-key" http://localhost:8108/health
```

**Network Issues**
```bash
# Check if container can reach itself
docker exec container-name ping localhost

# Verify port binding
docker port container-name
```

### 3. Connection Refused / Cannot Connect

#### Symptoms
- "Connection refused" errors
- "Unable to connect to Typesense"
- Timeout errors when accessing API

#### Diagnosis Steps

```bash
# Test from host machine
curl -v http://localhost:8108/health

# Test from within container
docker exec container-name curl http://localhost:8108/health

# Check port mapping
docker port container-name

# Verify firewall settings
sudo ufw status  # Ubuntu
sudo firewall-cmd --list-ports  # CentOS/RHEL
```

#### Solutions

**Incorrect Port Mapping**
```bash
# Ensure port is properly mapped
docker run -p 8108:8108 -e TYPESENSE_API_KEY=key ghcr.io/batonogov/typesense:latest
```

**Service Binding to Wrong Interface**
```bash
# Ensure Typesense binds to all interfaces
docker run -e TYPESENSE_LISTEN_ADDRESS=0.0.0.0 -e TYPESENSE_API_KEY=key ghcr.io/batonogov/typesense:latest
```

**Firewall Blocking Connection**
```bash
# Allow port through firewall (Ubuntu)
sudo ufw allow 8108

# Allow port through firewall (CentOS/RHEL)
sudo firewall-cmd --permanent --add-port=8108/tcp
sudo firewall-cmd --reload
```

### 4. API Authentication Issues

#### Symptoms
- 401 Unauthorized errors
- "Invalid API key" messages
- Authentication failures

#### Diagnosis Steps

```bash
# Test with API key
curl -H "X-TYPESENSE-API-KEY: your-key" http://localhost:8108/collections

# Check environment variables
docker exec container-name env | grep TYPESENSE

# Verify API key format
echo "API key length: $(echo -n 'your-key' | wc -c)"
```

#### Solutions

**Wrong API Key**
```bash
# Ensure API key matches what was set during startup
docker run -e TYPESENSE_API_KEY=correct-key ghcr.io/batonogov/typesense:latest
```

**Missing API Key Header**
```bash
# Always include API key in requests
curl -H "X-TYPESENSE-API-KEY: your-key" http://localhost:8108/collections
```

### 5. Performance Issues

#### Symptoms
- Slow search responses
- High CPU/memory usage
- Timeouts on operations

#### Diagnosis Steps

```bash
# Monitor resource usage
docker stats container-name

# Check container limits
docker inspect container-name | grep -A 10 "Memory\|Cpu"

# Test search performance
time curl -H "X-TYPESENSE-API-KEY: key" "http://localhost:8108/collections/test/documents/search?q=query"

# Check disk I/O
iostat -x 1 5  # Linux
```

#### Solutions

**Insufficient Resources**
```yaml
# Increase resource limits in docker-compose.yml
deploy:
  resources:
    limits:
      memory: 2G
      cpus: '1.0'
    reservations:
      memory: 1G
      cpus: '0.5'
```

**Slow Storage**
```bash
# Use SSD storage for data directory
# Mount data volume on fast storage
docker run -v /fast/ssd/path:/data -e TYPESENSE_API_KEY=key ghcr.io/batonogov/typesense:latest
```

**Too Many Collections/Documents**
```bash
# Optimize Typesense configuration
docker run -e TYPESENSE_API_KEY=key \
  ghcr.io/batonogov/typesense:latest \
  --max-memory-ratio=0.8 \
  --num-memory-shards=1
```

### 6. Data Persistence Issues

#### Symptoms
- Data lost after container restart
- "Collection not found" after restart
- Empty collections after reboot

#### Diagnosis Steps

```bash
# Check volume mounts
docker inspect container-name | grep -A 10 "Mounts"

# Verify data directory
docker exec container-name ls -la /data

# Check volume persistence
docker volume ls
docker volume inspect volume-name
```

#### Solutions

**Missing Volume Mount**
```yaml
# Ensure data persistence in docker-compose.yml
services:
  typesense:
    volumes:
      - typesense_data:/data
    environment:
      - TYPESENSE_DATA_DIR=/data

volumes:
  typesense_data:
```

**Wrong Data Directory**
```bash
# Ensure data directory matches volume mount
docker run -v /host/data:/custom/data \
  -e TYPESENSE_DATA_DIR=/custom/data \
  -e TYPESENSE_API_KEY=key \
  ghcr.io/batonogov/typesense:latest
```

### 7. Docker Compose Issues

#### Symptoms
- Services not starting
- Networks not connecting
- Volumes not mounting

#### Diagnosis Steps

```bash
# Check compose file syntax
docker-compose config

# View service logs
docker-compose logs typesense

# Check service status
docker-compose ps

# Validate networks
docker network ls
```

#### Solutions

**Invalid YAML Syntax**
```bash
# Validate docker-compose.yml
docker-compose config
# Fix any syntax errors reported
```

**Version Compatibility**
```yaml
# Use compatible compose version
version: '3.8'  # Recommended
```

**Service Dependencies**
```yaml
# Ensure proper service ordering
services:
  typesense:
    depends_on:
      - some-dependency
```

## Error Messages Reference

### Common Error Messages and Solutions

**"API key is required"**
- Solution: Set `TYPESENSE_API_KEY` environment variable

**"Address already in use"**
- Solution: Change port mapping or stop conflicting service

**"Permission denied"**
- Solution: Fix file/directory permissions or use Docker volumes

**"Cannot allocate memory"**
- Solution: Increase available memory or set container limits

**"Connection refused"**
- Solution: Check port mapping and firewall settings

**"Invalid JSON"**
- Solution: Verify API request format and content-type headers

**"Collection not found"**
- Solution: Ensure data persistence and correct collection names

## Advanced Debugging

### Enable Debug Logging

```bash
# Run with debug logging
docker run -e TYPESENSE_LOG_LEVEL=DEBUG \
  -e TYPESENSE_API_KEY=key \
  ghcr.io/batonogov/typesense:latest
```

### Network Debugging

```bash
# Test network connectivity
docker exec container-name ping google.com

# Check DNS resolution
docker exec container-name nslookup google.com

# Test internal container networking
docker network inspect bridge
```

### Resource Monitoring

```bash
# Continuous monitoring
watch docker stats

# Memory usage breakdown
docker exec container-name cat /proc/meminfo

# Disk usage
docker exec container-name df -h
```

### Container Shell Access

```bash
# Access container shell for debugging
docker exec -it container-name /bin/sh

# Run debugging commands inside container
docker exec container-name ps aux
docker exec container-name netstat -tulpn
```

## Performance Tuning

### Memory Optimization

```bash
# Set memory limits
docker run --memory=2g --memory-swap=2g \
  -e TYPESENSE_API_KEY=key \
  ghcr.io/batonogov/typesense:latest
```

### CPU Optimization

```bash
# Limit CPU usage
docker run --cpus=1.5 \
  -e TYPESENSE_API_KEY=key \
  ghcr.io/batonogov/typesense:latest
```

### Storage Optimization

```bash
# Use tmpfs for temporary data
docker run --tmpfs /tmp:rw,noexec,nosuid,size=100m \
  -e TYPESENSE_API_KEY=key \
  ghcr.io/batonogov/typesense:latest
```

## Getting Help

If you continue to experience issues:

1. **Check the Logs**: Always start with `docker logs container-name`
2. **Review Documentation**: Check the [main README](README.md)
3. **Search Issues**: Look through [GitHub Issues](https://github.com/batonogov/typesense/issues)
4. **Create Issue**: Provide detailed information including:
   - Docker version
   - Operating system
   - Complete error messages
   - Steps to reproduce
   - Container logs
   - Docker compose file (if applicable)

### Information to Include in Bug Reports

```bash
# System information
docker version
docker-compose version
uname -a

# Container information
docker logs container-name
docker inspect container-name
docker stats container-name --no-stream

# Configuration
cat docker-compose.yml  # Remove sensitive information
env | grep TYPESENSE    # Remove sensitive values
```

Remember to remove any sensitive information (API keys, passwords) before sharing logs or configurations!