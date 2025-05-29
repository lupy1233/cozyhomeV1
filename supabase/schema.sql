-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create custom types
CREATE TYPE user_role AS ENUM ('homeowner', 'architect', 'manufacturer', 'admin');
CREATE TYPE account_status AS ENUM ('active', 'inactive', 'pending', 'suspended');
CREATE TYPE rfq_status AS ENUM ('draft', 'active', 'closed', 'expired', 'completed');
CREATE TYPE offer_status AS ENUM ('pending', 'accepted', 'rejected', 'withdrawn');
CREATE TYPE message_status AS ENUM ('sent', 'delivered', 'read');

-- Users table (extends Supabase auth.users)
CREATE TABLE public.users (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  first_name TEXT,
  last_name TEXT,
  phone TEXT,
  role user_role NOT NULL DEFAULT 'homeowner',
  status account_status NOT NULL DEFAULT 'active',
  company_name TEXT, -- For manufacturers
  company_description TEXT,
  company_website TEXT,
  company_address TEXT,
  company_phone TEXT,
  tax_id TEXT, -- CUI for Romanian companies
  is_verified BOOLEAN DEFAULT FALSE,
  avatar_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_login TIMESTAMP WITH TIME ZONE,
  
  -- Manufacturer specific fields
  manufacturer_parent_id UUID REFERENCES public.users(id), -- For sub-accounts
  
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

-- RFQs (Request for Quotes) table
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

-- RFQ Categories junction table (many-to-many)
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

-- RFQ Questions and Answers
CREATE TABLE public.rfq_answers (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  rfq_id UUID REFERENCES public.rfqs(id) ON DELETE CASCADE NOT NULL,
  category_id UUID REFERENCES public.categories(id) ON DELETE CASCADE,
  question_key TEXT NOT NULL,
  question_text TEXT NOT NULL,
  answer_value TEXT,
  answer_data JSONB, -- For complex answers (measurements, selections, etc.)
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- File uploads table
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
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT valid_manufacturer CHECK (
    manufacturer_id IN (
      SELECT id FROM public.users WHERE role = 'manufacturer'
    )
  )
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

-- Create indexes for better performance
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

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_homes_updated_at BEFORE UPDATE ON public.homes FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_rfqs_updated_at BEFORE UPDATE ON public.rfqs FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_offers_updated_at BEFORE UPDATE ON public.offers FOR EACH ROW EXECUTE FUNCTION update_updated_at_column(); 