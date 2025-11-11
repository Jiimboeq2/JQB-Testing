# ISXJQB Backend API

License verification backend for ISXJQB extension.

## Database Setup

### 1. Connect to Your Neon Database

Your PostgreSQL database is already provisioned at Neon.

**Connection details** (stored securely in environment variables):
- Host: `ep-aged-surf-a5kyar58.us-east-2.aws.neon.tech`
- Database: `neondb`
- SSL: Required

### 2. Initialize Database Schema

Connect to your database and run:

```bash
psql "postgresql://neondb_owner:npg_Xedr6xVanI5h@ep-sweet-king-ah50tgzg.c-3.us-east-1.aws.neon.tech/neondb?sslmode=require" < database/schema.sql
```

Or using a PostgreSQL client:
- Copy contents of `database/schema.sql`
- Execute in your Neon dashboard SQL editor

This creates:
- `licenses` table - Stores license keys
- `license_audit_log` table - Tracks verification attempts
- `paypal_transactions` table - Links PayPal purchases (optional)
- Helper functions for license management

### 3. Deploy API

Upload `api/verify_license.php` to your web server.

**Recommended structure**:
```
/var/www/html/
├── api/
│   └── verify_license.php
└── .env (for database credentials)
```

**Environment Variables** (production):
```bash
export DATABASE_URL="postgresql://neondb_owner:npg_Xedr6xVanI5h@ep-sweet-king-ah50tgzg.c-3.us-east-1.aws.neon.tech/neondb?sslmode=require"
```

## API Endpoint

### Verify License

**Endpoint**: `POST /api/verify_license.php`

**Request**:
```json
{
    "email": "user@example.com",
    "license": "66B0-00B8-558A-5B6A-7B91-246E-9E98-B5DC"
}
```

**Success Response** (200):
```json
{
    "valid": true,
    "message": "License verified",
    "expires": "2025-12-31",
    "features": ["basic", "premium"],
    "use_count": 42
}
```

**Error Responses**:

Invalid credentials (401):
```json
{
    "valid": false,
    "message": "Invalid credentials"
}
```

Expired license (401):
```json
{
    "valid": false,
    "message": "License expired",
    "expires": "2024-12-31"
}
```

Deactivated (401):
```json
{
    "valid": false,
    "message": "License deactivated"
}
```

## License Management

### Create New License

```sql
SELECT * FROM create_license(
    'customer@example.com',          -- Email
    '2025-12-31',                    -- Expiration date
    '["basic", "premium"]'::jsonb    -- Features
);
```

Returns:
```
license_key                          | email              | expires_at
------------------------------------|--------------------|-----------
66B0-00B8-558A-5B6A-7B91-246E-9E98-B5DC | customer@example.com | 2025-12-31
```

### Extend Existing License

```sql
SELECT extend_license(
    '66B0-00B8-558A-5B6A-7B91-246E-9E98-B5DC',  -- License key
    30                                           -- Days to add
);
```

### Deactivate License

```sql
UPDATE licenses
SET active = FALSE
WHERE license_key = '66B0-00B8-558A-5B6A-7B91-246E-9E98-B5DC';
```

### View Active Licenses

```sql
SELECT * FROM active_licenses;
```

### View Statistics

```sql
SELECT * FROM license_stats;
```

## Security Best Practices

### 1. Environment Variables

**NEVER hardcode database credentials in code!**

Use environment variables:

```php
// .env file (NEVER commit this!)
DATABASE_URL=postgresql://user:pass@host/db

// In PHP
$dbUrl = getenv('DATABASE_URL');
```

### 2. HTTPS Only

**Always use HTTPS** for API endpoints:
- Protects credentials in transit
- Prevents man-in-the-middle attacks
- Required for production

### 3. Rate Limiting

Add rate limiting to prevent brute force:

```php
// Example: Redis-based rate limiting
$redis = new Redis();
$redis->connect('localhost', 6379);

$key = 'ratelimit:' . $_SERVER['REMOTE_ADDR'];
$requests = $redis->incr($key);

if ($requests === 1) {
    $redis->expire($key, 60); // 1 minute window
}

if ($requests > 10) { // Max 10 requests per minute
    http_response_code(429);
    echo json_encode(['error' => 'Too many requests']);
    exit();
}
```

### 4. Audit Logging

Log all verification attempts:

```php
// In verify_license.php, add after verification
$auditStmt = $pdo->prepare('
    INSERT INTO license_audit_log (email, license_key, success, ip_address, user_agent, response_message)
    VALUES (:email, :license, :success, :ip, :ua, :message)
');

$auditStmt->execute([
    'email' => $email,
    'license' => $license,
    'success' => $valid,
    'ip' => $_SERVER['REMOTE_ADDR'],
    'ua' => $_SERVER['HTTP_USER_AGENT'] ?? '',
    'message' => $responseMessage
]);
```

### 5. IP Whitelisting (Optional)

For extra security, whitelist InnerSpace IP ranges:

```php
$allowedIPs = ['1.2.3.4', '5.6.7.8']; // Your users' IPs

if (!in_array($_SERVER['REMOTE_ADDR'], $allowedIPs)) {
    http_response_code(403);
    echo json_encode(['error' => 'Access denied']);
    exit();
}
```

## Integration with ISXJQB

### Update Auth.h

Replace the TODO in `Auth.h` line 77:

```cpp
static bool VerifyLicense()
{
    if (PayPalEmail.empty() || LicenseKey.empty())
    {
        printf("\\ar[ISXJQB Auth] No credentials loaded");
        return false;
    }

    printf("\\ay[ISXJQB Auth] Verifying license...");

    // Build JSON request
    std::string json = "{\"email\":\"" + PayPalEmail + "\",\"license\":\"" + LicenseKey + "\"}";

    // Make HTTP request
    std::string url = "https://your-domain.com/api/verify_license.php";

    // TODO: Implement HTTP POST and parse JSON response
    // You'll need to:
    // 1. Use EzHttpRequest or implement HTTP client
    // 2. Parse JSON response
    // 3. Check "valid" field
    // 4. Update IsAuthenticated based on result

    // For now, placeholder
    IsAuthenticated = false; // Change to true only if API returns valid=true

    return IsAuthenticated;
}
```

### Example HTTP Request (C++)

You'll need to implement a proper HTTP client. Here's a basic WinHTTP example:

```cpp
#include <winhttp.h>
#pragma comment(lib, "winhttp.lib")

std::string HttpPost(const std::string& url, const std::string& data)
{
    // Parse URL
    // Create session
    // Open connection
    // Send POST request
    // Read response
    // Parse JSON

    // Return response body
}
```

Or use a library like `cpp-httplib` or `cURL`.

## Monitoring

### Check Recent Activity

```sql
SELECT
    email,
    success,
    COUNT(*) as attempts,
    MAX(attempted_at) as last_attempt
FROM license_audit_log
WHERE attempted_at > NOW() - INTERVAL '24 hours'
GROUP BY email, success
ORDER BY last_attempt DESC;
```

### Detect Suspicious Activity

```sql
-- Multiple failed attempts from same email
SELECT
    email,
    COUNT(*) as failed_attempts,
    array_agg(DISTINCT ip_address) as ip_addresses
FROM license_audit_log
WHERE success = FALSE
AND attempted_at > NOW() - INTERVAL '1 hour'
GROUP BY email
HAVING COUNT(*) > 5
ORDER BY failed_attempts DESC;
```

### Most Active Users

```sql
SELECT
    email,
    license_key,
    use_count,
    last_used_at
FROM licenses
WHERE active = TRUE
ORDER BY use_count DESC
LIMIT 10;
```

## Troubleshooting

### Database Connection Failed

Check:
1. Neon database is running
2. Connection string is correct
3. SSL is enabled
4. Firewall allows connections

### License Not Found

Check:
1. Email matches exactly (case-sensitive)
2. License key format is correct (XXXX-XXXX-...)
3. License exists in database

### Always Returns Invalid

Check:
1. Database connection works
2. SQL query executes
3. `active` flag is TRUE
4. `expires_at` is in future
5. API logs for errors

## Production Checklist

- [ ] Database schema deployed
- [ ] API endpoint configured
- [ ] HTTPS enabled
- [ ] Environment variables set
- [ ] Rate limiting implemented
- [ ] Audit logging enabled
- [ ] Test license created
- [ ] Client integration tested
- [ ] Monitoring set up
- [ ] Backup strategy in place

## Support

For issues:
1. Check API logs
2. Check database audit log
3. Verify network connectivity
4. Test with curl:

```bash
curl -X POST https://your-domain.com/api/verify_license.php \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","license":"66B0-00B8-558A-5B6A-7B91-246E-9E98-B5DC"}'
```

---

**Database**: Neon PostgreSQL
**API**: PHP 7.4+
**Client**: ISXJQB C++ Extension
