# Supabase SQL Setup

This file contains the SQL commands to set up the database schema, custom types, and Row Level Security (RLS) policies based on the Flutter domain models.

## 1. Custom Enums

```sql
-- Create custom types for user roles and organization types
CREATE TYPE user_type AS ENUM ('donor', 'rider', 'organization');
CREATE TYPE organization_type AS ENUM ('ngo', 'orphanage', 'oldAgeHome', 'other');
```

## 2. Tables

```sql
-- Profiles table (Base user information)
-- Maps to AppUser model
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
    email TEXT NOT NULL,
    name TEXT NOT NULL,
    phone_number TEXT,
    user_type user_type NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT email_format CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

-- Donor Profiles table
-- Maps to DonorProfile model
CREATE TABLE public.donor_profiles (
    id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    default_address TEXT,
    default_latitude DOUBLE PRECISION,
    default_longitude DOUBLE PRECISION
);

-- Organization Profiles table
-- Maps to OrganizationProfile model
CREATE TABLE public.organization_profiles (
    id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    organization_name TEXT NOT NULL,
    organization_type organization_type NOT NULL,
    address TEXT NOT NULL,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    is_verified BOOLEAN DEFAULT FALSE,
    license_number TEXT
);

-- Rider Profiles table
-- Maps to RiderProfile model
CREATE TABLE public.rider_profiles (
    id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    vehicle_type TEXT NOT NULL,
    vehicle_number TEXT NOT NULL,
    is_available BOOLEAN DEFAULT FALSE,
    current_latitude DOUBLE PRECISION,
    current_longitude DOUBLE PRECISION
);
```

## 3. Row Level Security (RLS)

```sql
-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.donor_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.organization_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rider_profiles ENABLE ROW LEVEL SECURITY;

-- 3.1 Profiles RLS Policies
CREATE POLICY "Users can view their own profile" ON public.profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

-- 3.2 Donor Profiles RLS Policies
CREATE POLICY "Users can view their own profile" ON public.profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);
    
-- 3.3 Organization Profiles RLS Policies
-- Allow anyone to see verified organizations (for discovery)
CREATE POLICY "Public can view verified organization profiles" ON public.organization_profiles
    FOR SELECT USING (is_verified = true OR auth.uid() = id);

CREATE POLICY "Users can update their own organization profile" ON public.organization_profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert their own organization profile" ON public.organization_profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- 3.4 Rider Profiles RLS Policies
-- Riders might need to be visible to others for tracking, but for now limited to owner
CREATE POLICY "Users can view their own rider profile" ON public.rider_profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own rider profile" ON public.rider_profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert their own rider profile" ON public.rider_profiles
    FOR INSERT WITH CHECK (auth.uid() = id);
```

## 4. Authentication Automation

Automatically create a profile entry when a new user signs up via Supabase Auth.

```sql
-- Function to handle new user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, name, user_type)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'name', 'User'),
    COALESCE((NEW.raw_user_meta_data->>'user_type')::user_type, 'donor'::user_type)
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to call the function on signup
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```
