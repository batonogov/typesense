#!/bin/bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
README_FILE="README.md"
VERBOSE=false
CHECK_LINKS=true
TIMEOUT=10

# Usage function
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Validate badges in README.md"
    echo ""
    echo "Options:"
    echo "  -f, --file FILE     README file to check (default: README.md)"
    echo "  -v, --verbose       Enable verbose output"
    echo "  -t, --timeout SEC   HTTP timeout in seconds (default: 10)"
    echo "  --no-links          Skip checking badge destination links"
    echo "  -h, --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                  # Check badges in README.md"
    echo "  $0 -v -t 5          # Verbose mode with 5s timeout"
    echo "  $0 --no-links       # Skip checking destination links"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--file)
            README_FILE="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -t|--timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        --no-links)
            CHECK_LINKS=false
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Check if README file exists
if [[ ! -f "$README_FILE" ]]; then
    echo -e "${RED}Error: $README_FILE not found${NC}"
    exit 1
fi

# Initialize counters
total_badges=0
valid_badges=0
invalid_badges=0
total_links=0
valid_links=0
invalid_links=0

# Function to log verbose messages
log_verbose() {
    if [[ "$VERBOSE" == true ]]; then
        echo -e "${BLUE}[VERBOSE]${NC} $1"
    fi
}

# Function to check URL accessibility
check_url() {
    local url="$1"
    local type="$2"
    local description="$3"

    log_verbose "Checking $type: $url"

    if curl -f -s -L --max-time "$TIMEOUT" "$url" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} $description"
        return 0
    else
        echo -e "${RED}✗${NC} $description"
        echo -e "  ${YELLOW}URL:${NC} $url"
        return 1
    fi
}

# Function to extract and validate badges
validate_badges() {
    echo -e "${BLUE}=== Validating Badges ===${NC}"

    # Define regex pattern for markdown badges: [![text](badge_url)](link_url)
    local badge_pattern='!\[([^]]*)\]\(([^)]+)\)\]\(([^)]+)\)'

    # Extract badge patterns from README
    while IFS= read -r line; do
        # Match markdown badge pattern: [![text](badge_url)](link_url)
        if [[ $line =~ $badge_pattern ]]; then
            badge_text="${BASH_REMATCH[1]}"
            badge_url="${BASH_REMATCH[2]}"
            link_url="${BASH_REMATCH[3]}"

            ((total_badges++))

            echo ""
            echo -e "${YELLOW}Badge:${NC} $badge_text"

            # Check badge URL
            if check_url "$badge_url" "badge" "Badge image accessible"; then
                ((valid_badges++))
            else
                ((invalid_badges++))
            fi

            # Check destination link if enabled
            if [[ "$CHECK_LINKS" == true ]]; then
                ((total_links++))
                if check_url "$link_url" "link" "Badge destination accessible"; then
                    ((valid_links++))
                else
                    ((invalid_links++))
                fi
            fi
        fi
    done < "$README_FILE"
}

# Function to check for common badge issues
check_badge_issues() {
    echo -e "\n${BLUE}=== Checking Common Issues ===${NC}"

    # Check for HTTP vs HTTPS
    if grep -q "http://img.shields.io" "$README_FILE"; then
        echo -e "${YELLOW}⚠${NC} Found HTTP shield.io URLs (should use HTTPS)"
    fi

    # Check for inconsistent styles
    local style_count
    style_count=$(grep -o "style=[^&)]*" "$README_FILE" | sort -u | wc -l)
    if [[ $style_count -gt 1 ]]; then
        echo -e "${YELLOW}⚠${NC} Multiple badge styles detected:"
        grep -o "style=[^&)]*" "$README_FILE" | sort -u | sed 's/^/  - /'
    fi

    # Check for missing alt text
    if grep -q "\[\!\[\]\(" "$README_FILE"; then
        echo -e "${YELLOW}⚠${NC} Found badges with empty alt text"
    fi

    # Check for very long badge URLs (potential formatting issues)
    while IFS= read -r line; do
        if [[ ${#line} -gt 200 && $line =~ \[\!\[ ]]; then
            echo -e "${YELLOW}⚠${NC} Very long badge line detected (potential formatting issue)"
            break
        fi
    done < "$README_FILE"
}

# Function to suggest improvements
suggest_improvements() {
    echo -e "\n${BLUE}=== Suggestions ===${NC}"

    # Check if flat-square style is used consistently
    if ! grep -q "style=flat-square" "$README_FILE"; then
        echo -e "${YELLOW}💡${NC} Consider using flat-square style for better appearance"
    fi

    # Check for missing common badges
    if ! grep -q "license" "$README_FILE"; then
        echo -e "${YELLOW}💡${NC} Consider adding a license badge"
    fi

    if ! grep -q "release" "$README_FILE"; then
        echo -e "${YELLOW}💡${NC} Consider adding a latest release badge"
    fi

    if ! grep -q "docker.*size\|image.*size" "$README_FILE"; then
        echo -e "${YELLOW}💡${NC} Consider adding a Docker image size badge"
    fi
}

# Function to print summary
print_summary() {
    echo -e "\n${BLUE}=== Summary ===${NC}"
    echo -e "Badges checked: $total_badges"
    echo -e "${GREEN}Valid badges:${NC} $valid_badges"
    if [[ $invalid_badges -gt 0 ]]; then
        echo -e "${RED}Invalid badges:${NC} $invalid_badges"
    fi

    if [[ "$CHECK_LINKS" == true ]]; then
        echo -e "Links checked: $total_links"
        echo -e "${GREEN}Valid links:${NC} $valid_links"
        if [[ $invalid_links -gt 0 ]]; then
            echo -e "${RED}Invalid links:${NC} $invalid_links"
        fi
    fi

    if [[ $invalid_badges -eq 0 && ($invalid_links -eq 0 || "$CHECK_LINKS" == false) ]]; then
        echo -e "\n${GREEN}🎉 All badges are working correctly!${NC}"
        exit 0
    else
        echo -e "\n${RED}❌ Some badges or links are not working${NC}"
        exit 1
    fi
}

# Main execution
main() {
    echo -e "${BLUE}🏷️  Badge Validator${NC}"
    echo -e "Checking badges in: $README_FILE"
    echo -e "Timeout: ${TIMEOUT}s"
    echo ""

    validate_badges
    check_badge_issues
    suggest_improvements
    print_summary
}

# Run main function
main
