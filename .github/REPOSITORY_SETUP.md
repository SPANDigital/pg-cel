# GitHub Repository Configuration

This document provides recommended GitHub repository settings for optimal governance and community engagement.

## Repository Settings

### General
- **Visibility**: Public (for open source)
- **Template Repository**: Disabled
- **Issues**: ✅ Enabled
- **Projects**: ✅ Enabled (for project management)
- **Wiki**: Enabled (optional)
- **Discussions**: ✅ Enabled (for community engagement)
- **Sponsorships**: Consider enabling if accepting donations

### Features

#### Issues
- **Issues**: ✅ Enabled
- **Labels**: Use the default labels plus custom ones:
  - `bug` - Something isn't working
  - `enhancement` - New feature or request
  - `question` - Further information is requested
  - `needs-triage` - Needs initial review
  - `good first issue` - Good for newcomers
  - `help wanted` - Extra attention is needed
  - `postgresql-14`, `postgresql-15`, `postgresql-16`, `postgresql-17` - Version-specific issues
  - `linux`, `macos`, `windows` - Platform-specific issues
  - `performance` - Performance-related issues
  - `documentation` - Documentation improvements
  - `build` - Build system issues

#### Pull Requests
- **Allow merge commits**: ✅ Enabled
- **Allow squash merging**: ✅ Enabled (recommended for clean history)
- **Allow rebase merging**: ✅ Enabled
- **Always suggest updating pull request branches**: ✅ Enabled
- **Automatically delete head branches**: ✅ Enabled

#### Discussions
- **Discussions**: ✅ Enabled
- **Categories**:
  - 📢 Announcements (Announcement format)
  - 💭 General (Discussion format)
  - 💡 Ideas (Discussion format) 
  - 🙋 Q&A (Q&A format)
  - 🏆 Show and tell (Discussion format)

## Branch Protection Rules

### Main Branch (`main`)
- **Require a pull request before merging**: ✅ Enabled
  - **Require approvals**: 1 (minimum)
  - **Dismiss stale pull request approvals**: ✅ Enabled
  - **Require review from code owners**: ✅ Enabled
- **Require status checks to pass**: ✅ Enabled
  - **Require branches to be up to date**: ✅ Enabled
  - **Status checks**: All CI workflow checks
- **Require conversation resolution**: ✅ Enabled
- **Require signed commits**: Consider enabling for security
- **Require linear history**: Consider enabling for clean history
- **Include administrators**: ✅ Enabled (applies rules to admins too)
- **Allow force pushes**: ❌ Disabled
- **Allow deletions**: ❌ Disabled

## Security Settings

### Code Security and Analysis
- **Dependency graph**: ✅ Enabled
- **Dependabot alerts**: ✅ Enabled
- **Dependabot security updates**: ✅ Enabled
- **Code scanning**: Consider enabling (GitHub CodeQL)
- **Secret scanning**: ✅ Enabled (for public repos)
- **Secret scanning push protection**: ✅ Enabled

### Dependabot Configuration
See `.github/dependabot.yml` for Go module and GitHub Actions dependencies monitoring.

## Actions Settings

### General
- **Actions permissions**: Allow enterprise, and select non-enterprise, actions and reusable workflows
- **Fork pull request workflows**: Require approval for first-time contributors
- **Fork pull request workflows in private repositories**: Send secrets to workflows

### Workflow Permissions
- **Default workflow permissions**: Read repository contents and package permissions
- **Allow GitHub Actions to create and approve pull requests**: ❌ Disabled (security)

## Pages Settings (if using GitHub Pages)
- **Source**: Deploy from a branch
- **Branch**: `main` / `docs` (if documentation site)
- **Custom domain**: Configure if available

## Community Standards Checklist

### Required Files
- ✅ `README.md` - Project overview and quick start
- ✅ `LICENSE` - MIT License
- ✅ `CONTRIBUTING.md` - Contribution guidelines
- ✅ `.github/CODEOWNERS` - Code ownership rules
- ✅ `.github/pull_request_template.md` - PR template
- ✅ `.github/ISSUE_TEMPLATE/` - Issue templates
- ✅ `.github/DISCUSSION_TEMPLATE/` - Discussion templates

### Recommended Files
- ✅ `INSTALL.md` - Detailed installation instructions
- ✅ `EXAMPLES.md` - Usage examples
- ✅ `TROUBLESHOOTING.md` - Common issues and solutions
- ✅ `VERSIONING.md` - Versioning strategy
- ❌ `CODE_OF_CONDUCT.md` - Consider adding
- ❌ `SECURITY.md` - Security policy (consider adding)
- ❌ `SUPPORT.md` - Support resources (consider adding)

## Notifications Configuration

### For Maintainers
- **Watch**: All activity (issues, PRs, discussions)
- **Releases**: Releases only
- **Custom**: Configure based on preferences

### Email Notifications
Configure team notification preferences for:
- New issues and PRs
- Review requests
- Failed workflow runs
- Security alerts

## Repository Topics/Tags
Add relevant topics to help discovery:
- `postgresql`
- `cel`
- `common-expression-language`
- `postgres-extension`
- `sql`
- `database`
- `caching`
- `go`
- `c`
- `postgresql-14`
- `postgresql-15`
- `postgresql-16`
- `postgresql-17`

## Team Configuration

### Required Teams
- `@SPANDigital/pg-cel-maintainers` - Core maintainers with admin access
- Consider: `@SPANDigital/pg-cel-contributors` - Regular contributors with write access

### Permissions
- **Maintainers**: Admin (full access)
- **Contributors**: Write (push, review, merge PRs)
- **Community**: Read (clone, open issues, fork)

## Automation Recommendations

### GitHub Apps (Optional)
- **Semantic Pull Requests**: Enforce conventional commit format
- **WIP**: Prevent merging of work-in-progress PRs
- **ImgBot**: Optimize images automatically
- **Renovate**: Advanced dependency management (alternative to Dependabot)

### Custom Workflows
Current workflows:
- ✅ CI testing across PostgreSQL versions and platforms
- ✅ Automated releases with artifact generation
- Consider: Issue/PR labeling automation
- Consider: Stale issue/PR management

---

**Note**: Some settings require repository admin access to configure. Work with repository administrators to implement these recommendations.
