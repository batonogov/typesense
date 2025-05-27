# Complete Automation Flow

## Overview

This document describes the fully automated release pipeline for Typesense stable and RC versions, from dependency updates to Docker image deployment.

## Full Automation Flow

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   New Typesense │    │    Dependabot    │    │   Pull Request  │
│   Version       │───▶│   Daily Check    │───▶│   Created       │
│   Released      │    │ (Stable + RC)    │    │   Automatically │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                                         │
                                                         ▼
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Developer     │    │    Dockerfile    │    │   PR Review &   │
│   Merges PR     │◀───│    Updated       │◀───│   Merge         │
│                 │    │                  │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                       │
         ▼                       ▼
┌─────────────────┐    ┌──────────────────┐
│ release-manager │    │  Version Check   │
│   Triggered     │───▶│  RC vs Stable    │
│                 │    │                  │
└─────────────────┘    └──────────────────┘
                                │
                    ┌───────────┴───────────┐
                    ▼                       ▼
         ┌─────────────────┐      ┌─────────────────┐
         │   RC Version    │      │ Stable Version  │
         │   (29.0.rc1)    │      │   (29.0)        │
         └─────────────────┘      └─────────────────┘
                    │                       │
                    ▼                       ▼
         ┌─────────────────┐      ┌─────────────────┐
         │  Creates RC:    │      │ Creates Stable: │
         │  • v29.0.rc1    │      │ • v29.0 tag     │
         │  • RC branch    │      │ • latest tag    │
         │  • Testing issue│      │ • Announcement  │
         └─────────────────┘      └─────────────────┘
                    │                       │
                    └───────────┬───────────┘
                                ▼
                    ┌─────────────────┐
                    │   Tag Created   │
                    │   Triggers      │
                    │ release-publisher│
                    └─────────────────┘
                                │
                                ▼
                    ┌─────────────────┐
                    │ GitHub Release  │
                    │ • Full details  │
                    │ • Notifications │
                    │ • Badge updates │
                    └─────────────────┘
                                │
                                ▼
                    ┌─────────────────┐
                    │ publish.yaml    │
                    │ • Multi-arch    │
                    │ • GHCR upload   │
                    │ • Cosign sign   │
                    └─────────────────┘
                                │
                                ▼
                    ┌─────────────────┐
                    │ Docker Images   │
                    │ Ready for Use   │
                    │ ghcr.io/repo:   │
                    │ version         │
                    └─────────────────┘
```

## Automation Components

### 1. Dependabot (Daily)

- **Monitors**: Typesense Docker Hub for new versions
- **Creates**: Automatic PRs for version updates
- **Includes**: Stable versions (29.0) and RC versions (29.0.rc1)
- **Excludes**: Alpha, beta, and dev versions

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

## Version-Specific Flows

### RC Version Flow (29.0.rc1)

```
Dependabot PR → Merge → release-manager detects RC → Creates:
├── v29.0.rc1 tag
├── rc/29.0.rc1 branch
├── Testing issue with checklist
└── Triggers release-publisher for prerelease
```

### Stable Version Flow (29.0)

```
Dependabot PR → Merge → release-manager detects Stable → Creates:
├── v29.0 tag
├── Updates latest tag
├── Announcement issue
└── Triggers release-publisher for stable release
```

## Human Interaction Points

### Required

- **PR Review**: Merging dependabot PRs (stable or RC versions only)
- **RC Testing**: Following testing checklist in created issues (for RC versions)
- **Issue Management**: Closing resolved testing/announcement issues

### Optional

- **Manual RC Creation**: Force create specific RC numbers
- **Manual Releases**: Emergency releases with workflow_dispatch
- **Configuration Updates**: Adjusting dependabot settings

## Timing Expectations

### Typical Flow Duration

1. **Dependabot Detection**: < 1 hour after Typesense release
1. **PR Creation**: Immediate after detection
1. **PR Review & Merge**: Human-dependent (minutes to days)
1. **Automated Release**: 2-5 minutes after merge
1. **Docker Images**: 5-10 minutes for multi-arch build
1. **Full Availability**: ~15 minutes total automation time

### Frequency

- **Dependabot Checks**: Daily at various times
- **RC Releases**: As soon as RC versions are available
- **Stable Releases**: As soon as stable versions are available
- **Security Scans**: Weekly (Sundays)

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

## Benefits of Automation

### Speed

- **Immediate response** to new Typesense versions
- **No manual intervention** required for standard releases
- **Parallel processing** of build and documentation tasks

### Reliability

- **Consistent process** every time
- **No human errors** in version detection or tagging
- **Automated testing** at every step

### Scalability

- **Handles multiple versions** simultaneously
- **No bottlenecks** from manual processes
- **Easy to extend** with additional automation

This automated system ensures that new Typesense stable and RC versions are available as Docker images with minimal delay and maximum reliability.
