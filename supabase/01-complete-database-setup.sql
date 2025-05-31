-- ===================================================================
-- COMPLETE DATABASE SETUP FOR ROMANIAN FURNITURE RFQ MARKETPLACE
-- ===================================================================
-- Run this script in Supabase SQL Editor to set up the entire database
-- This includes both the main system and the firm portal system
-- ===================================================================

-- STEP 1: CLEANUP (Remove existing objects to start fresh)
-- ===================================================================

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view their own profile" ON public.users CASCADE;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.users CASCADE;
DROP POLICY IF EXISTS "Authenticated users can insert their profile" ON public.users CASCADE;
DROP POLICY IF EXISTS "Users can view their own homes" ON public.homes CASCADE;
DROP POLICY IF EXISTS "Users can manage their own homes" ON public.homes CASCADE;
DROP POLICY IF EXISTS "Users can view their own RFQs" ON public.rfqs CASCADE;
DROP POLICY IF EXISTS "Manufacturers can view active RFQs" ON public.rfqs CASCADE;
DROP POLICY IF EXISTS "Users can manage their own RFQs" ON public.rfqs CASCADE;
DROP POLICY IF EXISTS "Users can view offers for their RFQs" ON public.offers CASCADE;
DROP POLICY IF EXISTS "Manufacturers can view their own offers" ON public.offers CASCADE;
DROP POLICY IF EXISTS "Manufacturers can create offers" ON public.offers CASCADE;
DROP POLICY IF EXISTS "Manufacturers can update their own offers" ON public.offers CASCADE;

-- Drop firm system policies
DROP POLICY IF EXISTS "Enable read for firm users" ON public.firms CASCADE;
DROP POLICY IF EXISTS "Enable insert for new firms" ON public.firms CASCADE;
DROP POLICY IF EXISTS "Enable update for firm CEOs" ON public.firms CASCADE;
DROP POLICY IF EXISTS "Enable read for own firm users" ON public.firm_users CASCADE;
DROP POLICY IF EXISTS "Enable insert for firm CEOs" ON public.firm_users CASCADE;
DROP POLICY IF EXISTS "Enable update for firm CEOs" ON public.firm_users CASCADE;
DROP POLICY IF EXISTS "Enable delete for firm CEOs" ON public.firm_users CASCADE;
DROP POLICY IF EXISTS "Enable read for own firm settings" ON public.firm_settings CASCADE;
DROP POLICY IF EXISTS "Enable update for firm CEOs" ON public.firm_settings CASCADE;
DROP POLICY IF EXISTS "Enable read for firm assignments" ON public.rfq_assignments CASCADE;
DROP POLICY IF EXISTS "Enable insert for assignments" ON public.rfq_assignments CASCADE;
DROP POLICY IF EXISTS "Enable update for assignments" ON public.rfq_assignments CASCADE;

-- Drop triggers
DROP TRIGGER IF EXISTS validate_manufacturer_offer_trigger ON public.offers CASCADE;
DROP TRIGGER IF EXISTS update_users_updated_at ON public.users CASCADE;
DROP TRIGGER IF EXISTS update_homes_updated_at ON public.homes CASCADE;
DROP TRIGGER IF EXISTS update_rfqs_updated_at ON public.rfqs CASCADE;
DROP TRIGGER IF EXISTS update_offers_updated_at ON public.offers CASCADE;
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users CASCADE;
DROP TRIGGER IF EXISTS on_auth_user_login ON auth.users CASCADE;

-- Drop functions
DROP FUNCTION IF EXISTS public.validate_manufacturer_offer() CASCADE;
DROP FUNCTION IF EXISTS public.update_updated_at_column() CASCADE;
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS public.update_user_last_login() CASCADE;
DROP FUNCTION IF EXISTS public.get_filtered_rfqs(uuid, text[], text[], numeric, numeric, text) CASCADE;

-- Drop indexes
DROP INDEX IF EXISTS idx_users_role CASCADE;
DROP INDEX IF EXISTS idx_users_status CASCADE;
DROP INDEX IF EXISTS idx_users_company CASCADE;
DROP INDEX IF EXISTS idx_homes_user_id CASCADE;
DROP INDEX IF EXISTS idx_rfqs_user_id CASCADE;
DROP INDEX IF EXISTS idx_rfqs_status CASCADE;
DROP INDEX IF EXISTS idx_rfqs_created_at CASCADE;
DROP INDEX IF EXISTS idx_rfq_categories_rfq_id CASCADE;
DROP INDEX IF EXISTS idx_offers_rfq_id CASCADE;
DROP INDEX IF EXISTS idx_offers_manufacturer_id CASCADE;
DROP INDEX IF EXISTS idx_messages_rfq_id CASCADE;
DROP INDEX IF EXISTS idx_messages_participants CASCADE;
DROP INDEX IF EXISTS idx_notifications_user_id CASCADE;
DROP INDEX IF EXISTS idx_notifications_unread CASCADE;

-- Drop firm system indexes
DROP INDEX IF EXISTS idx_firm_users_firm_id CASCADE;
DROP INDEX IF EXISTS idx_firm_users_email CASCADE;
DROP INDEX IF EXISTS idx_rfq_assignments_rfq_id CASCADE;
DROP INDEX IF EXISTS idx_rfq_assignments_firm_user_id CASCADE;
DROP INDEX IF EXISTS idx_firm_sessions_token CASCADE;
DROP INDEX IF EXISTS idx_firm_sessions_user_id CASCADE;

-- Drop tables (in correct order due to foreign keys)
DROP TABLE IF EXISTS public.rfq_assignments CASCADE;
DROP TABLE IF EXISTS public.firm_sessions CASCADE;
DROP TABLE IF EXISTS public.firm_settings CASCADE;
DROP TABLE IF EXISTS public.firm_users CASCADE;
DROP TABLE IF EXISTS public.firms CASCADE;
DROP TABLE IF EXISTS public.notifications CASCADE;
DROP TABLE IF EXISTS public.messages CASCADE;
DROP TABLE IF EXISTS public.offers CASCADE;
DROP TABLE IF EXISTS public.files CASCADE;
DROP TABLE IF EXISTS public.rfq_answers CASCADE;
DROP TABLE IF EXISTS public.rfq_categories CASCADE;
DROP TABLE IF EXISTS public.rfqs CASCADE;
DROP TABLE IF EXISTS public.categories CASCADE;
DROP TABLE IF EXISTS public.homes CASCADE;
DROP TABLE IF EXISTS public.users CASCADE;

-- Drop types
DROP TYPE IF EXISTS user_role CASCADE;
DROP TYPE IF EXISTS account_status CASCADE;
DROP TYPE IF EXISTS rfq_status CASCADE;
DROP TYPE IF EXISTS offer_status CASCADE;
DROP TYPE IF EXISTS message_status CASCADE;
DROP TYPE IF EXISTS firm_user_role CASCADE;
DROP TYPE IF EXISTS assignment_mode CASCADE;
DROP TYPE IF EXISTS assignment_status CASCADE;

-- STEP 2: ENABLE EXTENSIONS
-- ===================================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- STEP 3: CREATE CUSTOM TYPES
-- ===================================================================
CREATE TYPE user_role AS ENUM ('homeowner', 'architect', 'manufacturer', 'admin');
CREATE TYPE account_status AS ENUM ('active', 'inactive', 'pending', 'suspended');
CREATE TYPE rfq_status AS ENUM ('draft', 'active', 'closed', 'expired', 'completed');
CREATE TYPE offer_status AS ENUM ('pending', 'accepted', 'rejected', 'withdrawn');
CREATE TYPE message_status AS ENUM ('sent', 'delivered', 'read');
CREATE TYPE firm_user_role AS ENUM ('ceo', 'employee');
CREATE TYPE assignment_mode AS ENUM ('ceo_only', 'free_assignment');
CREATE TYPE assignment_status AS ENUM ('pending', 'accepted', 'completed', 'cancelled');

-- STEP 4: CREATE MAIN SYSTEM TABLES
-- ===================================================================

-- Users table (extends Supabase auth.users)
CREATE TABLE public.users (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  first_name TEXT,
  last_name TEXT,
  phone TEXT,
  role user_role NOT NULL DEFAULT 'homeowner',
  status account_status NOT NULL DEFAULT 'active',
  company_name TEXT,
  company_description TEXT,
  company_website TEXT,
  company_address TEXT,
  company_phone TEXT,
  tax_id TEXT,
  is_verified BOOLEAN DEFAULT FALSE,
  avatar_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_login TIMESTAMP WITH TIME ZONE,
  manufacturer_parent_id UUID REFERENCES public.users(id),
  
  CONSTRAINT valid_role_company CHECK (
    (role IN ('homeowner', 'architect') AND company_name IS NULL) OR
    (role = 'manufacturer' AND company_name IS NOT NULL)
  )
);

-- Homes/Properties table
CREATE TABLE public.homes (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  country TEXT NOT NULL DEFAULT 'România',
  county TEXT NOT NULL,
  city TEXT NOT NULL,
  street TEXT NOT NULL,
  number TEXT NOT NULL,
  apartment TEXT,
  postal_code TEXT,
  description TEXT,
  total_area DECIMAL,
  is_primary BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Categories table
CREATE TABLE public.categories (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name TEXT NOT NULL,
  name_ro TEXT NOT NULL,
  description TEXT,
  description_ro TEXT,
  icon TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RFQs table
CREATE TABLE public.rfqs (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  home_id UUID REFERENCES public.homes(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  description TEXT,
  status rfq_status NOT NULL DEFAULT 'draft',
  budget_min DECIMAL,
  budget_max DECIMAL,
  deadline DATE,
  is_urgent BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  published_at TIMESTAMP WITH TIME ZONE,
  expires_at TIMESTAMP WITH TIME ZONE,
  completed_at TIMESTAMP WITH TIME ZONE
);

-- RFQ Categories junction table
CREATE TABLE public.rfq_categories (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  rfq_id UUID REFERENCES public.rfqs(id) ON DELETE CASCADE NOT NULL,
  category_id UUID REFERENCES public.categories(id) ON DELETE CASCADE NOT NULL,
  quantity INTEGER NOT NULL DEFAULT 1,
  room_name TEXT,
  specific_requirements TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(rfq_id, category_id, room_name)
);

-- RFQ Answers table
CREATE TABLE public.rfq_answers (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  rfq_id UUID REFERENCES public.rfqs(id) ON DELETE CASCADE NOT NULL,
  category_id UUID REFERENCES public.categories(id) ON DELETE CASCADE,
  question_key TEXT NOT NULL,
  question_text TEXT NOT NULL,
  answer_value TEXT,
  answer_data JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Files table
CREATE TABLE public.files (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  rfq_id UUID REFERENCES public.rfqs(id) ON DELETE CASCADE,
  filename TEXT NOT NULL,
  original_filename TEXT NOT NULL,
  file_path TEXT NOT NULL,
  file_size BIGINT NOT NULL,
  mime_type TEXT NOT NULL,
  description TEXT,
  is_public BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Offers table
CREATE TABLE public.offers (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  rfq_id UUID REFERENCES public.rfqs(id) ON DELETE CASCADE NOT NULL,
  manufacturer_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  price DECIMAL NOT NULL,
  currency TEXT DEFAULT 'RON',
  delivery_time_days INTEGER,
  delivery_time_text TEXT,
  materials_description TEXT,
  warranty_months INTEGER,
  status offer_status NOT NULL DEFAULT 'pending',
  valid_until DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Messages table
CREATE TABLE public.messages (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  rfq_id UUID REFERENCES public.rfqs(id) ON DELETE CASCADE NOT NULL,
  sender_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  recipient_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  subject TEXT,
  content TEXT NOT NULL,
  status message_status NOT NULL DEFAULT 'sent',
  is_system_message BOOLEAN DEFAULT FALSE,
  parent_message_id UUID REFERENCES public.messages(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  read_at TIMESTAMP WITH TIME ZONE
);

-- Notifications table
CREATE TABLE public.notifications (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  data JSONB,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  read_at TIMESTAMP WITH TIME ZONE
);

-- STEP 5: CREATE FIRM SYSTEM TABLES
-- ===================================================================

-- Firms table
CREATE TABLE public.firms (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name TEXT NOT NULL,
  tax_id TEXT UNIQUE NOT NULL,
  address TEXT NOT NULL,
  city TEXT NOT NULL,
  county TEXT NOT NULL,
  phone TEXT NOT NULL,
  email TEXT NOT NULL,
  website TEXT,
  description TEXT,
  logo_url TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Firm users table
CREATE TABLE public.firm_users (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  firm_id UUID REFERENCES public.firms(id) ON DELETE CASCADE NOT NULL,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  phone TEXT,
  role firm_user_role NOT NULL DEFAULT 'employee',
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_login TIMESTAMP WITH TIME ZONE
);

-- Firm settings table
CREATE TABLE public.firm_settings (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  firm_id UUID REFERENCES public.firms(id) ON DELETE CASCADE NOT NULL UNIQUE,
  assignment_mode assignment_mode NOT NULL DEFAULT 'ceo_only',
  max_active_rfqs INTEGER DEFAULT 10,
  auto_assign_enabled BOOLEAN DEFAULT FALSE,
  notification_email TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RFQ assignments table
CREATE TABLE public.rfq_assignments (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  rfq_id UUID REFERENCES public.rfqs(id) ON DELETE CASCADE NOT NULL,
  firm_id UUID REFERENCES public.firms(id) ON DELETE CASCADE NOT NULL,
  firm_user_id UUID REFERENCES public.firm_users(id) ON DELETE SET NULL,
  status assignment_status NOT NULL DEFAULT 'pending',
  assigned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  accepted_at TIMESTAMP WITH TIME ZONE,
  completed_at TIMESTAMP WITH TIME ZONE,
  response_message TEXT,
  internal_notes TEXT,
  
  UNIQUE(rfq_id, firm_id)
);

-- Firm sessions table
CREATE TABLE public.firm_sessions (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  token TEXT UNIQUE NOT NULL,
  firm_user_id UUID REFERENCES public.firm_users(id) ON DELETE CASCADE NOT NULL,
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- STEP 6: CREATE INDEXES
-- ===================================================================

-- Main system indexes
CREATE INDEX idx_users_role ON public.users(role);
CREATE INDEX idx_users_status ON public.users(status);
CREATE INDEX idx_users_company ON public.users(company_name) WHERE role = 'manufacturer';
CREATE INDEX idx_homes_user_id ON public.homes(user_id);
CREATE INDEX idx_rfqs_user_id ON public.rfqs(user_id);
CREATE INDEX idx_rfqs_status ON public.rfqs(status);
CREATE INDEX idx_rfqs_created_at ON public.rfqs(created_at DESC);
CREATE INDEX idx_rfq_categories_rfq_id ON public.rfq_categories(rfq_id);
CREATE INDEX idx_offers_rfq_id ON public.offers(rfq_id);
CREATE INDEX idx_offers_manufacturer_id ON public.offers(manufacturer_id);
CREATE INDEX idx_messages_rfq_id ON public.messages(rfq_id);
CREATE INDEX idx_messages_participants ON public.messages(sender_id, recipient_id);
CREATE INDEX idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX idx_notifications_unread ON public.notifications(user_id, is_read) WHERE is_read = FALSE;

-- Firm system indexes
CREATE INDEX idx_firm_users_firm_id ON public.firm_users(firm_id);
CREATE INDEX idx_firm_users_email ON public.firm_users(email);
CREATE INDEX idx_rfq_assignments_rfq_id ON public.rfq_assignments(rfq_id);
CREATE INDEX idx_rfq_assignments_firm_user_id ON public.rfq_assignments(firm_user_id);
CREATE INDEX idx_firm_sessions_token ON public.firm_sessions(token);
CREATE INDEX idx_firm_sessions_user_id ON public.firm_sessions(firm_user_id);

-- STEP 7: CREATE FUNCTIONS
-- ===================================================================

-- Updated at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Validate manufacturer offers function
CREATE OR REPLACE FUNCTION validate_manufacturer_offer()
RETURNS TRIGGER AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.users 
    WHERE id = NEW.manufacturer_id AND role = 'manufacturer'
  ) THEN
    RAISE EXCEPTION 'Only users with manufacturer role can create offers';
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Handle new user function
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, first_name, last_name, role, phone)
  VALUES (
    NEW.id,
    NEW.email,
    NEW.raw_user_meta_data->>'first_name',
    NEW.raw_user_meta_data->>'last_name',
    COALESCE(NEW.raw_user_meta_data->>'role', 'homeowner')::user_role,
    NEW.raw_user_meta_data->>'phone'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update user last login function
CREATE OR REPLACE FUNCTION public.update_user_last_login()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.users 
  SET last_login = NOW()
  WHERE id = NEW.id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get filtered RFQs function (for firm dashboard)
CREATE OR REPLACE FUNCTION public.get_filtered_rfqs(
  p_firm_id UUID,
  p_categories TEXT[] DEFAULT NULL,
  p_locations TEXT[] DEFAULT NULL,
  p_min_budget NUMERIC DEFAULT NULL,
  p_max_budget NUMERIC DEFAULT NULL,
  p_response_time TEXT DEFAULT NULL
)
RETURNS TABLE (
  id UUID,
  title TEXT,
  description TEXT,
  budget_min DECIMAL,
  budget_max DECIMAL,
  deadline DATE,
  is_urgent BOOLEAN,
  created_at TIMESTAMP WITH TIME ZONE,
  location TEXT,
  categories JSONB,
  is_assigned BOOLEAN,
  assigned_to UUID
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    r.id,
    r.title,
    r.description,
    r.budget_min,
    r.budget_max,
    r.deadline,
    r.is_urgent,
    r.created_at,
    COALESCE(h.city || ', ' || h.county, 'România') as location,
    COALESCE(
      jsonb_agg(
        DISTINCT jsonb_build_object(
          'id', c.id,
          'name', c.name,
          'name_ro', c.name_ro
        )
      ) FILTER (WHERE c.id IS NOT NULL),
      '[]'::jsonb
    ) as categories,
    EXISTS (
      SELECT 1 FROM public.rfq_assignments ra 
      WHERE ra.rfq_id = r.id AND ra.firm_id = p_firm_id
    ) as is_assigned,
    (
      SELECT ra.firm_user_id 
      FROM public.rfq_assignments ra 
      WHERE ra.rfq_id = r.id AND ra.firm_id = p_firm_id
      LIMIT 1
    ) as assigned_to
  FROM public.rfqs r
  LEFT JOIN public.homes h ON r.home_id = h.id
  LEFT JOIN public.rfq_categories rc ON rc.rfq_id = r.id
  LEFT JOIN public.categories c ON c.id = rc.category_id
  WHERE r.status = 'active'
    AND (p_categories IS NULL OR c.name = ANY(p_categories))
    AND (p_locations IS NULL OR h.city = ANY(p_locations) OR h.county = ANY(p_locations))
    AND (p_min_budget IS NULL OR r.budget_max >= p_min_budget)
    AND (p_max_budget IS NULL OR r.budget_min <= p_max_budget)
    AND (
      p_response_time IS NULL OR
      (p_response_time = 'urgent' AND r.is_urgent = true) OR
      (p_response_time = '7days' AND r.deadline <= CURRENT_DATE + INTERVAL '7 days') OR
      (p_response_time = '30days' AND r.deadline <= CURRENT_DATE + INTERVAL '30 days')
    )
  GROUP BY r.id, r.title, r.description, r.budget_min, r.budget_max, 
           r.deadline, r.is_urgent, r.created_at, h.city, h.county
  ORDER BY r.created_at DESC;
END;
$$ LANGUAGE plpgsql STABLE;

-- STEP 8: CREATE TRIGGERS
-- ===================================================================

-- Updated at triggers
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_homes_updated_at BEFORE UPDATE ON public.homes 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_rfqs_updated_at BEFORE UPDATE ON public.rfqs 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_offers_updated_at BEFORE UPDATE ON public.offers 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_firms_updated_at BEFORE UPDATE ON public.firms 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_firm_users_updated_at BEFORE UPDATE ON public.firm_users 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_firm_settings_updated_at BEFORE UPDATE ON public.firm_settings 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Validate manufacturer offers trigger
CREATE TRIGGER validate_manufacturer_offer_trigger
  BEFORE INSERT OR UPDATE ON public.offers
  FOR EACH ROW EXECUTE FUNCTION validate_manufacturer_offer();

-- Handle new user trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Update user last login trigger
CREATE TRIGGER on_auth_user_login
  AFTER UPDATE OF last_sign_in_at ON auth.users
  FOR EACH ROW 
  WHEN (OLD.last_sign_in_at IS DISTINCT FROM NEW.last_sign_in_at)
  EXECUTE FUNCTION public.update_user_last_login();

-- STEP 9: INSERT DEFAULT DATA
-- ===================================================================

-- Insert default categories
INSERT INTO public.categories (name, name_ro, description_ro, icon, sort_order) VALUES
  ('kitchen', 'Bucătărie', 'Mobilier pentru bucătărie - corpuri, fronturi, blat', 'UtensilsCrossed', 1),
  ('hallway', 'Hol', 'Mobilier pentru hol - cuiere, pantofare, console', 'Home', 2),
  ('bedroom', 'Dormitor', 'Mobilier pentru dormitor - paturi, noptiere, comode', 'Bed', 3),
  ('living', 'Living', 'Mobilier pentru living - canapele, mese, biblioteci', 'Sofa', 4),
  ('bathroom', 'Baie', 'Mobilier pentru baie - dulapuri, oglinzi, rafturi', 'Bath', 5),
  ('office', 'Birou', 'Mobilier pentru birou - birouri, scaune, rafturi', 'Briefcase', 6),
  ('dressing', 'Dressing', 'Mobilier pentru dressing - dulapuri, rafturi, organizatoare', 'Shirt', 7),
  ('wardrobe', 'Dulap', 'Dulapuri pentru diverse camere', 'DoorOpen', 8),
  ('outdoor', 'Exterior', 'Mobilier pentru exterior - mese, scaune, pergole', 'TreePine', 9);

-- STEP 10: ENABLE ROW LEVEL SECURITY
-- ===================================================================

-- Enable RLS on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.homes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rfqs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rfq_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rfq_answers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.files ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.offers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.firms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.firm_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.firm_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rfq_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.firm_sessions ENABLE ROW LEVEL SECURITY;

-- STEP 11: CREATE ROW LEVEL SECURITY POLICIES
-- ===================================================================

-- Users table policies
CREATE POLICY "Users can view their own profile" ON public.users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON public.users
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Authenticated users can insert their profile" ON public.users
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Homes table policies
CREATE POLICY "Users can view their own homes" ON public.homes
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can manage their own homes" ON public.homes
  FOR ALL USING (auth.uid() = user_id);

-- Categories table policies (public read)
CREATE POLICY "Anyone can view categories" ON public.categories
  FOR SELECT USING (true);

-- RFQs table policies
CREATE POLICY "Users can view their own RFQs" ON public.rfqs
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Manufacturers can view active RFQs" ON public.rfqs
  FOR SELECT USING (
    status = 'active' AND 
    EXISTS (
      SELECT 1 FROM public.users 
      WHERE id = auth.uid() AND role = 'manufacturer'
    )
  );

CREATE POLICY "Users can manage their own RFQs" ON public.rfqs
  FOR ALL USING (auth.uid() = user_id);

-- Offers table policies
CREATE POLICY "Users can view offers for their RFQs" ON public.offers
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.rfqs 
      WHERE id = offers.rfq_id AND user_id = auth.uid()
    )
  );

CREATE POLICY "Manufacturers can view their own offers" ON public.offers
  FOR SELECT USING (auth.uid() = manufacturer_id);

CREATE POLICY "Manufacturers can create offers" ON public.offers
  FOR INSERT WITH CHECK (
    auth.uid() = manufacturer_id AND
    EXISTS (
      SELECT 1 FROM public.users 
      WHERE id = auth.uid() AND role = 'manufacturer'
    )
  );

CREATE POLICY "Manufacturers can update their own offers" ON public.offers
  FOR UPDATE USING (auth.uid() = manufacturer_id);

-- Firm system policies (using service role for now)
-- These will be managed through the API routes with custom authentication

-- STEP 12: GRANT PERMISSIONS
-- ===================================================================

-- Grant usage on schema
GRANT USAGE ON SCHEMA public TO anon, authenticated;

-- Grant permissions on tables
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated;

-- ===================================================================
-- SETUP COMPLETE!
-- ===================================================================
-- The database is now ready for use with both the main system and firm portal 