-- ===================================================================
-- FIX DATABASE FUNCTIONS
-- ===================================================================
-- This script fixes search path and security invoker issues in functions
-- ===================================================================

-- Drop existing functions
DROP FUNCTION IF EXISTS public.update_updated_at_column() CASCADE;
DROP FUNCTION IF EXISTS public.validate_manufacturer_offer() CASCADE;
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS public.update_user_last_login() CASCADE;
DROP FUNCTION IF EXISTS public.get_filtered_rfqs(uuid, text[], text[], numeric, numeric, text) CASCADE;

-- Recreate functions with proper search path and security settings

-- Updated at trigger function
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

-- Validate manufacturer offers function
CREATE OR REPLACE FUNCTION public.validate_manufacturer_offer()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.users 
    WHERE id = NEW.manufacturer_id AND role = 'manufacturer'
  ) THEN
    RAISE EXCEPTION 'Only users with manufacturer role can create offers';
  END IF;
  
  RETURN NEW;
END;
$$;

-- Handle new user function
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
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
$$;

-- Update user last login function
CREATE OR REPLACE FUNCTION public.update_user_last_login()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.users 
  SET last_login = NOW()
  WHERE id = NEW.id;
  RETURN NEW;
END;
$$;

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
)
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
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
$$;

-- Recreate triggers
CREATE TRIGGER update_users_updated_at 
  BEFORE UPDATE ON public.users 
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_homes_updated_at 
  BEFORE UPDATE ON public.homes 
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_rfqs_updated_at 
  BEFORE UPDATE ON public.rfqs 
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_offers_updated_at 
  BEFORE UPDATE ON public.offers 
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_firms_updated_at 
  BEFORE UPDATE ON public.firms 
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_firm_users_updated_at 
  BEFORE UPDATE ON public.firm_users 
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_firm_settings_updated_at 
  BEFORE UPDATE ON public.firm_settings 
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER validate_manufacturer_offer_trigger
  BEFORE INSERT OR UPDATE ON public.offers
  FOR EACH ROW EXECUTE FUNCTION public.validate_manufacturer_offer();

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

CREATE TRIGGER on_auth_user_login
  AFTER UPDATE OF last_sign_in_at ON auth.users
  FOR EACH ROW 
  WHEN (OLD.last_sign_in_at IS DISTINCT FROM NEW.last_sign_in_at)
  EXECUTE FUNCTION public.update_user_last_login(); 