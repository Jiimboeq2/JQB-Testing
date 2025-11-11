<?php
/**
 * ISXJQB License Verification API
 *
 * Endpoint: POST /api/verify_license.php
 *
 * Request Body (JSON):
 * {
 *     "email": "user@example.com",
 *     "license": "66B0-00B8-558A-5B6A-7B91-246E-9E98-B5DC"
 * }
 *
 * Response (JSON):
 * {
 *     "valid": true,
 *     "message": "License verified",
 *     "tier": "god|oracle|acolyte",
 *     "max_characters": 999,
 *     "permissions": ["unlimited_characters", "all_features", ...],
 *     "expires": "2025-12-31",
 *     "days_remaining": 120,
 *     "features": ["basic", "premium", "vip"],
 *     "use_count": 42
 * }
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

// Handle preflight
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Only accept POST
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['error' => 'Method not allowed']);
    exit();
}

// Get request body
$input = file_get_contents('php://input');
$data = json_decode($input, true);

if (!$data || !isset($data['email']) || !isset($data['license'])) {
    http_response_code(400);
    echo json_encode([
        'valid' => false,
        'error' => 'Missing email or license key'
    ]);
    exit();
}

$email = filter_var($data['email'], FILTER_SANITIZE_EMAIL);
$license = preg_replace('/[^A-Z0-9\-]/', '', strtoupper($data['license']));

// Validate format
if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    http_response_code(400);
    echo json_encode([
        'valid' => false,
        'error' => 'Invalid email format'
    ]);
    exit();
}

// Validate license format (XXXX-XXXX-XXXX-XXXX-XXXX-XXXX-XXXX-XXXX)
if (!preg_match('/^[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$/', $license)) {
    http_response_code(400);
    echo json_encode([
        'valid' => false,
        'error' => 'Invalid license key format'
    ]);
    exit();
}

// Database connection (USE ENVIRONMENT VARIABLES IN PRODUCTION!)
try {
    // Get from environment variable (more secure)
    $dbUrl = getenv('DATABASE_URL') ?: 'postgresql://neondb_owner:npg_Xedr6xVanI5h@ep-sweet-king-ah50tgzg.c-3.us-east-1.aws.neon.tech/neondb?sslmode=require';

    $parts = parse_url($dbUrl);
    $host = $parts['host'];
    $port = $parts['port'] ?? 5432;
    $dbname = ltrim($parts['path'], '/');
    $user = $parts['user'];
    $password = $parts['pass'];

    // Connect to PostgreSQL
    $dsn = "pgsql:host=$host;port=$port;dbname=$dbname;sslmode=require";
    $pdo = new PDO($dsn, $user, $password, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES => false
    ]);

} catch (PDOException $e) {
    error_log('Database connection failed: ' . $e->getMessage());
    http_response_code(500);
    echo json_encode([
        'valid' => false,
        'error' => 'Database connection failed'
    ]);
    exit();
}

try {
    // Query license
    $stmt = $pdo->prepare('
        SELECT
            id,
            email,
            license_key,
            active,
            tier,
            max_characters,
            expires_at,
            features,
            last_used_at,
            use_count
        FROM licenses
        WHERE email = :email
        AND license_key = :license
        LIMIT 1
    ');

    $stmt->execute([
        'email' => $email,
        'license' => $license
    ]);

    $row = $stmt->fetch();

    if (!$row) {
        // License not found - log attempt
        logAuditAttempt($pdo, $email, $license, false, null, 'Invalid credentials');

        http_response_code(401);
        echo json_encode([
            'valid' => false,
            'message' => 'Invalid credentials'
        ]);
        exit();
    }

    // Check if active
    if (!$row['active']) {
        logAuditAttempt($pdo, $email, $license, false, $row['tier'], 'License deactivated');

        http_response_code(401);
        echo json_encode([
            'valid' => false,
            'message' => 'License deactivated'
        ]);
        exit();
    }

    // Check expiration
    $expiresAt = new DateTime($row['expires_at']);
    $now = new DateTime();

    if ($expiresAt < $now) {
        logAuditAttempt($pdo, $email, $license, false, $row['tier'], 'License expired');

        http_response_code(401);
        echo json_encode([
            'valid' => false,
            'message' => 'License expired',
            'expires' => $expiresAt->format('Y-m-d')
        ]);
        exit();
    }

    // Update last used timestamp and usage count
    $updateStmt = $pdo->prepare('
        UPDATE licenses
        SET last_used_at = NOW(),
            use_count = use_count + 1
        WHERE id = :id
    ');
    $updateStmt->execute(['id' => $row['id']]);

    // Parse features JSON
    $features = json_decode($row['features'], true) ?: ['basic'];

    // Determine permissions based on tier
    $permissions = [];
    switch ($row['tier']) {
        case 'god':
            $permissions = [
                'unlimited_characters',
                'all_features',
                'priority_support',
                'beta_access',
                'custom_scripts',
                'api_access'
            ];
            break;
        case 'oracle':
            $permissions = [
                'multi_character',     // Up to max_characters
                'premium_features',
                'priority_support',
                'advanced_automation'
            ];
            break;
        case 'acolyte':
            $permissions = [
                'single_character',    // 1 character only
                'basic_features',
                'standard_support'
            ];
            break;
    }

    // Calculate days remaining
    $daysRemaining = $now->diff($expiresAt)->days;

    // Valid license!
    $response = [
        'valid' => true,
        'message' => 'License verified',
        'tier' => $row['tier'],
        'max_characters' => (int)$row['max_characters'],
        'permissions' => $permissions,
        'expires' => $expiresAt->format('Y-m-d'),
        'days_remaining' => $daysRemaining,
        'features' => $features,
        'use_count' => (int)$row['use_count'] + 1
    ];

    // Log successful verification
    logAuditAttempt($pdo, $email, $license, true, $row['tier'], 'License verified');

    http_response_code(200);
    echo json_encode($response);

} catch (PDOException $e) {
    error_log('Database query failed: ' . $e->getMessage());
    http_response_code(500);
    echo json_encode([
        'valid' => false,
        'error' => 'Verification failed'
    ]);
}

/**
 * Log verification attempt to audit table
 */
function logAuditAttempt($pdo, $email, $license, $success, $tier, $message)
{
    try {
        $stmt = $pdo->prepare('
            INSERT INTO license_audit_log (email, license_key, success, tier, ip_address, user_agent, response_message)
            VALUES (:email, :license, :success, :tier, :ip, :ua, :message)
        ');

        $stmt->execute([
            'email' => $email,
            'license' => $license,
            'success' => $success ? 'true' : 'false',
            'tier' => $tier,
            'ip' => $_SERVER['REMOTE_ADDR'] ?? null,
            'ua' => $_SERVER['HTTP_USER_AGENT'] ?? null,
            'message' => $message
        ]);
    } catch (PDOException $e) {
        error_log('Audit log failed: ' . $e->getMessage());
    }
}
