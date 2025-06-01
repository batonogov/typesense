# GitHub Actions Workflows Documentation

## Overview

This project uses an **optimized event-driven CI/CD architecture** with 5 core
workflows and automated dependency management for Typesense Docker image
releases.

## Architecture Diagram

```text
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Dependabot    │    │  Developer Push  │    │ Manual Trigger  │
│   (Daily)       │    │   (main branch)  │    │  (Workflow UI)  │
└─────────┬───────┘    └──────────┬───────┘    └─────────┬───────┘
          │                       │                      │
          │ Creates PR            │ Direct push          │ Manual dispatch
          │                       │                      │
          └───────────────────────┼──────────────────────┘
                                  │
                           ┌──────▼──────┐
                           │ Dockerfile  │
                           │   Changed   │
                           └──────┬──────┘
                                  │
                          ┌───────▼────────┐
                          │ release-       │◄─── Detects changes
                          │ manager.yaml   │     Creates tags
                          │                │     Manages RC/Stable
                          └───────┬────────┘
                                  │
                                  │ Creates git tag
                                  │
                          ┌───────▼────────┐
                          │ release-       │◄─── Triggered by tag
                          │ publisher.yaml │     Creates GitHub release
                          │                │     Sends notifications
                          └───────┬────────┘
                                  │
                    ┌─────────────┼─────────────┐
                    │             │             │
            ┌───────▼──────┐ ┌────▼─────┐ ┌────▼──────┐
            │ publish.yaml │ │tests.yaml│ │security-  │
            │              │ │          │ │scan.yaml  │
            │ Docker Build │ │API Tests │ │Weekly     │
            └──────────────┘ └──────────┘ │Trivy Scan │
                                          └───────────┘
```

## Supported Versions

### ✅ Included

- **Stable Releases**: `29.0`, `29.1`, `30.0`
- **Release Candidates**: `29.0.rc1`, `29.1.rc2`, `30.0.rc1`

### ❌ Excluded

- **Alpha**: `29.0.alpha1`, `29.1.alpha2`
- **Beta**: `29.0.beta1`, `29.1.beta3`
- **Dev**: `29.0.dev`, `29.1.dev2`

## Workflow Architecture

### 🏗️ Core Workflows (5 total)

#### 1. **`release-manager.yaml`** - Master Release Controller

- **Role**: Master release orchestrator
- **Triggers**: Dockerfile changes, documentation updates, manual dispatch
- **Responsibilities**:
  - Detect change types (RC vs Stable vs Docs)
  - Create appropriate git tags
  - Manage RC-specific tasks (testing issues, branches)
  - Handle stable release tasks (latest tag updates)
  - Generate documentation updates
- **Jobs**:
  - `detect-changes`: Analyzes changes and determines release type
  - `create-tag`: Creates appropriate git tags
  - `manage-rc`: RC-specific tasks (branches, testing issues)
  - `manage-stable`: Stable release tasks (latest tag updates)
  - `generate-docs`: Documentation updates
  - `summary`: Workflow completion summary

#### 2. **`release-publisher.yaml`** - GitHub Release Creator

- **Role**: GitHub release creator and notifier
- **Triggers**: New git tags (`v*.*`, `v*.*.rc*`, `v*.*rc*`)
- **Responsibilities**:
  - Create GitHub releases with rich descriptions
  - Update badges and documentation
  - Send community notifications
  - Validate release completeness
- **Jobs**:
  - `create-release`: Creates GitHub release with full description
  - `post-release-tasks`: Badge updates, announcements, validations

#### 3. **`publish.yaml`** - Docker Image Builder

- **Role**: Multi-platform Docker image publisher
- **Triggers**: Tags and main branch pushes
- **Responsibilities**:
  - Build multi-architecture images (amd64, arm64)
  - Publish to GitHub Container Registry
  - Sign images with Cosign for security
  - Cache layers for performance
- **Output**: `ghcr.io/repo:version` images with cosign signatures

#### 4. **`tests.yaml`** - Quality Assurance

- **Role**: Continuous testing and validation
- **Triggers**: Main branch and PR changes
- **Responsibilities**:
  - API functionality testing
  - Performance benchmarking
  - Health check validation
  - Integration testing
- **Jobs**: `api-test`, `performance-test`

#### 5. **`security-scan.yaml`** - Security Monitoring

- **Role**: Security vulnerability scanning
- **Triggers**: Weekly schedule (Sundays)
- **Responsibilities**:
  - Trivy vulnerability scanning
  - SARIF report generation
  - Security advisory management
- **Output**: SARIF results to GitHub Security tab

## Complete Automation Flow

### Full Process Overview

```text
Typesense Release → Dependabot PR → Human Review → Merge → Automatic Release
```

### RC Release Flow

```text
Dockerfile: typesense:29.1.rc2 → release-manager → v29.1.rc2 tag →
release-publisher → GitHub RC Release
                                     ↓
                              RC branch + testing issue
```

1. Typesense releases `29.1.rc2`
2. Dependabot creates PR within 24 hours
3. Developer reviews and merges PR
4. `release-manager.yaml` detects RC version
5. Creates:
   - Git tag `v29.1.rc2`
   - RC branch `rc/29.1.rc2`
   - Testing issue with checklist
6. `release-publisher.yaml` creates GitHub prerelease
7. `publish.yaml` builds Docker images
8. Result: `ghcr.io/repo:29.1.rc2` available

### Stable Release Flow

```text
Dockerfile: typesense:29.1 → release-manager → v29.1 tag →
release-publisher → GitHub Stable Release
                                ↓                            ↓
                         latest tag update              announcement issue
```

1. Typesense releases `29.1`
2. Dependabot creates PR within 24 hours
3. Developer reviews and merges PR
4. `release-manager.yaml` detects stable version
5. Creates:
   - Git tag `v29.1`
   - Updates `latest` tag
   - Announcement issue
6. `release-publisher.yaml` creates GitHub stable release
7. `publish.yaml` builds Docker images
8. Result: `ghcr.io/repo:29.1` and `ghcr.io/repo:latest` available

### Docker Publishing Flow

```text
New tag → publish.yaml → Multi-arch build → ghcr.io images → Cosign signature
```

## Automation Components

### 1. Dependabot (Daily)

- **Monitors**: Typesense Docker Hub for new versions
- **Creates**: Automatic PRs for version updates
- **Includes**: Stable versions (29.0) and RC versions (29.0.rc1)
- **Configuration**:

  ```yaml
  - package-ecosystem: "docker"
    directory: "/"
    schedule:
      interval: "daily"
    ignore:
      - dependency-name: "*"
        versions: ["*-alpha*", "*-beta*", "*-dev*"]
  ```

### 2. Release Manager (Event-driven)

- **Trigger**: Dockerfile changes on main branch
- **Detects**: Version type (RC vs Stable)
- **Creates**: Appropriate git tags
- **Manages**: Release-specific tasks

### 3. Release Publisher (Tag-driven)

- **Trigger**: New version tags
- **Creates**: GitHub releases with full documentation
- **Handles**: Post-release notifications and updates

### 4. Docker Publisher (Tag-driven)

- **Builds**: Multi-architecture images (amd64, arm64)
- **Publishes**: To GitHub Container Registry
- **Signs**: Images with Cosign for security

### 5. Quality Assurance (Continuous)

- **Tests**: API functionality and performance
- **Scans**: Security vulnerabilities weekly
- **Validates**: Image functionality post-build

## Version Detection Logic

| Dockerfile Version | Detected Type | Tag Created | Release Type |
| ------------------ | ------------- | ----------- | ------------ |
| `29.1.rc2`         | RC            | `v29.1.rc2` | Prerelease   |
| `29.1`             | Stable        | `v29.1`     | Release      |

| Branch Created | Issue Type   |
| -------------- | ------------ |
| `rc/29.1.rc2`  | Testing      |
| None           | Announcement |

```bash
if [[ "$VERSION" == *"rc"* ]]; then
  TYPE="Release Candidate"
  PRERELEASE=true
  BRANCH="rc/$VERSION"
  ISSUE="Testing checklist"
else
  TYPE="Stable Release"
  PRERELEASE=false
  TAG_UPDATE="latest"
  ISSUE="Announcement"
fi
```

## Manual Controls

### Force Release Creation

```bash
gh workflow run release-manager.yaml -f force_create=true
```

### Create Specific RC Number

```bash
gh workflow run release-manager.yaml -f rc_number=5
```

### Skip Automation

Add `[skip ci]` to commit message when updating Dockerfile

## Human Interaction Points

### Required Actions

- **PR Review**: Only human step - merge dependabot PRs
- **RC Testing**: Follow checklist in automatically created testing issues
- **Issue Management**: Close resolved testing/announcement issues

### Optional Actions

- **Manual RC Creation**: Force create specific RC numbers
- **Manual Releases**: Emergency releases with workflow_dispatch
- **Configuration Updates**: Adjusting dependabot settings

## Timing Expectations

### Typical Flow Duration

1. **Dependabot Detection**: < 1 hour after Typesense release
2. **PR Creation**: Immediate after detection
3. **PR Review & Merge**: Human-dependent (minutes to days)
4. **Automated Release**: 2-5 minutes after merge
5. **Docker Images**: 5-10 minutes for multi-arch build
6. **Full Availability**: ~15 minutes total automation time

### Frequency

- **Dependabot Checks**: Daily at various times
- **RC Releases**: As soon as RC versions are available
- **Stable Releases**: As soon as stable versions are available
- **Security Scans**: Weekly (Sundays)

## Workflow Optimization Results

### Before Optimization (11 workflows)

- `auto-tag.yaml` + `create-rc.yaml` + `auto-stable-release.yaml` +
  `docs.yaml`
- `release.yaml` + `release-notification.yaml`
- `auto-pr.yaml` (removed - unnecessary)
- `update-typesense.yaml` (removed - dependabot handles this)
- Plus 3 support workflows

### After Optimization (5 workflows + dependabot)

- `release-manager.yaml` (unified release control)
- `release-publisher.yaml` (unified publishing)
- Plus 3 support workflows
- Dependabot for dependency management

**Result**: 55% fewer workflow files, clearer responsibilities, easier
maintenance

## Monitoring & Observability

### Success Indicators

- ✅ Dependabot PRs created within 1 hour of Typesense release
- ✅ Releases created within 5 minutes of PR merge
- ✅ Docker images available within 15 minutes
- ✅ No failed workflow runs

### Alert Points

- ❌ Dependabot PR creation fails
- ❌ Release workflow failures
- ❌ Docker build/push failures
- ❌ Security scan critical findings

### Dashboard Links

- **Actions**: GitHub Actions tab for workflow status
- **Packages**: GitHub Packages for Docker images
- **Security**: Security tab for vulnerability reports
- **Dependabot**: Insights → Dependency graph → Dependabot
- **Releases**: GitHub Releases page
- **Issues**: Auto-created issues for testing/announcements

## File Structure

```text
.github/workflows/
├── release-manager.yaml      # 🎯 Master release controller
├── release-publisher.yaml    # 📢 GitHub release creator
├── publish.yaml             # 🐳 Docker image builder
├── tests.yaml               # 🧪 Quality assurance
└── security-scan.yaml       # 🔒 Security monitoring

.github/
├── dependabot.yaml          # 🔄 Dependency updates (Typesense + Actions)
├── WORKFLOWS.md             # 📚 This documentation
└── ISSUE_TEMPLATE/
    └── release_testing.md   # 🧪 RC testing template
```

## Benefits of This System

### Speed

- **Immediate response** to new Typesense versions
- **Single manual step** (PR merge)
- **Parallel processing** of builds and documentation

### Reliability

- **Consistent process** every time
- **No version detection errors**
- **Automated testing** at every step

### Simplicity

- **55% fewer workflows** to maintain
- **Clear responsibilities** per workflow
- **Easy troubleshooting** with unified logic

### Scalability

- **Handles multiple versions** simultaneously
- **No bottlenecks** from manual processes
- **Easy to extend** with additional automation

## Resource Usage

### GitHub Actions Minutes

- **release-manager**: ~2-3 minutes per release
- **release-publisher**: ~1-2 minutes per release
- **publish**: ~5-10 minutes per release (multi-arch)
- **tests**: ~3-5 minutes per change
- **security-scan**: ~2-3 minutes weekly

### Storage

- **Git tags**: Linear growth with releases
- **Docker images**: One per version (cleanup available)
- **Artifacts**: Test logs (7-day retention)

## Troubleshooting

### Common Issues

#### Release Not Created

**Issue**: Tag pushed but no release created
**Solution**:

1. Check if tag format matches pattern (`v*.*` or `v*.*.rc*`)
2. Verify release workflow status in Actions tab
3. Check workflow permissions (needs `contents: write`)

#### Docker Image Not Available

**Issue**: Release created but Docker image pull fails
**Solution**:

1. Check publish workflow status
2. Verify GHCR permissions
3. Wait 5-10 minutes for registry sync
4. Check if workflow completed successfully

#### RC Not Auto-Created

**Issue**: Scheduled RC creation didn't work
**Solution**:

1. Check if there are new commits since last release
2. Verify create-rc workflow schedule settings
3. Manually trigger workflow if needed

#### Testing Issue Not Created

**Issue**: RC created but no testing issue
**Solution**:

1. Check release-notification workflow logs
2. Verify issues permissions
3. Manually create issue using template

## Security

### Image Signing

- All images signed with Cosign
- Keyless signing with GitHub OIDC
- Verification commands:

```bash
cosign verify ghcr.io/batonogov/typesense:v29.0 \
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

This optimized automation system provides reliable, fast, and maintainable
releases for Typesense stable and RC versions with minimal human intervention.
