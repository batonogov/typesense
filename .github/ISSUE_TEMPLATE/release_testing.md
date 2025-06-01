---
name: Release Testing
about: Template for testing new releases and release candidates
title: '🧪 Testing: [VERSION] - [BRIEF_DESCRIPTION]'
labels: testing, release
assignees: ''
---

# 🧪 Release Testing Report

## 📦 Release Information

- **Version**: <!-- e.g., v29.0.0 or v29.0.0.rc1 -->
- **Release Type**: <!-- Stable / Release Candidate -->
- **Typesense Core Version**: <!-- e.g., 29.0.0 -->
- **Docker Image**: `ghcr.io/batonogov/typesense:[VERSION]`
- **Testing Date**: <!-- YYYY-MM-DD -->
- **Tester**: @<!-- your-username -->

## 🔧 Test Environment

- **OS**: <!-- e.g., Ubuntu 22.04, macOS 14, Windows 11 -->
- **Docker Version**: <!-- e.g., 24.0.7 -->
- **Architecture**: <!-- amd64 / arm64 -->
- **Memory**: <!-- e.g., 8GB -->
- **CPU**: <!-- e.g., 4 cores -->

## 📋 Testing Checklist

### Basic Functionality

- [ ] Docker image pulls successfully
- [ ] Container starts without errors
- [ ] Healthcheck endpoint responds (`/health`)
- [ ] API authentication works
- [ ] Basic API endpoints are accessible

### Core Features

- [ ] Collection creation and management
- [ ] Document indexing and retrieval
- [ ] Search functionality
- [ ] Real-time search updates
- [ ] Data persistence across restarts

### Performance & Reliability

- [ ] Container startup time is acceptable (< 60s)
- [ ] Memory usage is within expected range
- [ ] CPU usage is reasonable under load
- [ ] Healthcheck responds consistently
- [ ] No memory leaks during extended operation

### Container Features

- [ ] Healthcheck works correctly
- [ ] Environment variables are respected
- [ ] Volume mounting works for data persistence
- [ ] Port mapping functions properly
- [ ] Container stops gracefully

### Multi-Architecture (if applicable)

- [ ] amd64 image works correctly
- [ ] arm64 image works correctly
- [ ] Both architectures have same functionality

## 🧪 Test Commands Used

### Basic Setup

```bash
# Pull the image
docker pull ghcr.io/batonogov/typesense:[VERSION]

# Run container
docker run -d --name typesense-test \
  -p 8108:8108 \
  -e TYPESENSE_API_KEY=test-key-123 \
  -v typesense-test-data:/data \
  ghcr.io/batonogov/typesense:[VERSION]
```

### Health Check

```bash
# Check container status
docker ps

# Test healthcheck endpoint
curl -f http://localhost:8108/health

# Check container health status
docker inspect typesense-test --format='{{.State.Health.Status}}'
```

### API Testing

```bash
# Test API authentication
curl -H "X-TYPESENSE-API-KEY: test-key-123" http://localhost:8108/collections

# Create test collection
curl -X POST http://localhost:8108/collections \
  -H "X-TYPESENSE-API-KEY: test-key-123" \
  -H "Content-Type: application/json" \
  -d '{"name":"test","fields":[{"name":"title","type":"string"},{"name":"content","type":"string"}]}'

# Add test document
curl -X POST http://localhost:8108/collections/test/documents \
  -H "X-TYPESENSE-API-KEY: test-key-123" \
  -H "Content-Type: application/json" \
  -d '{"title":"Test Document","content":"This is a test document for release testing"}'

# Search test
curl -H "X-TYPESENSE-API-KEY: test-key-123" \
  "http://localhost:8108/collections/test/documents/search?q=test&query_by=title,content"
```

## 📊 Test Results

### ✅ Passed Tests

<!-- List tests that passed successfully -->

-

### ❌ Failed Tests

<!-- List tests that failed with details -->

-

### ⚠️ Issues Found

<!-- Describe any issues, bugs, or concerns -->

#### Issue 1

- **Description**:
- **Steps to Reproduce**:
- **Expected Behavior**:
- **Actual Behavior**:
- **Severity**: <!-- Critical / High / Medium / Low -->
- **Logs**:

```
<!-- Paste relevant logs here -->
```

#### Issue 2

- **Description**:
- **Steps to Reproduce**:
- **Expected Behavior**:
- **Actual Behavior**:
- **Severity**: <!-- Critical / High / Medium / Low -->
- **Logs**:

```
<!-- Paste relevant logs here -->
```

## 📈 Performance Observations

### Startup Performance

- **Container Start Time**: <!-- seconds -->
- **Time to First API Response**: <!-- seconds -->
- **Healthcheck First Success**: <!-- seconds -->

### Runtime Performance

- **Memory Usage (Idle)**: <!-- MB -->
- **Memory Usage (Under Load)**: <!-- MB -->
- **CPU Usage (Idle)**: <!-- % -->
- **CPU Usage (Under Load)**: <!-- % -->

### Search Performance

- **Simple Search Response Time**: <!-- ms -->
- **Complex Search Response Time**: <!-- ms -->
- **Indexing Speed**: <!-- documents/second -->

## 🔍 Additional Testing Notes

### Configuration Testing

<!-- Test results for different configurations -->

- **Custom API Key**: <!-- ✅ / ❌ -->
- **Custom Data Directory**: <!-- ✅ / ❌ -->
- **Custom Listen Address**: <!-- ✅ / ❌ -->
- **Volume Persistence**: <!-- ✅ / ❌ -->

### Integration Testing

<!-- Test results for integration scenarios -->

- **Docker Compose**: <!-- ✅ / ❌ -->
- **Kubernetes**: <!-- ✅ / ❌ / N/A -->
- **Load Balancer**: <!-- ✅ / ❌ / N/A -->
- **Reverse Proxy**: <!-- ✅ / ❌ / N/A -->

## 📝 Logs and Debugging

### Container Logs

```
<!-- Paste relevant container logs -->
```

### System Logs

```
<!-- Paste relevant system logs if any issues -->
```

## 🎯 Overall Assessment

### Recommendation

<!-- Choose one -->

- [ ] ✅ **APPROVE**: Ready for stable release
- [ ] ⚠️ **APPROVE WITH NOTES**: Minor issues, but acceptable for release
- [ ] ❌ **REJECT**: Critical issues found, needs fixes before release
- [ ] 🔄 **NEEDS MORE TESTING**: Requires additional testing in specific areas

### Summary

<!-- Provide a brief summary of testing results and recommendation reasoning -->

### Next Steps

<!-- What should happen next based on testing results -->

-

## 📚 References

- **Release Notes**: <!-- Link to release notes -->
- **Docker Registry**: `ghcr.io/batonogov/typesense:[VERSION]`
- **Documentation**: https://github.com/batonogov/typesense/blob/main/README.md
- **Previous Testing**: <!-- Link to previous release testing if relevant -->

______________________________________________________________________

**Testing completed by**: @<!-- your-username -->
**Testing date**: <!-- YYYY-MM-DD -->
**Total testing time**: <!-- hours/minutes -->
