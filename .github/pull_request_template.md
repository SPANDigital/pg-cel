# Pull Request

## Description

<!-- Provide a brief summary of your changes -->

## Type of Change

<!-- Please check the type of change your PR introduces -->

- [ ] 🐛 Bug fix (non-breaking change which fixes an issue)
- [ ] ✨ New feature (non-breaking change which adds functionality)
- [ ] 💥 Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] 📚 Documentation update
- [ ] 🔧 Build/CI changes
- [ ] 🧹 Code cleanup/refactoring
- [ ] ⚡ Performance improvement
- [ ] 🧪 Test improvements

## Related Issues

<!-- Link any related issues -->
Fixes #<!-- issue number -->
Relates to #<!-- issue number -->

## Changes Made

<!-- Describe the changes in detail -->

### Core Changes
- 
- 
- 

### Files Modified
- `main.go`: 
- `pg_wrapper.c`: 
- `pg_cel--*.sql`: 
- Other: 

## Testing

<!-- Describe how you tested your changes -->

### Test Environment
- [ ] PostgreSQL 14
- [ ] PostgreSQL 15
- [ ] PostgreSQL 16
- [ ] PostgreSQL 17
- [ ] Linux
- [ ] macOS
- [ ] Windows (WSL)

### Test Cases
- [ ] Unit tests pass (`./build.sh test`)
- [ ] Integration tests pass
- [ ] Performance tests (if applicable)
- [ ] Manual testing completed

### Test Results
```sql
-- Include any relevant test SQL or results
```

## CEL Expression Examples

<!-- If your changes affect CEL functionality, provide examples -->

```sql
-- Before (if applicable)
SELECT cel_eval('old_expression', '{"data": "value"}');

-- After
SELECT cel_eval('new_expression', '{"data": "value"}');
```

## Performance Impact

<!-- Describe any performance implications -->

- [ ] No performance impact
- [ ] Performance improvement (describe)
- [ ] Potential performance impact (describe and justify)
- [ ] Benchmarking completed (attach results)

## Breaking Changes

<!-- If this is a breaking change, describe the impact -->

- [ ] No breaking changes
- [ ] Breaking changes (describe migration path)

### Migration Guide
<!-- If breaking changes, provide migration instructions -->

## Documentation

<!-- Check all that apply -->

- [ ] README.md updated
- [ ] EXAMPLES.md updated  
- [ ] INSTALL.md updated
- [ ] TROUBLESHOOTING.md updated
- [ ] Code comments added/updated
- [ ] SQL function documentation updated

## Checklist

<!-- Please check off completed items -->

### Code Quality
- [ ] Code follows project style guidelines
- [ ] Self-review of the code completed
- [ ] Code is properly commented
- [ ] Go code uses `any` instead of `interface{}`
- [ ] Error handling is appropriate
- [ ] Memory management is correct (CGO)

### Building & Testing
- [ ] `./build.sh` completes successfully
- [ ] `./build.sh test` passes
- [ ] `go mod tidy` executed
- [ ] All CI checks pass
- [ ] Cross-platform compatibility verified

### Version Management
- [ ] Version bumped if necessary (`./manage_version.sh`)
- [ ] Upgrade SQL scripts created (if needed)
- [ ] CHANGELOG entry added (if applicable)

### Security
- [ ] No sensitive information exposed
- [ ] No security vulnerabilities introduced
- [ ] Dependencies are secure and up-to-date

## Additional Notes

<!-- Any additional information for reviewers -->

## Reviewer Guidance

<!-- Help reviewers focus on important areas -->

### Areas to Focus On
- 
- 
- 

### Questions for Reviewers
- 
- 
- 

---

<!-- 
Thank you for contributing to pg-cel! 
Please ensure all checks pass before requesting review.
-->
