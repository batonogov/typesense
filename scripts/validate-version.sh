#!/bin/bash

# Typesense Version Validation Script
# Validates version format and checks image availability

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DOCKERFILE_PATH="$PROJECT_ROOT/Dockerfile"

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

print_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Validates Typesense version from Dockerfile and optionally checks image availability.

Options:
    -h, --help          Show this help message
    -v, --verbose       Enable verbose output
    -c, --check-image   Check if Docker image is available
    -f, --dockerfile    Path to Dockerfile (default: ../Dockerfile)
    --dry-run          Show what would be done without executing

Examples:
    $0                          # Basic validation
    $0 -c                       # Validate and check image availability
    $0 -f /path/to/Dockerfile   # Use custom Dockerfile path
    $0 -v -c                    # Verbose mode with image check
EOF
}

extract_version_from_dockerfile() {
    local dockerfile_path="$1"

    if [[ ! -f "$dockerfile_path" ]]; then
        log_error "Dockerfile not found: $dockerfile_path"
        return 1
    fi

    local version
    version=$(grep -o 'typesense/typesense:[0-9][0-9]*\.[0-9][0-9]*\(\.rc[0-9][0-9]*\)*' "$dockerfile_path" | sed 's/typesense\/typesense://' || true)

    if [[ -z "$version" ]]; then
        log_error "Could not extract Typesense version from Dockerfile"
        return 1
    fi

    echo "$version"
}

validate_version_format() {
    local version="$1"

    # Check for stable version format (X.Y)
    if [[ "$version" =~ ^[0-9]+\.[0-9]+$ ]]; then
        echo "stable"
        return 0
    fi

    # Check for RC version format (X.Y.rcN)
    if [[ "$version" =~ ^[0-9]+\.[0-9]+\.rc[0-9]+$ ]]; then
        echo "rc"
        return 0
    fi

    return 1
}

get_git_tag_for_version() {
    local version="$1"
    echo "v$version"
}

check_git_tag_exists() {
    local tag="$1"

    if git rev-parse "$tag" >/dev/null 2>&1; then
        log_warning "Git tag already exists: $tag"
        return 0
    else
        log_info "Git tag does not exist: $tag"
        return 1
    fi
}

check_docker_image_availability() {
    local version="$1"
    local image="ghcr.io/batonogov/typesense:$version"

    log_info "Checking Docker image availability: $image"

    # Check if image exists using docker manifest
    if docker manifest inspect "$image" >/dev/null 2>&1; then
        log_success "Docker image is available: $image"
        return 0
    else
        log_warning "Docker image not available: $image"
        return 1
    fi
}

get_version_info() {
    local version="$1"
    local version_type="$2"

    echo "Version Information:"
    echo "  Version: $version"
    echo "  Type: $version_type"
    echo "  Git Tag: $(get_git_tag_for_version "$version")"

    if [[ "$version_type" == "rc" ]]; then
        local base_version
        base_version=${version%.rc*}
        local rc_number
        rc_number=$(echo "$version" | sed -n 's/.*\.rc\([0-9][0-9]*\).*/\1/p')
        echo "  Base Version: $base_version"
        echo "  RC Number: $rc_number"
    fi
}

validate_version_progression() {
    local version="$1"
    local version_type="$2"

    # Get latest stable version from git tags
    local latest_stable
    latest_stable=$(git tag -l "v*.*" | grep -v "rc" | sort -V | tail -1 | sed 's/^v//' || echo "")

    if [[ -n "$latest_stable" ]]; then
        log_info "Latest stable version: $latest_stable"

        # Extract major.minor for comparison
        local current_major_minor
        if [[ "$version_type" == "rc" ]]; then
            current_major_minor=${version%.rc*}
        else
            current_major_minor="$version"
        fi

        # Compare versions
        if [[ "$(printf '%s\n' "$latest_stable" "$current_major_minor" | sort -V | tail -1)" == "$current_major_minor" ]]; then
            if [[ "$current_major_minor" == "$latest_stable" ]]; then
                log_info "Version matches latest stable release"
            else
                log_success "Version is newer than latest stable release"
            fi
        else
            log_warning "Version is older than latest stable release ($latest_stable)"
        fi
    else
        log_info "No previous stable releases found"
    fi
}

main() {
    local verbose=false
    local check_image=false
    local dockerfile_path="$DOCKERFILE_PATH"
    local dry_run=false

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                print_usage
                exit 0
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            -c|--check-image)
                check_image=true
                shift
                ;;
            -f|--dockerfile)
                dockerfile_path="$2"
                shift 2
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                print_usage
                exit 1
                ;;
        esac
    done

    log_info "Starting Typesense version validation"

    if [[ "$dry_run" == true ]]; then
        log_info "DRY RUN MODE - No actual operations will be performed"
    fi

    # Extract version from Dockerfile
    log_info "Extracting version from: $dockerfile_path"
    local version
    if ! version=$(extract_version_from_dockerfile "$dockerfile_path"); then
        exit 1
    fi

    log_info "Extracted version: $version"

    # Validate version format
    local version_type
    if ! version_type=$(validate_version_format "$version"); then
        log_error "Invalid version format: $version"
        log_error "Expected formats:"
        log_error "  - Stable: X.Y (e.g., 29.0)"
        log_error "  - RC: X.Y.rcN (e.g., 29.0.rc26)"
        exit 1
    fi

    if [[ "$version_type" == "stable" ]]; then
        log_success "Valid stable version format: $version"
    elif [[ "$version_type" == "rc" ]]; then
        log_success "Valid release candidate format: $version"
    fi

    # Show version information
    if [[ "$verbose" == true ]]; then
        echo
        get_version_info "$version" "$version_type"
        echo
    fi

    # Check git tag existence
    local git_tag
    git_tag=$(get_git_tag_for_version "$version")
    check_git_tag_exists "$git_tag"

    # Validate version progression
    if [[ "$verbose" == true ]]; then
        echo
        validate_version_progression "$version" "$version_type"
        echo
    fi

    # Check Docker image availability if requested
    if [[ "$check_image" == true && "$dry_run" == false ]]; then
        echo
        check_docker_image_availability "$version"
    fi

    # Summary
    echo
    log_success "Version validation completed successfully"
    log_info "Version: $version ($version_type)"
    log_info "Git tag: $git_tag"

    if [[ "$check_image" == true && "$dry_run" == false ]]; then
        log_info "Docker image: ghcr.io/batonogov/typesense:v$version"
    fi
}

# Check if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
