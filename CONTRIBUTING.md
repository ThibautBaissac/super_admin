# Contributing to SuperAdmin

Thank you for your interest in contributing to SuperAdmin! This document provides guidelines and instructions for contributing.

## Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Help create a welcoming environment for all contributors

## Ways to Contribute

### 🐛 Reporting Bugs

Before creating a bug report:
1. Search existing issues to avoid duplicates
2. Update to the latest version to see if the issue persists

When reporting a bug, include:
- Ruby version (`ruby -v`)
- Rails version (`rails -v`)
- SuperAdmin version
- Steps to reproduce
- Expected vs. actual behavior
- Relevant logs or error messages

### 💡 Suggesting Features

Feature requests are welcome! Please:
1. Check existing issues/discussions first
2. Clearly describe the use case
3. Explain why this would benefit the community
4. Consider if it fits SuperAdmin's scope

### 📝 Improving Documentation

Documentation improvements are always appreciated:
- Fix typos or unclear sections
- Add examples
- Improve YARD comments in code
- Update guides

### 🔧 Code Contributions

## Development Setup

### 1. Fork and Clone

```bash
git fork https://github.com/ThibautBaissac/super_admin
git clone https://github.com/YOUR_USERNAME/super_admin.git
cd super_admin
```

### 2. Install Dependencies

```bash
bundle install
```

### 3. Run Tests

```bash
# Run all tests
bundle exec rake test

# Run specific test file
bundle exec rake test TEST=test/models/super_admin/audit_log_test.rb

# Run with coverage
bundle exec rake test
# Coverage report in coverage/index.html
```

### 4. Run Linting

```bash
# Check code style
bundle exec rubocop

# Auto-fix issues
bundle exec rubocop -a
```

### 5. Test in Dummy App

The dummy app is in `test/dummy/`:

```bash
cd test/dummy
rails server
# Visit http://localhost:3000/super_admin
```

## Making Changes

### Branch Naming

Use descriptive branch names:
- `fix/issue-description` (bug fixes)
- `feat/feature-description` (new features)
- `docs/what-changed` (documentation)
- `refactor/what-refactored` (refactoring)

### Commit Messages

Follow conventional commits format:

```
type(scope): short description

Longer description if needed.

Fixes #123
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `refactor`: Code refactoring
- `test`: Adding/updating tests
- `chore`: Maintenance tasks

**Examples:**
```
feat(exports): add JSON export support

fix(search): handle special characters in queries

docs(readme): update installation instructions

test(controllers): add tests for ResourcesController
```

### Code Style

- Follow [Ruby Style Guide](https://rubystyle.guide/)
- Use Rubocop (extends `rubocop-rails-omakase`)
- Add YARD comments for public methods:

```ruby
# Retrieves dashboard for given model class
#
# @param model_class [Class] ActiveRecord model class
# @return [Class, nil] Dashboard class or nil if not found
# @example
#   DashboardRegistry.instance.dashboard_for(User)
#   #=> SuperAdmin::UserDashboard
def dashboard_for(model_class)
  # ...
end
```

### Testing

**All code contributions must include tests.**

- Test new features thoroughly
- Add regression tests for bug fixes
- Maintain or improve code coverage (minimum 80%)
- Test edge cases

Test structure:
```ruby
require "test_helper"

module SuperAdmin
  class MyFeatureTest < ActiveSupport::TestCase
    setup do
      # Setup code
    end

    test "descriptive test name" do
      # Test implementation
      assert_equal expected, actual
    end
  end
end
```

### Performance Considerations

SuperAdmin emphasizes performance:
- Avoid N+1 queries (use `includes`, `preload`, or `eager_load`)
- Test with realistic data volumes
- Profile changes if touching query code
- See [PERFORMANCE.md](PERFORMANCE.md) for guidelines

### Security Considerations

Security is critical:
- Never use string interpolation in SQL queries (use Arel)
- Validate and sanitize user input
- Follow principle of least privilege
- See [SECURITY.md](SECURITY.md) for detailed guidelines

## Pull Request Process

### 1. Before Opening PR

- [ ] Tests pass: `bundle exec rake test`
- [ ] Linting passes: `bundle exec rubocop`
- [ ] Documentation updated (if needed)
- [ ] CHANGELOG.md updated (under `[Unreleased]`)
- [ ] No merge conflicts with `main`

### 2. Opening the PR

**PR Title:** Use conventional commit format
```
feat(exports): add JSON export support
```

**PR Description:** Include:
- What changed and why
- Related issue number (`Fixes #123`, `Closes #456`)
- Screenshots (for UI changes)
- Breaking changes (if any)
- Migration required (if adding/changing DB schema)

**Draft PRs:** Use draft PRs for work-in-progress to get early feedback.

### 3. Review Process

- Maintainers will review your PR
- Address feedback by pushing new commits
- Don't force-push after review starts (makes review harder)
- Maintainer will squash/merge when approved

### 4. After Merge

- Your contribution will be included in next release
- You'll be credited in release notes
- Thank you! 🎉

## Architecture Overview

See [CLAUDE.md](CLAUDE.md) for detailed architecture documentation:

- **Dashboard-Based Discovery**: Models need dashboards to appear
- **Dynamic Resource Controller**: Single controller handles all resources
- **Query Object Pattern**: Search/filter/sort delegation
- **Form Field System**: Automatic form generation
- **Service Objects**: Business logic extraction

## Questions?

- Open a [Discussion](https://github.com/ThibautBaissac/super_admin/discussions) for questions
- Check [existing issues](https://github.com/ThibautBaissac/super_admin/issues)
- Read the [documentation](README.md)

## Recognition

Contributors will be:
- Listed in release notes
- Credited in commit history
- Mentioned in README (for significant contributions)

Thank you for contributing to SuperAdmin! 🚀
