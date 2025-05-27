# Dependabot Configuration Fix

## Problem

Dependabot encountered a parsing error in `.github/dependabot.yaml`:

```
The property '#/updates/1/ignore/0/versions' includes invalid version requirements for a docker ignore condition
```

The error was caused by invalid version patterns in the Docker ecosystem configuration:

```yaml
ignore:
  - dependency-name: "*"
    versions: ["*-alpha*", "*-beta*", "*-dev*"]
```

## Root Cause

Docker ecosystem in Dependabot has stricter requirements for version ignore patterns compared to other package ecosystems. The wildcard patterns we used were not supported for Docker dependencies.

## Solution Approach

Instead of trying to fix the Dependabot patterns, we moved the version filtering logic into our GitHub Actions workflow for better control and reliability.

### Before (Broken)

- Dependabot tried to filter versions using invalid patterns
- Configuration failed to parse
- No automatic updates possible

### After (Working)

- Dependabot tracks ALL Typesense versions without restrictions
- `release-manager.yaml` workflow handles version filtering internally
- Only stable and RC versions trigger releases
- Alpha/beta/dev versions are automatically skipped with clear logging

## Implementation Details

### 1. Simplified Dependabot Configuration

```yaml
- package-ecosystem: "docker"
  directory: "/"
  schedule:
    interval: "daily"
  # No ignore patterns - let workflow handle filtering
```

### 2. Enhanced Workflow Logic

Added version detection in `release-manager.yaml`:

```bash
# Check if version should be ignored (alpha, beta, dev)
if [[ "$VERSION" == *"alpha"* ]] || [[ "$VERSION" == *"beta"* ]] || [[ "$VERSION" == *"dev"* ]]; then
  echo "should_skip=true" >> $GITHUB_OUTPUT
  echo "⚠️ Skipping version $VERSION (alpha/beta/dev not supported)"
  exit 0
fi
```

### 3. Conditional Workflow Execution

All subsequent jobs check the `should_skip` flag:

```yaml
if: needs.detect-changes.outputs.should_skip != 'true'
```

## Benefits

1. **Reliable Configuration**: No more Dependabot parsing errors
1. **Better Control**: Version filtering logic is visible and customizable
1. **Clear Logging**: Explicit messages when versions are skipped
1. **Flexibility**: Easy to modify filtering rules without touching Dependabot config
1. **Transparency**: PR descriptions will show all versions, workflow decides processing

## Supported Versions

| Version Type | Example        | Dependabot PR | Workflow Action      |
| ------------ | -------------- | ------------- | -------------------- |
| Stable       | `29.0`, `29.1` | ✅ Creates PR | ✅ Processes release |
| RC           | `29.0.rc1`     | ✅ Creates PR | ✅ Processes release |
| Alpha        | `29.0.alpha1`  | ✅ Creates PR | ⏭️ Skips processing  |
| Beta         | `29.0.beta1`   | ✅ Creates PR | ⏭️ Skips processing  |
| Dev          | `29.0.dev`     | ✅ Creates PR | ⏭️ Skips processing  |

## Testing

To verify the fix works:

1. Check Dependabot configuration is valid (no parsing errors)
1. Confirm daily Dependabot runs complete successfully
1. Test workflow with different version types to ensure proper filtering
1. Verify skipped versions show clear log messages

## Future Maintenance

If version filtering rules need to change:

- Modify the detection logic in `release-manager.yaml`
- No need to touch `dependabot.yaml`
- Test changes with different version formats
- Update documentation if filtering criteria change

This approach provides a more robust and maintainable solution than trying to work around Dependabot's Docker ecosystem limitations.
