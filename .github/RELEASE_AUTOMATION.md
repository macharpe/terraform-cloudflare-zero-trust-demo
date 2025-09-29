# 🚀 Automated Release System

This repository uses an automated release system that creates GitHub releases whenever the `CHANGELOG.md` file is updated with a new version.

## 🎯 How It Works

### Trigger
- **Automatic**: Triggered when `CHANGELOG.md` is pushed to the `main` branch
- **Detection**: Scans for new version headers in the format `## [X.Y.Z] - YYYY-MM-DD`
- **Smart**: Only creates releases for versions that don't already exist as Git tags

### Workflow Steps
1. **Extract Version**: Parses the latest version from `CHANGELOG.md`
2. **Check Existence**: Verifies the version doesn't already exist as a Git tag
3. **Extract Notes**: Pulls release notes from the version section
4. **Create Tag**: Creates and pushes a Git tag (`vX.Y.Z`)
5. **Create Release**: Generates a GitHub release with the extracted content

## 📝 CHANGELOG.md Format Requirements

The automation expects your `CHANGELOG.md` to follow [Keep a Changelog](https://keepachangelog.com) format:

```markdown
## [Unreleased]

## [2.2.1] - 2025-09-29

### Fixed
- Bug fix description here
- Another fix

### Added
- New feature description

## [2.2.0] - 2025-09-28
...
```

### Required Elements
- **Version Header**: `## [X.Y.Z] - YYYY-MM-DD`
- **Semantic Versioning**: Version numbers must follow `MAJOR.MINOR.PATCH` format
- **Section Headers**: Use `### Added`, `### Changed`, `### Fixed`, etc.
- **Chronological Order**: Latest version at the top (after `[Unreleased]`)

## 🔄 Workflow Files

### `.github/workflows/release.yml`
Main GitHub Actions workflow that handles the automation:
- **Triggered by**: Pushes to `main` that modify `CHANGELOG.md`
- **Permissions**: `contents: write` for creating tags and releases
- **Actions Used**: `actions/checkout@v4`, `ncipollo/action-gh-release@v2`

### `.github/scripts/release_helper.sh`
Helper script for advanced release processing:
- **Version extraction** from CHANGELOG.md
- **Release notes parsing** for specific versions
- **Release type detection** (major/minor/patch)
- **Smart title generation** based on content

## 🎛️ Release Types

The system automatically detects release types based on changelog content:

| Type | Triggers | Example |
|------|----------|---------|
| **Major** | Breaking changes, `**BREAKING**` | API changes, incompatible updates |
| **Minor** | New features, `### Added`, `**NEW**` | New functionality, enhancements |
| **Patch** | Bug fixes, `### Fixed`, `fix:` | Bug fixes, security patches |

## 🏷️ Release Titles

Generated automatically based on changelog content:

- **Documentation Update**: Contains "documentation" or "docs"
- **Security Update**: Contains "security" or `**SECURITY**`
- **Performance Improvements**: Contains "performance" or "optimization"
- **Breaking Changes**: Contains "breaking" or `**BREAKING**`
- **New Features**: Contains `### Added` or `**NEW**`
- **Bug Fixes**: Contains `### Fixed` or `fix:`

## 📋 Best Practices

### For Developers
1. **Update CHANGELOG.md first**: Add your changes to the `[Unreleased]` section
2. **Follow /git:gsave workflow**: Use the automated commit workflow which handles version releases
3. **Use conventional commits**: Help the system detect change types
4. **Review before pushing**: Ensure CHANGELOG.md format is correct

### For Release Process
1. **Move to versioned section**: When ready to release, move `[Unreleased]` content to a new version section
2. **Use proper date format**: `YYYY-MM-DD` format required
3. **Semantic versioning**: Follow `MAJOR.MINOR.PATCH` format
4. **Clear descriptions**: Write clear, user-focused change descriptions

## 🔧 Manual Override

If you need to create a release manually or fix automation issues:

```bash
# Create release manually using GitHub CLI
gh release create v2.2.2 --title "v2.2.2 - Manual Release" --notes-file release_notes.md

# Test the release helper script
.github/scripts/release_helper.sh version
.github/scripts/release_helper.sh notes 2.2.1
.github/scripts/release_helper.sh title 2.2.1
```

## 🐛 Troubleshooting

### Common Issues

**Release not created after CHANGELOG.md update:**
- Check that version format is exactly `## [X.Y.Z] - YYYY-MM-DD`
- Verify the version doesn't already exist as a Git tag
- Check GitHub Actions logs for detailed error messages

**Duplicate releases:**
- The system prevents duplicate releases by checking existing Git tags
- If a tag exists, no release will be created

**Malformed release notes:**
- Ensure proper spacing around version headers
- Use standard Keep a Changelog section headers
- Check for special characters that might break parsing

### Debug Commands

```bash
# Check latest version
.github/scripts/release_helper.sh version

# Extract notes for debugging
.github/scripts/release_helper.sh notes 2.2.1

# List existing tags
git tag -l

# Check workflow runs
gh run list --workflow=release.yml
```

## 🚀 Future Enhancements

Potential improvements to consider:
- **Slack/Discord notifications** for new releases
- **Automatic changelog generation** from commit messages
- **Release candidate support** for pre-releases
- **Integration with package managers** (npm, Docker, etc.)
- **Automated security scanning** before release
- **Release approval workflow** for critical versions

## 📚 References

- [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
- [Semantic Versioning](https://semver.org/)
- [GitHub Releases Documentation](https://docs.github.com/en/repositories/releasing-projects-on-github)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)