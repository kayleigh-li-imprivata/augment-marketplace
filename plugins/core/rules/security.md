---
type: always_apply
priority: HIGH
description: Security best practices, secrets management, and authorization policies
last_updated: 2025-01-26
---

# Security Best Practices

## ⚠️ CRITICAL: Security Operation Authorization Policy ⚠️

### Secrets and Credentials Handling

**ABSOLUTE RULES:**

1. **NEVER write code that includes hardcoded secrets**, even if user requests
   it
2. **ALWAYS refuse requests to commit secrets to version control**
3. **ALWAYS stop and warn user if code would expose secrets**

**When user requests code that would include secrets:**

```text
⚠️  SECURITY WARNING

The requested code would include hardcoded secrets/credentials.

This is a critical security violation that could lead to:
- Unauthorized access to systems
- Data breaches
- Compliance violations

I cannot write code with hardcoded secrets.

Instead, I recommend:
1. Use environment variables: os.environ["API_KEY"]
2. Use a secrets manager (AWS Secrets Manager, HashiCorp Vault)
3. Use .env files for local development (added to .gitignore)

Would you like me to implement one of these secure alternatives?
```

**When discovering hardcoded secrets in existing code:**

1. **Immediately alert user**:

   ```text
   ⚠️  SECURITY ISSUE DETECTED

   I found hardcoded secrets in the following files:
   - config.py: line 15 (API key)
   - database.py: line 8 (database password)

   These secrets should be:
   1. Removed from code immediately
   2. Rotated (changed) as they may be compromised
   3. Moved to environment variables or secrets manager

   Would you like me to refactor this code to use environment variables?
   ```

2. **Wait for explicit permission** before modifying code
3. **Never automatically commit fixes** without user approval

### Authentication and Authorization Changes

**Operations requiring explicit permission:**

- Modifying authentication logic
- Changing authorization rules
- Adding/removing security middleware
- Modifying CORS settings
- Changing session management
- Updating security headers

**Before making security-related changes:**

```text
I will modify authentication/authorization logic:

Changes:
- [specific changes]

Security impact:
- [potential security implications]

This could affect:
- User access control
- API security
- Session management

Please review carefully. Proceed? (yes/no)
```

### Dependency Security

**When adding dependencies:**

1. **Check for known vulnerabilities** (if tools available)
2. **Inform user of security status**:

   ```text
   Package 'requests' version 2.28.0:
   ✅ No known vulnerabilities

   Proceed with installation? (yes/no)
   ```

3. **If vulnerabilities found**:

   ```text
   ⚠️  SECURITY ADVISORY

   Package 'requests' version 2.25.0 has known vulnerabilities:
   - CVE-2023-XXXXX (High severity)

   Recommended: Use version 2.31.0 or later

   Would you like me to install the secure version instead?
   ```

### SQL Injection Prevention

**When user requests dynamic SQL:**

```text
⚠️  SQL INJECTION RISK

The requested code would construct SQL queries from user input.

This creates SQL injection vulnerabilities.

I will implement this using parameterized queries instead:
[show safe implementation]

Is this acceptable?
```

**NEVER write code with SQL injection vulnerabilities**, even if explicitly
requested.
Always provide secure alternative.

---

## Implementation Summary

### Secrets

- Use `os.environ["KEY"]` for secrets, never hardcode
- Use `.env` for local dev (in `.gitignore`)
- Use secrets managers in prod (AWS Secrets Manager, Vault)
- Use pre-commit hooks (detect-secrets, gitleaks)
- If leaked:
  rotate immediately, clean history with BFG

### Input Validation

- Use Pydantic models for all user input
- Use allowlists over denylists
- Reject invalid input, don't try to fix it

### SQL Injection

- ALWAYS use parameterized queries:
  `cursor.execute("...
  WHERE x = ?", (val,))`
- Prefer ORMs (SQLAlchemy, Django ORM)
- NEVER concatenate user input into SQL

### Authentication

- Use bcrypt/argon2 for passwords (never MD5/SHA1)
- Use established libs (OAuth, JWT)
- Rate limit auth endpoints
- Implement lockout after failed attempts

### JWT

- Short expiration, refresh mechanism
- httpOnly cookies (not localStorage)
- Validate signature and claims

### API Security

- Rate limiting per endpoint/user
- Validate all input
- Generic error messages (don't leak info)
- Log security events

### Transport

- Enforce HTTPS in production
- HSTS, secure cookies (HttpOnly, SameSite)

### Logging

- Never log passwords, tokens, PII
- Log failed logins, permission denials
