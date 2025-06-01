# Release Workflow Documentation

## Overview

This project uses an **optimized event-driven release system** with consolidated workflows that automatically create releases when Typesense versions are updated in the Dockerfile.

## Workflow Architecture

### 🏗️ Core Workflows (5 total)

#### 1. **`release-manager.yaml`** - Master Release Controller

- **Trigger**: Changes to `Dockerfile`, docs, or manual dispatch
- **Purpose**: Detects changes, creates tags, manages RC/stable releases, generates docs
- **Jobs**:
  - `detect-changes`: Analyzes what changed and determines release type
  - `create-tag`: Creates appropriate git tags
  - `manage-rc`: Handles RC-specific tasks (testing issues, RC branches)
  - `manage-stable`: Handles stable release tasks (latest tag updates)
  - `generate-docs`: Updates documentation when needed

#### 2. **`release-publisher.yaml`** - GitHub Release Creator

- **Trigger**: New tags (`v*.*`, `v*.*.rc*`, `v*.*rc*`)
- **Purpose**: Creates GitHub releases with full descriptions and notifications
- **Jobs**:
  - `create-release`: Creates the GitHub release
  - `post-release-tasks`: Updates badges, creates announcements, validates images

#### 3. **`publish.yaml`** - Docker Image Builder

- **Trigger**: Tags and main branch pushes
- **Purpose**: Builds and publishes multi-arch Docker images
- **Output**: `ghcr.io/repo:version` images with cosign signatures

#### 4. **`tests.yaml`** - Quality Assurance

- **Trigger**: Main branch and PR changes
- **Purpose**: API and performance testing
- **Jobs**: `api-test`, `performance-test`

#### 5. **`security-scan.yaml`** - Security Monitoring

- **Trigger**: Weekly schedule (Sundays)
- **Purpose**: Trivy vulnerability scanning
- **Output**: SARIF results to GitHub Security tab

#### Dependency Management

- **Dependabot**: Configured to check for Typesense updates daily
- **Purpose**: Automatically creates PRs for all new Typesense versions
- **Configuration**: No version restrictions - workflow handles filtering internally

## Release Flow

### 🧪 Release Candidate Flow

```
Dockerfile: typesense:29.1.rc2 → release-manager → v29.1.rc2 tag → release-publisher → GitHub RC Release
                                     ↓
                              RC branch + testing issue
```

### 🚀 Stable Release Flow

```
Dockerfile: typesense:29.1 → release-manager → v29.1 tag → release-publisher → GitHub Stable Release
                                ↓                            ↓
                         latest tag update              announcement issue
```

### 🐳 Docker Publishing Flow

```
New tag → publish.yaml → Multi-arch build → ghcr.io images → Cosign signature
```

## Trigger Patterns

### Event-Driven Triggers

- **Dockerfile changes** → Immediate release processing
- **Documentation changes** → Doc generation only
- **New tags** → GitHub release creation
- **Main/PR changes** → Testing

### Schedule Triggers

- **Security scans**: Sundays 00:00 UTC
- **Dependabot updates**: Daily (managed by GitHub Dependabot)

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

## Version Detection Logic

| Dockerfile Version | Detected Type | Tag Created | Release Type |
| ------------------ | ------------- | ----------- | ------------ |
| `29.1.rc2`         | RC            | `v29.1.rc2` | Prerelease   |
| `29.1`             | Stable        | `v29.1`     | Release      |

## File Structure

```
.github/workflows/
├── release-manager.yaml      # 🎯 Master release controller
├── release-publisher.yaml    # 📢 GitHub release creator
├── publish.yaml             # 🐳 Docker image builder
├── tests.yaml               # 🧪 Quality assurance
└── security-scan.yaml       # 🔒 Security monitoring

.github/
└── dependabot.yaml          # 🔄 Dependency updates (Typesense + Actions)
```

## Optimization Benefits

### Before (11 workflows)

- `auto-tag.yaml` + `create-rc.yaml` + `auto-stable-release.yaml` + `docs.yaml`
- `release.yaml` + `release-notification.yaml`
- `auto-pr.yaml` (removed - unnecessary)
- `update-typesense.yaml` (removed - dependabot handles this)
- Plus 3 support workflows

### After (5 workflows + dependabot)

- `release-manager.yaml` (unified release control)
- `release-publisher.yaml` (unified publishing)
- Plus 3 support workflows
- Dependabot for dependency management

**Result**: 55% fewer workflow files, clearer responsibilities, easier maintenance

## Examples

### RC Release Example

1. Update: `FROM typesense/typesense:29.2.rc1`
1. Push to main
1. `release-manager.yaml` detects RC version
1. Creates `v29.2.rc1` tag and RC branch
1. Opens testing issue with checklist
1. `release-publisher.yaml` creates prerelease
1. `publish.yaml` builds Docker images

### Stable Release Example

1. Update: `FROM typesense/typesense:29.2`
1. Push to main
1. `release-manager.yaml` detects stable version
1. Creates `v29.2` tag and updates `latest`
1. `release-publisher.yaml` creates stable release
1. Creates announcement issue
1. Updates documentation and badges

## Dependency Management

### Dependabot Configuration

- **Typesense updates**: Daily checks for all new versions
- **GitHub Actions**: Weekly updates for action versions
- **Ignores**: Nothing - all versions are tracked
- **Auto-PRs**: Creates pull requests with detailed changelogs

### Integration with Release System

1. **Dependabot** creates PR for new Typesense version (any type)
1. **Developer** reviews and merges PR
1. **release-manager.yaml** detects Dockerfile change and filters version type
1. **Automatic release** process begins (RC or stable) or skips (alpha/beta/dev)

## Monitoring

- **Release status**: Check GitHub Actions tab
- **Security**: GitHub Security tab for Trivy results
- **Images**: GitHub Packages for published containers
- **Issues**: Auto-created issues for testing/announcements
- **Dependencies**: Dependabot tab for update status

This optimized system provides the same functionality with better organization, easier maintenance, and automated dependency management.
</edits>
