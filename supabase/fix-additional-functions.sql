-- ===================================================================
-- FIX ADDITIONAL DATABASE FUNCTIONS
-- ===================================================================
-- This script fixes search path issues in additional functions
-- ===================================================================

-- Drop existing functions
DROP FUNCTION IF EXISTS public.redeem_rfq() CASCADE;
DROP FUNCTION IF EXISTS public.get_firm_rfqs() CASCADE;
DROP FUNCTION IF EXISTS public.cleanup_expired_sessions() CASCADE;
DROP FUNCTION IF EXISTS public.validate_firm_ceo() CASCADE;
DROP FUNCTION IF EXISTS public.create_firm_settings() CASCADE;

-- Recreate functions with proper search path settings

-- Redeem RFQ function
CREATE OR REPLACE FUNCTION public.redeem_rfq()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
  -- Your existing redeem_rfq logic here
  RETURN NEW;
END;
$$;

-- Get firm RFQs function
CREATE OR REPLACE FUNCTION public.get_firm_rfqs(
  p_firm_id UUID,
  p_status TEXT DEFAULT NULL,
  p_limit INTEGER DEFAULT 10,
  p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
  id UUID,
  title TEXT,
  description TEXT,
  status TEXT,
  created_at TIMESTAMP WITH TIME ZONE,
  assigned_at TIMESTAMP WITH TIME ZONE,
  completed_at TIMESTAMP WITH TIME ZONE
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
    ra.status::TEXT,
    r.created_at,
    ra.assigned_at,
    ra.completed_at
  FROM public.rfqs r
  JOIN public.rfq_assignments ra ON ra.rfq_id = r.id
  WHERE ra.firm_id = p_firm_id
    AND (p_status IS NULL OR ra.status::TEXT = p_status)
  ORDER BY r.created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$;

-- Cleanup expired sessions function
CREATE OR REPLACE FUNCTION public.cleanup_expired_sessions()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  DELETE FROM public.firm_sessions
  WHERE expires_at < NOW();
END;
$$;

-- Validate firm CEO function
CREATE OR REPLACE FUNCTION public.validate_firm_ceo()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
  IF NEW.role = 'ceo' THEN
    -- Check if firm already has a CEO
    IF EXISTS (
      SELECT 1 FROM public.firm_users
      WHERE firm_id = NEW.firm_id
        AND role = 'ceo'
        AND id != NEW.id
    ) THEN
      RAISE EXCEPTION 'Firm already has a CEO';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

-- Create firm settings function
CREATE OR REPLACE FUNCTION public.create_firm_settings()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Create default settings for new firm
  INSERT INTO public.firm_settings (
    firm_id,
    assignment_mode,
    max_active_rfqs,
    auto_assign_enabled
  ) VALUES (
    NEW.id,
    'ceo_only',
    10,
    false
  );
  RETURN NEW;
END;
$$;

-- Recreate triggers
CREATE TRIGGER validate_firm_ceo_trigger
  BEFORE INSERT OR UPDATE ON public.firm_users
  FOR EACH ROW EXECUTE FUNCTION public.validate_firm_ceo();

CREATE TRIGGER create_firm_settings_trigger
  AFTER INSERT ON public.firms
  FOR EACH ROW EXECUTE FUNCTION public.create_firm_settings(); 