    -- ===================================================================
    -- FIX REMAINING DATABASE FUNCTIONS
    -- ===================================================================
    -- This script fixes search path issues in the remaining functions
    -- ===================================================================

    -- Drop existing functions
    DROP FUNCTION IF EXISTS public.get_firm_rfqs(UUID, TEXT, INTEGER, INTEGER) CASCADE;
    DROP FUNCTION IF EXISTS public.redeem_rfq() CASCADE;

    -- Recreate get_firm_rfqs function with proper search path
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

    -- Recreate redeem_rfq function with proper search path
    CREATE OR REPLACE FUNCTION public.redeem_rfq()
    RETURNS TRIGGER
    LANGUAGE plpgsql
    SECURITY INVOKER
    SET search_path = public
    AS $$
    DECLARE
    v_firm_id UUID;
    v_firm_user_id UUID;
    BEGIN
    -- Get firm and user IDs
    SELECT firm_id, firm_user_id INTO v_firm_id, v_firm_user_id
    FROM public.rfq_assignments
    WHERE rfq_id = NEW.rfq_id
    LIMIT 1;

    -- Update assignment status
    UPDATE public.rfq_assignments
    SET 
        status = 'completed',
        completed_at = NOW()
    WHERE rfq_id = NEW.rfq_id
        AND firm_id = v_firm_id;

    -- Update RFQ status
    UPDATE public.rfqs
    SET 
        status = 'completed',
        completed_at = NOW()
    WHERE id = NEW.rfq_id;

    RETURN NEW;
    END;
    $$; 