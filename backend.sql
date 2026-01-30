-- ============================
-- DROP OLD OBJECTS
-- ============================

DROP TABLE IF EXISTS public.food_requests CASCADE;
DROP TABLE IF EXISTS public.rider_profiles CASCADE;
DROP TABLE IF EXISTS public.organization_profiles CASCADE;
DROP TABLE IF EXISTS public.donor_profiles CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;

DROP TYPE IF EXISTS request_status CASCADE;
DROP TYPE IF EXISTS user_type CASCADE;
DROP TYPE IF EXISTS organization_type CASCADE;

-- ============================
-- ENUM TYPES
-- ============================

CREATE TYPE user_type AS ENUM ('donor', 'rider', 'organization');

CREATE TYPE organization_type AS ENUM ('ngo', 'orphanage', 'oldAgeHome', 'other');

CREATE TYPE request_status AS ENUM (
  'open',
  'pending_pickup',
  'in_transit',
  'completed',
  'cancelled'
);

-- ============================
-- TABLES (NO FOREIGN KEYS YET)
-- ============================

CREATE TABLE public.profiles (
  id TEXT PRIMARY KEY,
  email TEXT,
  name TEXT,
  phone_number TEXT,
  user_type user_type,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE public.donor_profiles (
  id TEXT PRIMARY KEY,
  default_address TEXT,
  default_latitude DOUBLE PRECISION,
  default_longitude DOUBLE PRECISION
);

CREATE TABLE public.organization_profiles (
  id TEXT PRIMARY KEY,
  organization_name TEXT,
  organization_type organization_type,
  address TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  is_verified BOOLEAN,
  license_number TEXT
);

CREATE TABLE public.rider_profiles (
  id TEXT PRIMARY KEY,
  vehicle_type TEXT,
  vehicle_number TEXT,
  is_available BOOLEAN,
  current_latitude DOUBLE PRECISION,
  current_longitude DOUBLE PRECISION
);

CREATE TABLE public.food_requests (
  id TEXT PRIMARY KEY,
  org_id TEXT,
  donor_id TEXT,
  rider_id TEXT,
  food_type TEXT,
  quantity INTEGER,
  status request_status,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
);

-- ============================
-- ADD FOREIGN KEYS AFTER IMPORT
-- ============================

ALTER TABLE donor_profiles
ADD CONSTRAINT fk_donor_profile
FOREIGN KEY (id) REFERENCES profiles(id) ON DELETE CASCADE;

ALTER TABLE organization_profiles
ADD CONSTRAINT fk_org_profile
FOREIGN KEY (id) REFERENCES profiles(id) ON DELETE CASCADE;

ALTER TABLE rider_profiles
ADD CONSTRAINT fk_rider_profile
FOREIGN KEY (id) REFERENCES profiles(id) ON DELETE CASCADE;

ALTER TABLE food_requests
ADD CONSTRAINT fk_req_org
FOREIGN KEY (org_id) REFERENCES organization_profiles(id) ON DELETE CASCADE;

ALTER TABLE food_requests
ADD CONSTRAINT fk_req_donor
FOREIGN KEY (donor_id) REFERENCES donor_profiles(id) ON DELETE SET NULL;

ALTER TABLE food_requests
ADD CONSTRAINT fk_req_rider
FOREIGN KEY (rider_id) REFERENCES rider_profiles(id) ON DELETE SET NULL;
