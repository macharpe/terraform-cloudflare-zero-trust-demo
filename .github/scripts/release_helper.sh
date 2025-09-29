#!/bin/bash
# 🚀 Release Helper Script
# Extracts release information from CHANGELOG.md following Keep a Changelog format

set -euo pipefail

CHANGELOG_FILE="CHANGELOG.md"

# Function to extract the latest version from CHANGELOG.md
get_latest_version() {
    grep -E "^## \[[0-9]+\.[0-9]+\.[0-9]+\]" "$CHANGELOG_FILE" | head -n 1 | sed -E 's/^## \[([0-9]+\.[0-9]+\.[0-9]+)\].*/\1/'
}

# Function to extract release notes for a specific version
extract_release_notes() {
    local version="$1"
    local in_section=false
    local content=""

    while IFS= read -r line; do
        if [[ $line =~ ^##[[:space:]]\[$version\] ]]; then
            in_section=true
            continue
        elif [[ $line =~ ^##[[:space:]]\[ ]] && $in_section; then
            break
        elif $in_section; then
            content+="$line"$'\n'
        fi
    done < "$CHANGELOG_FILE"

    # Clean up the content
    echo "$content" | sed '/^[[:space:]]*$/d' | sed '$d' | sed '1d'
}

# Function to determine release type based on changelog content
determine_release_type() {
    local version="$1"
    local notes
    notes=$(extract_release_notes "$version")

    if echo "$notes" | grep -qi "breaking\|**BREAKING**"; then
        echo "major"
    elif echo "$notes" | grep -qi "### Added\|**NEW**\|feat:"; then
        echo "minor"
    elif echo "$notes" | grep -qi "### Fixed\|fix:"; then
        echo "patch"
    else
        echo "patch"  # Default to patch
    fi
}

# Function to generate release title based on content
generate_release_title() {
    local version="$1"
    local notes
    notes=$(extract_release_notes "$version")

    # Look for key themes in the release
    if echo "$notes" | grep -qi "documentation\|docs"; then
        echo "v$version - Documentation Update"
    elif echo "$notes" | grep -qi "security\|**SECURITY**"; then
        echo "v$version - Security Update"
    elif echo "$notes" | grep -qi "performance\|optimization"; then
        echo "v$version - Performance Improvements"
    elif echo "$notes" | grep -qi "breaking\|**BREAKING**"; then
        echo "v$version - Breaking Changes"
    elif echo "$notes" | grep -qi "### Added\|**NEW**"; then
        echo "v$version - New Features"
    elif echo "$notes" | grep -qi "### Fixed\|fix:"; then
        echo "v$version - Bug Fixes"
    else
        echo "v$version"
    fi
}

# Main script logic
case "${1:-}" in
    "version")
        get_latest_version
        ;;
    "notes")
        if [ $# -lt 2 ]; then
            echo "Usage: $0 notes <version>"
            exit 1
        fi
        extract_release_notes "$2"
        ;;
    "type")
        if [ $# -lt 2 ]; then
            echo "Usage: $0 type <version>"
            exit 1
        fi
        determine_release_type "$2"
        ;;
    "title")
        if [ $# -lt 2 ]; then
            echo "Usage: $0 title <version>"
            exit 1
        fi
        generate_release_title "$2"
        ;;
    *)
        echo "🚀 Release Helper Script"
        echo ""
        echo "Usage: $0 <command> [args...]"
        echo ""
        echo "Commands:"
        echo "  version              Get the latest version from CHANGELOG.md"
        echo "  notes <version>      Extract release notes for a version"
        echo "  type <version>       Determine release type (major/minor/patch)"
        echo "  title <version>      Generate release title"
        echo ""
        echo "Examples:"
        echo "  $0 version"
        echo "  $0 notes 2.2.1"
        echo "  $0 type 2.2.1"
        echo "  $0 title 2.2.1"
        ;;
esac