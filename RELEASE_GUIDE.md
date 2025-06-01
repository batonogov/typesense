# Release Management Guide

This guide explains how to use the automated release system for the Typesense with Healthcheck project.

## Overview

Our release system consists of several automated workflows that handle:

- Automatic tagging based on Dockerfile changes
- Docker image building and publishing
- GitHub release creation with detailed notes
- Release candidate management
- Testing and validation
- Community notifications

## Release Types

### Stable Releases

- **Format**: `v{major}.{minor}` (e.g., `v29.0`)
- **Trigger**: Automatic when Dockerfile is updated with stable Typesense version
- **Docker Tags**: `{version}`, `v{version}`, `latest`
- **Features**: Full release notes, announcements, latest tag

### Release Candidates

- **Format**: `v{major}.{minor}.rc{number}` (e.g., `v29.0.rc1`)
- **Trigger**: Manual or scheduled (Mondays at 9 AM UTC)
- **Docker Tags**: `{version}`, `v{version}`
- **Features**: Testing issues, validation workflows

## Automatic Release Process

### 1. Update Typesense Version

```dockerfile
# In Dockerfile, update the FROM line:
FROM typesense/typesense:29.0  # Change this version
```

### 2. Automatic Flow

1. **Auto-tag workflow** detects Dockerfile change
1. Creates Git tag (`v29.0.0`)
1. **Publish workflow** builds and pushes Docker images
1. **Release workflow** creates GitHub release with notes
1. **Release notification workflow** creates announcements

## Manual Release Creation

### Creating a Stable Release

```bash
# Method 1: Update Dockerfile and push
git add Dockerfile
git commit -m "Update to Typesense 29.0"
git push origin main

# Method 2: Create tag manually
git tag -a v29.0 -m "Release 29.0"
git push origin v29.0
```

### Creating a Release Candidate

#### Via GitHub Actions UI

1. Go to **Actions** → **Create Release Candidate**
1. Click **Run workflow**
1. Optionally specify RC number
1. Click **Run workflow**

#### Via Command Line

```bash
# Auto-increment RC number
gh workflow run create-rc.yaml

# Specify RC number
gh workflow run create-rc.yaml -f rc_number=2

# Force create (overwrite existing)
gh workflow run create-rc.yaml -f force_create=true
```

#### Via Git Tag

```bash
git tag -a v29.0.rc1 -m "Release Candidate 29.0.rc1"
git push origin v29.0.rc1
```

## Testing Process

### Automated Testing

- Runs on every release (stable and RC)
- Includes API tests, performance tests, healthcheck validation
- Results reported in workflow logs

### Manual Testing for RCs

1. **Testing Issue Created**: Automatically created for each RC
1. **Community Testing**: Contributors test using provided checklist
1. **Approval Process**: Issues marked as resolved when testing passes

### Testing Checklist Template

```bash
# Pull and test RC
docker pull ghcr.io/batonogov/typesense:v29.0.rc1
docker run -d --name typesense-test -p 8108:8108 -e TYPESENSE_API_KEY=test-key ghcr.io/batonogov/typesense:v29.0.rc1
```

# Verify health

curl http://localhost:8108/health

# Test API

curl -H "X-TYPESENSE-API-KEY: test-key" http://localhost:8108/collections

# Cleanup

docker stop typesense-test && docker rm typesense-test

````

## Release Workflow Features

### Automated Release Notes
- **Version Information**: Current version and Typesense core version
- **Docker Usage**: Pull commands, quick start, Docker Compose
- **Feature Highlights**: Healthcheck, multi-arch, security
- **Changelog**: Git commits since last release
- **Configuration Guide**: Environment variables and examples

### Docker Image Management
- **Multi-Architecture**: Built for `linux/amd64` and `linux/arm64`
- **Security**: Images signed with Cosign
- **Registry**: Published to GitHub Container Registry (GHCR)
- **Verification**: Automatic image accessibility checks

### Community Engagement
- **Announcements**: Issues created for stable releases
- **Testing Requests**: Issues created for release candidates
- **Documentation**: README and badges updated automatically

## Monitoring Releases

### GitHub Resources
- **Releases**: https://github.com/batonogov/typesense/releases
- **Actions**: https://github.com/batonogov/typesense/actions
- **Packages**: https://github.com/batonogov/typesense/pkgs/container/typesense
- **Security**: https://github.com/batonogov/typesense/security

### Docker Registry
```bash
# List available tags
gh api repos/batonogov/typesense/packages

# Pull specific version
docker pull ghcr.io/batonogov/typesense:v29.0.0

# Pull latest
docker pull ghcr.io/batonogov/typesense:latest
````

## Troubleshooting

### Release Not Created

**Issue**: Tag pushed but no release created
**Solution**:

1. Check if tag format matches pattern (`v*.*` or `v*.*.rc*`)
1. Verify release workflow status in Actions tab
1. Check workflow permissions (needs `contents: write`)

### Docker Image Not Available

**Issue**: Release created but Docker image pull fails
**Solution**:

1. Check publish workflow status
1. Verify GHCR permissions
1. Wait 5-10 minutes for registry sync
1. Check if workflow completed successfully

### RC Not Auto-Created

**Issue**: Scheduled RC creation didn't work
**Solution**:

1. Check if there are new commits since last release
1. Verify create-rc workflow schedule settings
1. Manually trigger workflow if needed

### Testing Issue Not Created

**Issue**: RC created but no testing issue
**Solution**:

1. Check release-notification workflow logs
1. Verify issues permissions
1. Manually create issue using template

## Version Management

### Version Sources

- **Primary**: Typesense version in Dockerfile
- **Pattern**: `typesense/typesense:{version}`
- **Auto-detection**: Extracts version using regex

### Tagging Strategy

- **Stable**: Matches Typesense version exactly
- **RC**: Adds `.rc{number}` suffix
- **Latest**: Only for stable releases

### Branch Management

- **Main**: All development and releases
- **RC Branches**: Created for each RC (`rc/29.0.rc1`)
- **Rollback**: Available for critical issues

## Security

### Image Signing

- All images signed with Cosign
- Keyless signing with GitHub OIDC
- Verification commands:

```bash
cosign verify ghcr.io/batonogov/typesense:v29.0.0 \
  --certificate-identity-regexp="https://github.com/batonogov/typesense" \
  --certificate-oidc-issuer="https://token.actions.githubusercontent.com"
```

### Vulnerability Scanning

- Weekly Trivy scans
- Results in Security tab
- Fail on HIGH severity issues

## Configuration

### Workflow Permissions

Required permissions in repository settings:

- **Actions**: Read and write
- **Contents**: Write
- **Packages**: Write
- **Issues**: Write
- **Pull Requests**: Write

### Secrets and Variables

- **GITHUB_TOKEN**: Automatically provided
- **Registry Access**: Configured via GHCR permissions

## Best Practices

### Before Releasing

1. Test changes locally
1. Update documentation if needed
1. Review Dockerfile changes
1. Check for security updates

### For Release Candidates

1. Always test RCs before stable release
1. Allow community feedback time
1. Address critical issues before promoting

### For Stable Releases

1. Ensure RC testing is complete
1. Update version in documentation
1. Announce in community channels
1. Monitor for issues post-release

## Emergency Procedures

### Rollback Release

```bash
# Delete problematic tag
git tag -d v29.0
git push origin :refs/tags/v29.0
```

# Revert to previous version in Dockerfile

git revert <commit-hash>
git push origin main

````

### Hotfix Release
```bash
# Create hotfix branch
git checkout -b hotfix/29.0.1
# Make critical fixes
git commit -m "Critical security fix"
git push origin hotfix/29.0.1

# Update Dockerfile version
# Push to trigger release
````

### Security Incident

1. Immediately remove affected images
1. Create security advisory
1. Release patched version
1. Notify community

## Support

### Getting Help

- **Issues**: Create GitHub issue with `release` label
- **Discussions**: Use GitHub Discussions for questions
- **Documentation**: Check README.md for latest info

### Contributing

- **Testing**: Participate in RC testing
- **Feedback**: Report issues and suggestions
- **Documentation**: Help improve guides
