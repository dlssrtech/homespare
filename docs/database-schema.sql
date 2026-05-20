-- HomeSphere production-grade relational schema (PostgreSQL 16+)

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ===== Core identity and access =====
CREATE TABLE roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code VARCHAR(64) UNIQUE NOT NULL,
  name VARCHAR(128) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  full_name VARCHAR(160) NOT NULL,
  phone_e164 VARCHAR(20) UNIQUE NOT NULL,
  email VARCHAR(190),
  password_hash TEXT,
  status VARCHAR(32) NOT NULL DEFAULT 'active',
  referral_code VARCHAR(24) UNIQUE NOT NULL,
  referred_by_user_id UUID REFERENCES users(id),
  city_id UUID,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE user_roles (
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
  PRIMARY KEY(user_id, role_id)
);

CREATE TABLE otp_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone_e164 VARCHAR(20) NOT NULL,
  otp_hash TEXT NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  attempts INT NOT NULL DEFAULT 0,
  consumed_at TIMESTAMPTZ
);

-- ===== Geography, franchise, service taxonomy =====
CREATE TABLE cities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(120) NOT NULL,
  state VARCHAR(120) NOT NULL,
  country VARCHAR(80) NOT NULL DEFAULT 'India',
  is_active BOOLEAN NOT NULL DEFAULT TRUE
);

ALTER TABLE users ADD CONSTRAINT fk_users_city FOREIGN KEY (city_id) REFERENCES cities(id);

CREATE TABLE franchises (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(180) NOT NULL,
  manager_user_id UUID REFERENCES users(id),
  gst_number VARCHAR(40),
  city_id UUID NOT NULL REFERENCES cities(id),
  revenue_share_percent NUMERIC(5,2) NOT NULL DEFAULT 0,
  status VARCHAR(32) NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE service_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug VARCHAR(64) UNIQUE NOT NULL,
  name VARCHAR(120) NOT NULL,
  parent_id UUID REFERENCES service_categories(id),
  is_active BOOLEAN NOT NULL DEFAULT TRUE
);

-- ===== Profile extensions =====
CREATE TABLE customer_profiles (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  default_address_id UUID,
  loyalty_tier VARCHAR(32) DEFAULT 'basic'
);

CREATE TABLE vendor_profiles (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  business_name VARCHAR(190) NOT NULL,
  kyc_status VARCHAR(32) NOT NULL DEFAULT 'pending',
  franchise_id UUID REFERENCES franchises(id),
  is_available BOOLEAN NOT NULL DEFAULT FALSE,
  rating_avg NUMERIC(3,2) DEFAULT 0,
  total_jobs INT NOT NULL DEFAULT 0
);

CREATE TABLE technician_profiles (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  vendor_user_id UUID REFERENCES vendor_profiles(user_id),
  attendance_required BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE designer_profiles (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  portfolio_url TEXT,
  specialization TEXT
);

CREATE TABLE addresses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  label VARCHAR(64) NOT NULL,
  line1 VARCHAR(220) NOT NULL,
  line2 VARCHAR(220),
  landmark VARCHAR(120),
  city_id UUID NOT NULL REFERENCES cities(id),
  pincode VARCHAR(12) NOT NULL,
  latitude NUMERIC(10,7),
  longitude NUMERIC(10,7),
  is_default BOOLEAN NOT NULL DEFAULT FALSE
);

ALTER TABLE customer_profiles
ADD CONSTRAINT fk_customer_default_address FOREIGN KEY (default_address_id) REFERENCES addresses(id);

-- ===== Job management =====
CREATE TABLE service_catalog (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id UUID NOT NULL REFERENCES service_categories(id),
  title VARCHAR(190) NOT NULL,
  description TEXT,
  base_price NUMERIC(12,2) NOT NULL,
  duration_minutes INT,
  gst_percent NUMERIC(5,2) NOT NULL DEFAULT 18,
  is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE bookings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_user_id UUID NOT NULL REFERENCES users(id),
  service_id UUID REFERENCES service_catalog(id),
  booking_type VARCHAR(32) NOT NULL, -- household/interior/emergency/amc
  status VARCHAR(32) NOT NULL DEFAULT 'requested',
  schedule_at TIMESTAMPTZ NOT NULL,
  address_id UUID REFERENCES addresses(id),
  assigned_vendor_user_id UUID REFERENCES vendor_profiles(user_id),
  assigned_technician_user_id UUID REFERENCES technician_profiles(user_id),
  city_id UUID NOT NULL REFERENCES cities(id),
  franchise_id UUID REFERENCES franchises(id),
  subtotal NUMERIC(12,2) NOT NULL DEFAULT 0,
  discount_total NUMERIC(12,2) NOT NULL DEFAULT 0,
  commission_total NUMERIC(12,2) NOT NULL DEFAULT 0,
  gst_total NUMERIC(12,2) NOT NULL DEFAULT 0,
  grand_total NUMERIC(12,2) NOT NULL DEFAULT 0,
  payment_status VARCHAR(32) NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE booking_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
  event_type VARCHAR(64) NOT NULL,
  note TEXT,
  latitude NUMERIC(10,7),
  longitude NUMERIC(10,7),
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE booking_proofs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
  uploaded_by UUID NOT NULL REFERENCES users(id),
  media_url TEXT NOT NULL,
  media_type VARCHAR(32) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id UUID UNIQUE NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
  customer_user_id UUID NOT NULL REFERENCES users(id),
  vendor_user_id UUID REFERENCES users(id),
  rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ===== Interior design domain =====
CREATE TABLE interior_projects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_user_id UUID NOT NULL REFERENCES users(id),
  designer_user_id UUID REFERENCES designer_profiles(user_id),
  booking_id UUID REFERENCES bookings(id),
  title VARCHAR(200) NOT NULL,
  property_type VARCHAR(80),
  status VARCHAR(32) NOT NULL DEFAULT 'discovery',
  budget_min NUMERIC(14,2),
  budget_max NUMERIC(14,2),
  start_date DATE,
  target_end_date DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE design_assets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES interior_projects(id) ON DELETE CASCADE,
  asset_type VARCHAR(32) NOT NULL, -- 2d/3d/moodboard
  title VARCHAR(180),
  file_url TEXT NOT NULL,
  version_no INT NOT NULL DEFAULT 1,
  approval_status VARCHAR(32) NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE boq_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES interior_projects(id) ON DELETE CASCADE,
  item_name VARCHAR(190) NOT NULL,
  quantity NUMERIC(12,2) NOT NULL,
  uom VARCHAR(30) NOT NULL,
  unit_cost NUMERIC(12,2) NOT NULL,
  vendor_source VARCHAR(190),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE project_milestones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES interior_projects(id) ON DELETE CASCADE,
  name VARCHAR(140) NOT NULL,
  due_date DATE,
  percent_weight NUMERIC(5,2) NOT NULL DEFAULT 0,
  status VARCHAR(32) NOT NULL DEFAULT 'pending'
);

-- ===== Wallet, referral, commission, subscriptions =====
CREATE TABLE wallets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  balance NUMERIC(14,2) NOT NULL DEFAULT 0,
  currency VARCHAR(8) NOT NULL DEFAULT 'INR',
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE wallet_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  wallet_id UUID NOT NULL REFERENCES wallets(id) ON DELETE CASCADE,
  txn_type VARCHAR(32) NOT NULL, -- credit/debit/hold/release
  source_type VARCHAR(40) NOT NULL,
  source_id UUID,
  amount NUMERIC(14,2) NOT NULL,
  status VARCHAR(32) NOT NULL DEFAULT 'completed',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE commission_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rule_type VARCHAR(40) NOT NULL, -- dynamic/fixed/category/vendor/franchise
  category_id UUID REFERENCES service_categories(id),
  vendor_user_id UUID REFERENCES vendor_profiles(user_id),
  franchise_id UUID REFERENCES franchises(id),
  percent_value NUMERIC(5,2),
  fixed_value NUMERIC(12,2),
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  starts_at TIMESTAMPTZ,
  ends_at TIMESTAMPTZ
);

CREATE TABLE booking_commissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
  beneficiary_user_id UUID REFERENCES users(id),
  franchise_id UUID REFERENCES franchises(id),
  rule_id UUID REFERENCES commission_rules(id),
  amount NUMERIC(12,2) NOT NULL,
  status VARCHAR(32) NOT NULL DEFAULT 'pending_settlement'
);

CREATE TABLE referral_links (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  referrer_user_id UUID NOT NULL REFERENCES users(id),
  referred_user_id UUID UNIQUE NOT NULL REFERENCES users(id),
  level_no INT NOT NULL DEFAULT 1,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE referral_reward_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_type VARCHAR(30) NOT NULL, -- customer/vendor/franchise
  level_no INT NOT NULL DEFAULT 1,
  reward_type VARCHAR(20) NOT NULL, -- fixed/percent
  reward_value NUMERIC(10,2) NOT NULL,
  trigger_event VARCHAR(64) NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE referral_rewards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rule_id UUID REFERENCES referral_reward_rules(id),
  referrer_user_id UUID NOT NULL REFERENCES users(id),
  referred_user_id UUID NOT NULL REFERENCES users(id),
  booking_id UUID REFERENCES bookings(id),
  amount NUMERIC(12,2) NOT NULL,
  status VARCHAR(32) NOT NULL DEFAULT 'credited',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE subscription_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(120) NOT NULL,
  code VARCHAR(60) UNIQUE NOT NULL,
  validity_days INT NOT NULL,
  price NUMERIC(12,2) NOT NULL,
  services_included JSONB,
  is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE customer_subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  plan_id UUID NOT NULL REFERENCES subscription_plans(id),
  starts_at TIMESTAMPTZ NOT NULL,
  ends_at TIMESTAMPTZ NOT NULL,
  status VARCHAR(32) NOT NULL DEFAULT 'active'
);

-- ===== Payments, invoices, support =====
CREATE TABLE payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id UUID REFERENCES bookings(id),
  provider VARCHAR(24) NOT NULL, -- razorpay/cashfree/cod/wallet
  provider_order_id VARCHAR(120),
  provider_payment_id VARCHAR(120),
  amount NUMERIC(12,2) NOT NULL,
  status VARCHAR(32) NOT NULL DEFAULT 'initiated',
  paid_at TIMESTAMPTZ,
  metadata JSONB
);

CREATE TABLE refunds (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  payment_id UUID NOT NULL REFERENCES payments(id),
  amount NUMERIC(12,2) NOT NULL,
  reason TEXT,
  status VARCHAR(32) NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE invoices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id UUID UNIQUE NOT NULL REFERENCES bookings(id),
  invoice_no VARCHAR(64) UNIQUE NOT NULL,
  gstin VARCHAR(40),
  taxable_amount NUMERIC(12,2) NOT NULL,
  gst_amount NUMERIC(12,2) NOT NULL,
  total_amount NUMERIC(12,2) NOT NULL,
  pdf_url TEXT,
  generated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE support_tickets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  booking_id UUID REFERENCES bookings(id),
  subject VARCHAR(180) NOT NULL,
  description TEXT,
  priority VARCHAR(24) NOT NULL DEFAULT 'normal',
  status VARCHAR(24) NOT NULL DEFAULT 'open',
  assigned_to UUID REFERENCES users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_bookings_customer ON bookings(customer_user_id);
CREATE INDEX idx_bookings_vendor ON bookings(assigned_vendor_user_id);
CREATE INDEX idx_bookings_city_status ON bookings(city_id, status);
CREATE INDEX idx_wallet_txn_wallet ON wallet_transactions(wallet_id, created_at DESC);
CREATE INDEX idx_referral_rewards_referrer ON referral_rewards(referrer_user_id, created_at DESC);
CREATE INDEX idx_support_tickets_status ON support_tickets(status, created_at DESC);
