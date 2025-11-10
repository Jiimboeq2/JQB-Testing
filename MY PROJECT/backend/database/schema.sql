-- ISXJQB License Database Schema
-- PostgreSQL/Neon Database

-- Permission tiers enum
DO $$ BEGIN
    CREATE TYPE permission_tier AS ENUM ('acolyte', 'oracle', 'god');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Licenses table
CREATE TABLE IF NOT EXISTS licenses (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL,
    license_key VARCHAR(39) NOT NULL,
    active BOOLEAN DEFAULT TRUE,
    tier permission_tier DEFAULT 'acolyte',
    max_characters INTEGER DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NOT NULL,
    last_used_at TIMESTAMP,
    use_count INTEGER DEFAULT 0,
    features JSONB DEFAULT '["basic"]'::jsonb,
    notes TEXT,

    -- Indexes for fast lookups
    CONSTRAINT unique_license UNIQUE (license_key),
    CONSTRAINT unique_email_license UNIQUE (email, license_key)
);

CREATE INDEX IF NOT EXISTS idx_licenses_email ON licenses(email);
CREATE INDEX IF NOT EXISTS idx_licenses_key ON licenses(license_key);
CREATE INDEX IF NOT EXISTS idx_licenses_active ON licenses(active);
CREATE INDEX IF NOT EXISTS idx_licenses_expires ON licenses(expires_at);
CREATE INDEX IF NOT EXISTS idx_licenses_tier ON licenses(tier);

-- Audit log table (track all verification attempts)
CREATE TABLE IF NOT EXISTS license_audit_log (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255),
    license_key VARCHAR(39),
    success BOOLEAN,
    tier permission_tier,
    ip_address INET,
    user_agent TEXT,
    attempted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    response_message TEXT
);

CREATE INDEX IF NOT EXISTS idx_audit_email ON license_audit_log(email);
CREATE INDEX IF NOT EXISTS idx_audit_attempted ON license_audit_log(attempted_at);
CREATE INDEX IF NOT EXISTS idx_audit_success ON license_audit_log(success);

-- PayPal transactions table (optional - link purchases to licenses)
CREATE TABLE IF NOT EXISTS paypal_transactions (
    id SERIAL PRIMARY KEY,
    transaction_id VARCHAR(255) UNIQUE NOT NULL,
    payer_email VARCHAR(255) NOT NULL,
    amount DECIMAL(10, 2),
    currency VARCHAR(3) DEFAULT 'USD',
    status VARCHAR(50),
    tier_purchased permission_tier DEFAULT 'acolyte',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    license_id INTEGER REFERENCES licenses(id)
);

CREATE INDEX IF NOT EXISTS idx_paypal_email ON paypal_transactions(payer_email);
CREATE INDEX IF NOT EXISTS idx_paypal_transaction ON paypal_transactions(transaction_id);

-- Example data (REMOVE IN PRODUCTION)
INSERT INTO licenses (email, license_key, expires_at, tier, max_characters, features) VALUES
    ('god@example.com', '66B0-00B8-558A-5B6A-7B91-246E-9E98-B5DC', '2025-12-31', 'god', 999, '["basic", "premium", "vip", "beta"]'::jsonb),
    ('oracle@example.com', 'AAAA-BBBB-CCCC-DDDD-EEEE-FFFF-1111-2222', '2025-06-30', 'oracle', 10, '["basic", "premium"]'::jsonb),
    ('acolyte@example.com', '1111-2222-3333-4444-5555-6666-7777-8888', '2025-06-30', 'acolyte', 1, '["basic"]'::jsonb)
ON CONFLICT DO NOTHING;

-- Function to generate new license key
CREATE OR REPLACE FUNCTION generate_license_key()
RETURNS VARCHAR(39) AS $$
DECLARE
    key VARCHAR(39);
    chars VARCHAR(36) := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    i INTEGER;
BEGIN
    key := '';
    FOR i IN 1..8 LOOP
        IF i > 1 THEN
            key := key || '-';
        END IF;
        key := key ||
            substr(chars, floor(random() * 36)::int + 1, 1) ||
            substr(chars, floor(random() * 36)::int + 1, 1) ||
            substr(chars, floor(random() * 36)::int + 1, 1) ||
            substr(chars, floor(random() * 36)::int + 1, 1);
    END LOOP;
    RETURN key;
END;
$$ LANGUAGE plpgsql;

-- Function to create new license
CREATE OR REPLACE FUNCTION create_license(
    p_email VARCHAR(255),
    p_expires_at TIMESTAMP,
    p_tier permission_tier DEFAULT 'acolyte',
    p_max_characters INTEGER DEFAULT 1,
    p_features JSONB DEFAULT '["basic"]'::jsonb
)
RETURNS TABLE (
    license_key VARCHAR(39),
    email VARCHAR(255),
    tier permission_tier,
    max_characters INTEGER,
    expires_at TIMESTAMP
) AS $$
DECLARE
    new_key VARCHAR(39);
BEGIN
    -- Generate unique key
    LOOP
        new_key := generate_license_key();
        EXIT WHEN NOT EXISTS (SELECT 1 FROM licenses WHERE licenses.license_key = new_key);
    END LOOP;

    -- Insert license
    INSERT INTO licenses (email, license_key, expires_at, tier, max_characters, features)
    VALUES (p_email, new_key, p_expires_at, p_tier, p_max_characters, p_features);

    RETURN QUERY
    SELECT new_key, p_email, p_tier, p_max_characters, p_expires_at;
END;
$$ LANGUAGE plpgsql;

-- Example usage:
-- Acolyte (1 character, basic features):
-- SELECT * FROM create_license('user@example.com', '2025-12-31', 'acolyte', 1, '["basic"]'::jsonb);
--
-- Oracle (10 characters, premium features):
-- SELECT * FROM create_license('oracle@example.com', '2025-12-31', 'oracle', 10, '["basic", "premium"]'::jsonb);
--
-- God (unlimited, all features):
-- SELECT * FROM create_license('admin@example.com', '2025-12-31', 'god', 999, '["basic", "premium", "vip", "beta"]'::jsonb);

-- Function to extend license
CREATE OR REPLACE FUNCTION extend_license(
    p_license_key VARCHAR(39),
    p_days INTEGER
)
RETURNS TIMESTAMP AS $$
DECLARE
    new_expiry TIMESTAMP;
BEGIN
    UPDATE licenses
    SET expires_at = expires_at + (p_days || ' days')::INTERVAL
    WHERE license_key = p_license_key
    RETURNING expires_at INTO new_expiry;

    RETURN new_expiry;
END;
$$ LANGUAGE plpgsql;

-- Function to upgrade tier
CREATE OR REPLACE FUNCTION upgrade_tier(
    p_license_key VARCHAR(39),
    p_new_tier permission_tier
)
RETURNS permission_tier AS $$
DECLARE
    updated_tier permission_tier;
BEGIN
    UPDATE licenses
    SET tier = p_new_tier,
        max_characters = CASE
            WHEN p_new_tier = 'god' THEN 999
            WHEN p_new_tier = 'oracle' THEN 10
            ELSE 1
        END,
        features = CASE
            WHEN p_new_tier = 'god' THEN '["basic", "premium", "vip", "beta"]'::jsonb
            WHEN p_new_tier = 'oracle' THEN '["basic", "premium"]'::jsonb
            ELSE '["basic"]'::jsonb
        END
    WHERE license_key = p_license_key
    RETURNING tier INTO updated_tier;

    RETURN updated_tier;
END;
$$ LANGUAGE plpgsql;

-- Example: Upgrade user to oracle
-- SELECT upgrade_tier('1111-2222-3333-4444-5555-6666-7777-8888', 'oracle');

-- View for active licenses
CREATE OR REPLACE VIEW active_licenses AS
SELECT
    id,
    email,
    license_key,
    tier,
    max_characters,
    expires_at,
    features,
    use_count,
    last_used_at,
    CASE
        WHEN expires_at > CURRENT_TIMESTAMP THEN 'Active'
        ELSE 'Expired'
    END AS status
FROM licenses
WHERE active = TRUE
ORDER BY created_at DESC;

-- View for license statistics by tier
CREATE OR REPLACE VIEW license_stats AS
SELECT
    COUNT(*) AS total_licenses,
    COUNT(*) FILTER (WHERE active = TRUE) AS active_licenses,
    COUNT(*) FILTER (WHERE expires_at > CURRENT_TIMESTAMP) AS valid_licenses,
    COUNT(*) FILTER (WHERE expires_at <= CURRENT_TIMESTAMP) AS expired_licenses,
    COUNT(*) FILTER (WHERE tier = 'god') AS god_tier,
    COUNT(*) FILTER (WHERE tier = 'oracle') AS oracle_tier,
    COUNT(*) FILTER (WHERE tier = 'acolyte') AS acolyte_tier,
    SUM(use_count) AS total_uses,
    COUNT(DISTINCT email) AS unique_users
FROM licenses;

-- Tier pricing view (for reference)
CREATE OR REPLACE VIEW tier_info AS
SELECT
    'acolyte'::permission_tier as tier,
    1 as max_characters,
    '["basic"]'::jsonb as features,
    'Single character, basic features' as description
UNION ALL
SELECT
    'oracle'::permission_tier,
    10,
    '["basic", "premium"]'::jsonb,
    'Up to 10 characters, premium features'
UNION ALL
SELECT
    'god'::permission_tier,
    999,
    '["basic", "premium", "vip", "beta"]'::jsonb,
    'Unlimited characters, all features, beta access';
