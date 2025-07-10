# Security Policy

## Supported Versions

We actively support the following versions of pg-cel with security updates:

| Version | Supported          |
| ------- | ------------------ |
| 1.4.x   | ✅ Yes             |
| 1.3.x   | ✅ Yes             |
| 1.2.x   | ⚠️ Critical fixes only |
| < 1.2   | ❌ No             |

### PostgreSQL Compatibility

Security updates are provided for pg-cel running on:

- PostgreSQL 14 (14.0 and later)
- PostgreSQL 15 (15.0 and later)  
- PostgreSQL 16 (16.0 and later)
- PostgreSQL 17 (17.0 and later)

## Reporting a Vulnerability

If you discover a security vulnerability in pg-cel, please follow these steps:

### 1. Do NOT open a public issue

Security vulnerabilities should be reported privately to allow for responsible disclosure and coordinated fixes.

### 2. Contact the Security Team

**Primary Method**: Email security@spandigital.com with:
- Subject line: "pg-cel Security Vulnerability Report"
- Description of the vulnerability
- Steps to reproduce
- Potential impact assessment
- Your contact information

**Alternative Method**: If email is not available, you can:
- Create a private vulnerability report via GitHub's security advisory feature
- Contact maintainers directly via other secure channels

### 3. Provide Detailed Information

Include as much information as possible:

```
- pg-cel version affected
- PostgreSQL version and configuration
- Operating system and version
- Detailed description of the vulnerability
- Proof-of-concept or exploit code (if available)
- Potential impact and attack scenarios
- Suggested mitigation or fix (if you have ideas)
```

### 4. Response Timeline

We are committed to responding to security reports promptly:

- **Initial Response**: Within 48 hours of report receipt
- **Vulnerability Assessment**: Within 5 business days
- **Fix Development**: Timeline depends on severity and complexity
- **Coordinated Disclosure**: Typically 90 days after initial report

### 5. Disclosure Process

1. **Private Assessment**: We will privately assess and validate the report
2. **Fix Development**: Develop and test a fix in a private repository
3. **Security Advisory**: Prepare a security advisory draft
4. **Coordinated Release**: Release the fix and public advisory simultaneously
5. **Credit**: Security researchers will be credited (unless they prefer anonymity)

## Security Considerations

### CEL Expression Security

pg-cel evaluates CEL (Common Expression Language) expressions, which are designed to be safe by default. However, consider these security aspects:

#### Safe by Design
- CEL expressions cannot execute arbitrary code
- No file system access
- No network access
- Memory and computation limits built-in

#### Best Practices
- **Input Validation**: Validate CEL expressions before storing in applications
- **Data Sanitization**: Ensure JSON data doesn't contain malicious content
- **Access Control**: Restrict who can submit CEL expressions in your application
- **Audit Logging**: Log CEL expression evaluation in security-sensitive contexts

### Database Security

#### Permissions
- Grant minimal necessary permissions to users executing CEL functions
- Consider creating specific roles for CEL expression evaluation
- Audit user permissions regularly

#### Data Protection
- Sensitive data in JSON inputs should be encrypted at rest
- Consider data masking for non-production environments
- Be aware that CEL expressions and data may be cached in memory

### Build and Deployment Security

#### Dependencies
- Regularly update Go dependencies (monitored via Dependabot)
- Review security advisories for CEL-go library
- Keep PostgreSQL installations up to date

#### Build Security
- Verify integrity of downloaded binaries
- Build from source for maximum security assurance
- Use official release artifacts when possible

## Security Updates

### Notification Channels
Security updates will be communicated through:
- GitHub Security Advisories
- Release notes with security labels
- Email notifications to registered users (if available)

### Update Recommendations
- **Critical**: Update immediately
- **High**: Update within 1 week
- **Medium**: Update within 30 days
- **Low**: Update with next planned maintenance

## Scope

This security policy applies to:
- The pg-cel PostgreSQL extension itself
- Official build scripts and tooling
- Official documentation and examples
- Dependencies and third-party libraries we include

### Out of Scope
- Third-party applications using pg-cel
- Custom CEL expressions written by users
- Infrastructure running pg-cel (unless directly related to pg-cel vulnerabilities)
- General PostgreSQL security (use PostgreSQL's security channels)

## Contact Information

**Security Team**: security@spandigital.com
**Public Issues**: GitHub Issues (for non-security bugs only)
**General Questions**: GitHub Discussions

## Acknowledgments

We appreciate security researchers and users who help keep pg-cel secure. Contributors to security improvements will be acknowledged in:
- Security advisories
- Release notes  
- Hall of fame (if we establish one)

---

**Note**: This security policy may be updated from time to time. Please check back periodically for changes.
