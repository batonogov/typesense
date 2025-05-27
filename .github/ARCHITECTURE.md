# GitHub Actions Architecture Overview

## System Design

This repository uses an **optimized event-driven CI/CD architecture** with 5 core workflows and automated dependency management.

## Architecture Diagram

```
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

## Workflow Responsibilities

### 🎯 Primary Release Workflows

#### `release-manager.yaml`

- **Role**: Master release orchestrator
- **Triggers**: Dockerfile changes, documentation updates, manual dispatch
- **Responsibilities**:
  - Detect change types (RC vs Stable vs Docs)
  - Create appropriate git tags
  - Manage RC-specific tasks (testing issues, branches)
  - Handle stable release tasks (latest tag updates)
  - Generate documentation updates
- **Output**: Git tags, RC branches, testing issues

#### `release-publisher.yaml`

- **Role**: GitHub release creator and notifier
- **Triggers**: New git tags (`v*.*`, `v*.*.rc*`, `v*.*rc*`)
- **Responsibilities**:
  - Create GitHub releases with rich descriptions
  - Update
