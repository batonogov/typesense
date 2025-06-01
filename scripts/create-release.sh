#!/bin/bash

# Typesense Release Creation Helper
# Automates the process of creating releases for Typesense with Healthcheck

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DOCKERFILE_PATH="$PROJECT_ROOT/Dockerfile"

# Default values
DRY_RUN=false
PUSH_TAG=true
UPDATE_DOCKERFILE=true
FORCE=false

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

print_usage() {
    cat << EOF
Usage: $0 [COMMAND] [OPTIONS]

Commands:
    stable VERSION      Create a stable release (e.g., 29.0)
    rc VERSION [RC_NUM] Create a release candidate (e.g., 29.0.rc1)
    auto               Auto-detect version from Dockerfile and create appropriate release
    list               List recent releases and tags

Options:
    -h, --help         Show this help message
    -v, --verbose      Enable verbose output
    -n, --dry-run      Show what would be done without executing
    -f, --force        Force creation even if tag exists
    --no-push          Don't push the tag to remote
    --no-dockerfile    Don't update Dockerfile (only create tag)

Examples:
    $0 stable 29.0                    # Create stable release v29.0
    $0 rc 29.0 1                     # Create release candidate v29.0.rc1
    $0 rc 29.0                       # Auto-increment RC number
    $0 auto                          # Auto-detect from Dockerfile
    $0 stable 29.0 --dry-run         # Preview what would happen
    $0 rc 29.0 --no-dockerfile       # Only create tag, don't update Dockerfile

Environment Variables:
    GITHUB_TOKEN       GitHub token for API operations (optional)
EOF
}

validate_version_format() {
    local version="$1"
    local type="$2"

    case "$type" in
        "stable")
            if [[ ! "$version" =~ ^[0-9]+\.[0-9]+$ ]]; then
                log_error "Invalid stable version format: $version"
                log_error "Expected format: X.Y (e.g., 29.0)"
                return 1
            fi
            ;;
        "rc")
            if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.rc[0-9]+$ ]]; then
                log_error "Invalid RC version format: $version"
                log_error "Expected format: X.Y.rcN (e.g., 29.0.rc1)"
                return 1
            fi
            ;;
        *)
            log_error "Unknown version type: $type"
            return 1
            ;;
    esac

    return 0
}

get_current_version_from_dockerfile() {
    if [[ ! -f "$DOCKERFILE_PATH" ]]; then
        log_error "Dockerfile not found: $DOCKERFILE_PATH"
        return 1
    fi

    local version
    version=$(grep -o 'typesense/typesense:[0-9][0-9]*\.[0-9][0-9]*\(\.rc[0-9][0-9]*\)*' "$DOCKERFILE_PATH" | sed 's/typesense\/typesense://' || true)

    if [[ -z "$version" ]]; then
        log_error "Could not extract version from Dockerfile"
        return 1
    fi

    echo "$version"
}

get_next_rc_number() {
    local base_version="$1"

    # Find existing RC tags for this base version
    local existing_rcs
    existing_rcs=$(git tag -l "v${base_version}.rc*" | sed "s/v${base_version}\.rc//g" | sort -n || true)

    if [[ -z "$existing_rcs" ]]; then
        echo "1"
    else
        local last_rc
        last_rc=$(echo "$existing_rcs" | tail -1)
        echo $((last_rc + 1))
    fi
}

check_tag_exists() {
    local tag="$1"

    if git rev-parse "$tag" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

update_dockerfile_version() {
    local new_version="$1"

    if [[ "$DRY_RUN" == true ]]; then
        log_info "Would update Dockerfile with version: $new_version"
        return 0
    fi

    log_step "Updating Dockerfile with version: $new_version"

    # Create backup
    cp "$DOCKERFILE_PATH" "$DOCKERFILE_PATH.backup"

    # Update version in Dockerfile
    sed -i.bak "s/typesense\/typesense:[0-9][0-9]*\.[0-9][0-9]*\(\.rc[0-9][0-9]*\)*/typesense\/typesense:$new_version/" "$DOCKERFILE_PATH"

    # Remove backup file
    rm -f "$DOCKERFILE_PATH.bak"

    log_success "Dockerfile updated successfully"
}

create_git_tag() {
    local version="$1"
    local tag_name="v$version"
    local message="$2"

    if [[ "$DRY_RUN" == true ]]; then
        log_info "Would create git tag: $tag_name"
        return 0
    fi

    log_step "Creating git tag: $tag_name"

    # Check if tag already exists
    if check_tag_exists "$tag_name"; then
        if [[ "$FORCE" == true ]]; then
            log_warning "Tag exists, deleting due to --force flag"
            git tag -d "$tag_name"
            if [[ "$PUSH_TAG" == true ]]; then
                git push origin ":refs/tags/$tag_name" || log_warning "Failed to delete remote tag"
            fi
        else
            log_error "Tag already exists: $tag_name"
            log_error "Use --force to overwrite or choose a different version"
            return 1
        fi
    fi

    # Create the tag
    git tag -a "$tag_name" -m "$message"
    log_success "Created git tag: $tag_name"

    # Push tag if requested
    if [[ "$PUSH_TAG" == true ]]; then
        log_step "Pushing tag to remote"
        git push origin "$tag_name"
        log_success "Tag pushed to remote: $tag_name"
    fi
}

commit_dockerfile_changes() {
    local version="$1"

    if [[ "$DRY_RUN" == true ]]; then
        log_info "Would commit Dockerfile changes"
        return 0
    fi

    if git diff --quiet "$DOCKERFILE_PATH"; then
        log_info "No changes to commit in Dockerfile"
        return 0
    fi

    log_step "Committing Dockerfile changes"
    git add "$DOCKERFILE_PATH"
    git commit -m "Update Typesense to version $version"
    log_success "Dockerfile changes committed"
}

get_release_message() {
    local version="$1"
    local type="$2"

    case "$type" in
        "stable")
            echo "Typesense $version - Stable Release

This release updates Typesense to version $version with integrated healthcheck support.

Docker image: ghcr.io/batonogov/typesense:v$version"
            ;;
        "rc")
            local base_version
            base_version=${version%.rc*}
            local rc_number
            rc_number=$(echo "$version" | sed -n 's/.*\.rc\([0-9][0-9]*\).*/\1/p')

            echo "Typesense $version - Release Candidate

This is release candidate $rc_number based on Typesense $base_version.
This version is intended for testing purposes only.

Docker image: ghcr.io/batonogov/typesense:v$version

Please test thoroughly before promoting to stable release."
            ;;
    esac
}

list_releases() {
    log_info "Recent releases and tags:"
    echo

    echo "Stable releases:"
    git tag -l "v*.*" | grep -v "rc" | sort -V | tail -5 | while read -r tag; do
        echo "  $tag"
    done

    echo
    echo "Recent release candidates:"
    git tag -l "v*.*.rc*" | sort -V | tail -5 | while read -r tag; do
        echo "  $tag"
    done

    echo
    echo "Current Dockerfile version:"
    local current_version
    current_version=$(get_current_version_from_dockerfile)
    echo "  $current_version"
}

trigger_github_workflow() {
    local workflow="$1"
    local inputs="$2"

    if [[ -z "${GITHUB_TOKEN:-}" ]]; then
        log_warning "GITHUB_TOKEN not set, cannot trigger GitHub workflow"
        return 0
    fi

    if command -v gh >/dev/null 2>&1; then
        log_step "Triggering GitHub workflow: $workflow"
        if [[ -n "$inputs" ]]; then
            gh workflow run "$workflow" "$inputs"
        else
            gh workflow run "$workflow"
        fi
        log_success "GitHub workflow triggered: $workflow"
    else
        log_warning "GitHub CLI (gh) not found, cannot trigger workflow"
    fi
}

create_stable_release() {
    local version="$1"

    validate_version_format "$version" "stable"

    log_info "Creating stable release: $version"

    if [[ "$UPDATE_DOCKERFILE" == true ]]; then
        update_dockerfile_version "$version"
        commit_dockerfile_changes "$version"
    fi

    local message
    message=$(get_release_message "$version" "stable")

    create_git_tag "$version" "$message"

    log_success "Stable release $version created successfully!"
    log_info "Docker image will be available at: ghcr.io/batonogov/typesense:v$version"
    log_info "Release notes will be generated automatically"
}

create_rc_release() {
    local base_version="$1"
    local rc_number="${2:-}"

    # Auto-increment RC number if not provided
    if [[ -z "$rc_number" ]]; then
        rc_number=$(get_next_rc_number "$base_version")
        log_info "Auto-incremented RC number: $rc_number"
    fi

    local full_version="${base_version}.rc${rc_number}"

    validate_version_format "$full_version" "rc"

    log_info "Creating release candidate: $full_version"

    if [[ "$UPDATE_DOCKERFILE" == true ]]; then
        update_dockerfile_version "$full_version"
        commit_dockerfile_changes "$full_version"
    fi

    local message
    message=$(get_release_message "$full_version" "rc")

    create_git_tag "$full_version" "$message"

    # Trigger RC creation workflow if possible
    trigger_github_workflow "create-rc.yaml" "-f rc_number=$rc_number"

    log_success "Release candidate $full_version created successfully!"
    log_info "Docker image will be available at: ghcr.io/batonogov/typesense:v$full_version"
    log_info "Testing issue will be created automatically"
}

auto_create_release() {
    log_info "Auto-detecting release type from Dockerfile"

    local current_version
    current_version=$(get_current_version_from_dockerfile)

    log_info "Current version in Dockerfile: $current_version"

    if [[ "$current_version" =~ \.rc[0-9]+$ ]]; then
        log_info "Detected release candidate version"

        # Ask user what to do
        echo "Current version is a release candidate: $current_version"
        echo "What would you like to do?"
        echo "1) Create new RC for same base version"
        echo "2) Promote to stable release"
        echo "3) Cancel"

        read -r -p "Choose option [1-3]: " choice

        case "$choice" in
            1)
                local base_version
                base_version=${current_version%.rc*}
                create_rc_release "$base_version"
                ;;
            2)
                local base_version
                base_version=${current_version%.rc*}
                create_stable_release "$base_version"
                ;;
            *)
                log_info "Operation cancelled"
                exit 0
                ;;
        esac
    else
        log_info "Detected stable version, creating stable release"
        create_stable_release "$current_version"
    fi
}

main() {
    local command=""
    local version=""
    local rc_number=""

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                print_usage
                exit 0
                ;;
            -v|--verbose)
                # VERBOSE=true  # Currently unused
                shift
                ;;
            -n|--dry-run)
                DRY_RUN=true
                log_warning "DRY RUN MODE - No actual operations will be performed"
                shift
                ;;
            -f|--force)
                FORCE=true
                shift
                ;;
            --no-push)
                PUSH_TAG=false
                shift
                ;;
            --no-dockerfile)
                UPDATE_DOCKERFILE=false
                shift
                ;;
            stable|rc|auto|list)
                command="$1"
                shift
                break
                ;;
            *)
                log_error "Unknown option: $1"
                print_usage
                exit 1
                ;;
        esac
    done

    # Parse remaining arguments based on command
    case "$command" in
        stable)
            if [[ $# -lt 1 ]]; then
                log_error "Stable release requires version argument"
                print_usage
                exit 1
            fi
            version="$1"
            ;;
        rc)
            if [[ $# -lt 1 ]]; then
                log_error "RC release requires version argument"
                print_usage
                exit 1
            fi
            version="$1"
            if [[ $# -gt 1 ]]; then
                rc_number="$2"
            fi
            ;;
        auto|list)
            # No additional arguments needed
            ;;
        *)
            log_error "No command specified"
            print_usage
            exit 1
            ;;
    esac

    # Change to project root
    cd "$PROJECT_ROOT"

    # Verify we're in a git repository
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        log_error "Not in a git repository"
        exit 1
    fi

    # Execute command
    case "$command" in
        stable)
            create_stable_release "$version"
            ;;
        rc)
            create_rc_release "$version" "$rc_number"
            ;;
        auto)
            auto_create_release
            ;;
        list)
            list_releases
            ;;
    esac
}

# Check if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
