# Security Guide for ISXJQB Backend

## ⚠️ CRITICAL: Database Credentials

Your database connection string contains **sensitive credentials**. Follow these steps:

### 1. Move Credentials to Environment Variables

**NEVER hardcode credentials in PHP files!**

Create `.env` file (NOT committed to git):
```bash
DATABASE_URL=postgresql://neondb_owner:npg_oRK2HX8tzqrW@ep-aged-surf-a5kyar58.us-east-2.aws.neon.tech/neondb?sslmode=require
```

Update `api/verify_license.php`:
```php
// Load from environment
$dbUrl = getenv('DATABASE_URL');

if (!$dbUrl) {
    error_log('DATABASE_URL not set!');
    http_response_code(500);
    echo json_encode(['error' => 'Configuration error']);
    exit();
}
```

### 2. Set Environment Variables on Server

**Apache (.htaccess)**:
```apache
SetEnv DATABASE_URL "postgresql://user:pass@host/db?sslmode=require"
```

**Nginx + PHP-FPM** (`/etc/php/fpm/pool.d/www.conf`):
```ini
env[DATABASE_URL] = postgresql://user:pass@host/db?sslmode=require
```

**Docker**:
```yaml
environment:
  - DATABASE_URL=postgresql://user:pass@host/db?sslmode=require
```

**Systemd** (`/etc/systemd/system/php-fpm.service.d/override.conf`):
```ini
[Service]
Environment="DATABASE_URL=postgresql://user:pass@host/db?sslmode=require"
```

### 3. Rotate Credentials

If credentials were exposed:

1. **Reset Neon database password** immediately:
   - Go to Neon dashboard
   - Navigate to your project
   - Reset password
   - Update `.env` file

2. **Revoke compromised API access**:
   - Change all affected credentials
   - Review audit logs for suspicious activity

### 4. Production Security Checklist

- [ ] **HTTPS ONLY** - Never use HTTP for API
- [ ] **Environment variables** - No hardcoded credentials
- [ ] **Rate limiting** - Max 10 requests/minute per IP
- [ ] **Audit logging** - Track all verification attempts
- [ ] **IP whitelisting** (optional) - Restrict to known IPs
- [ ] **SQL injection protection** - Use prepared statements (already done)
- [ ] **XSS protection** - Sanitize inputs (already done)
- [ ] **CORS** - Restrict origins in production
- [ ] **Error handling** - Don't leak internal details
- [ ] **Monitoring** - Alert on suspicious patterns

### 5. Access Control

#### Database User Permissions

Create a restricted database user for the API:

```sql
-- Create read-only user for API
CREATE USER api_user WITH PASSWORD 'secure_password';

-- Grant only necessary permissions
GRANT SELECT, UPDATE ON licenses TO api_user;
GRANT INSERT ON license_audit_log TO api_user;

-- Revoke dangerous permissions
REVOKE CREATE, DROP, DELETE ON ALL TABLES IN SCHEMA public FROM api_user;
```

#### File Permissions

```bash
# API files: read-only
chmod 644 api/verify_license.php

# .env file: owner read-only
chmod 600 .env

# Directories: no write
chmod 755 api/
```

### 6. Monitoring & Alerts

#### Failed Authentication Attempts

```sql
-- Alert if > 20 failed attempts in 5 minutes
SELECT
    email,
    COUNT(*) as failures,
    array_agg(DISTINCT ip_address) as ips
FROM license_audit_log
WHERE success = FALSE
  AND attempted_at > NOW() - INTERVAL '5 minutes'
GROUP BY email
HAVING COUNT(*) > 20;
```

#### Unusual Activity Patterns

```sql
-- Same license used from multiple IPs quickly
SELECT
    email,
    license_key,
    COUNT(DISTINCT ip_address) as unique_ips,
    COUNT(*) as total_uses
FROM license_audit_log
WHERE attempted_at > NOW() - INTERVAL '1 hour'
  AND success = TRUE
GROUP BY email, license_key
HAVING COUNT(DISTINCT ip_address) > 3;
```

### 7. Backup Strategy

#### Automated Backups

Neon provides automatic backups, but also:

```bash
# Manual backup (run daily via cron)
pg_dump "postgresql://user:pass@host/db" > backup_$(date +%Y%m%d).sql

# Encrypt backup
gpg --encrypt --recipient admin@yoursite.com backup_*.sql

# Upload to secure storage
aws s3 cp backup_*.sql.gpg s3://your-backups/
```

#### Backup License Data

```sql
-- Export active licenses (encrypted)
COPY (
    SELECT email, license_key, expires_at, features
    FROM licenses
    WHERE active = TRUE
) TO '/secure/path/licenses_backup.csv' WITH CSV HEADER;
```

### 8. Incident Response

If database is compromised:

1. **Immediately**:
   - Disable API endpoint
   - Rotate all credentials
   - Review audit logs

2. **Investigation**:
   - Check `license_audit_log` for unusual patterns
   - Identify affected licenses
   - Determine attack vector

3. **Recovery**:
   - Restore from backup if needed
   - Notify affected users
   - Implement additional security measures

4. **Prevention**:
   - Review and strengthen security
   - Update documentation
   - Conduct security audit

### 9. Secure Deployment

#### Don't Commit Secrets

```bash
# Check for secrets before commit
git diff --staged | grep -i "password\|secret\|key"

# Use git-secrets to prevent accidents
git secrets --scan
```

#### Review Before Deployment

```bash
# Check for hardcoded credentials
grep -r "postgresql://" --include="*.php"
grep -r "password" --include="*.php"

# Should only be in .env (not tracked by git)
```

### 10. Emergency Contacts

If security incident occurs:

- **Database Admin**: [Your contact]
- **Security Team**: [Your contact]
- **Neon Support**: support@neon.tech

## Current Risk Assessment

🔴 **HIGH RISK**: Database credentials in `verify_license.php`
- **Action**: Move to environment variables immediately
- **Timeline**: Before production deployment

🟡 **MEDIUM RISK**: No rate limiting
- **Action**: Implement rate limiting
- **Timeline**: Before public release

🟢 **LOW RISK**: Prepared statements used
- **Status**: Protected against SQL injection

## Next Steps

1. ✅ Created backend API
2. ⏹️ Move credentials to environment variables
3. ⏹️ Deploy to secure HTTPS server
4. ⏹️ Enable rate limiting
5. ⏹️ Set up monitoring alerts
6. ⏹️ Test with production database
7. ⏹️ Integrate with C++ client

---

**Remember**: Security is an ongoing process, not a one-time setup!
