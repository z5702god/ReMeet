-- =====================================================
-- SECURITY FIXES MIGRATION
-- Date: 2026-01-15
-- =====================================================

-- =====================================================
-- 1. FIX COMPANIES TABLE RLS POLICIES
-- Problem: Any authenticated user can update any company
-- Solution: Only allow updates by the user who created the contact
-- =====================================================

-- First, drop the overly permissive policies
DROP POLICY IF EXISTS "Authenticated users can update companies" ON public.companies;

-- Add created_by column to track who created the company (if not exists)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'companies' AND column_name = 'created_by'
    ) THEN
        ALTER TABLE public.companies ADD COLUMN created_by UUID REFERENCES auth.users(id);
    END IF;
END $$;

-- Create new policy: Users can only update companies they created
CREATE POLICY "Users can update own companies"
    ON public.companies FOR UPDATE
    TO authenticated
    USING (created_by = auth.uid() OR created_by IS NULL)
    WITH CHECK (created_by = auth.uid() OR created_by IS NULL);

-- Create policy for insert that sets created_by
DROP POLICY IF EXISTS "Authenticated users can create companies" ON public.companies;

CREATE POLICY "Authenticated users can create companies"
    ON public.companies FOR INSERT
    TO authenticated
    WITH CHECK (created_by = auth.uid() OR created_by IS NULL);

-- =====================================================
-- 2. ADD SECURITY DEFINER SEARCH PATH TO FUNCTIONS
-- Problem: SECURITY DEFINER functions without search_path
-- Solution: Set search_path to prevent schema injection
-- =====================================================

-- First, drop existing functions to allow return type changes
DROP FUNCTION IF EXISTS search_contacts(TEXT, UUID);
DROP FUNCTION IF EXISTS get_company_stats(UUID);
DROP FUNCTION IF EXISTS get_meeting_timeline(UUID, DATE, DATE);

-- Update search_contacts function
CREATE OR REPLACE FUNCTION search_contacts(search_query TEXT, user_uuid UUID)
RETURNS SETOF contacts AS $$
BEGIN
    RETURN QUERY
    SELECT c.*
    FROM contacts c
    LEFT JOIN companies co ON c.company_id = co.id
    WHERE c.user_id = user_uuid
    AND (
        c.full_name ILIKE '%' || search_query || '%'
        OR c.email ILIKE '%' || search_query || '%'
        OR c.phone ILIKE '%' || search_query || '%'
        OR co.name ILIKE '%' || search_query || '%'
        OR c.notes ILIKE '%' || search_query || '%'
    )
    ORDER BY c.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public;

-- Update get_company_stats function
CREATE OR REPLACE FUNCTION get_company_stats(user_uuid UUID)
RETURNS TABLE (
    id UUID,
    name TEXT,
    industry TEXT,
    logo_url TEXT,
    website TEXT,
    contact_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        co.id,
        co.name,
        co.industry,
        co.logo_url,
        co.website,
        COUNT(c.id) as contact_count
    FROM companies co
    INNER JOIN contacts c ON c.company_id = co.id
    WHERE c.user_id = user_uuid
    GROUP BY co.id
    ORDER BY contact_count DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public;

-- Update get_meeting_timeline function
CREATE OR REPLACE FUNCTION get_meeting_timeline(
    user_uuid UUID,
    start_date DATE DEFAULT NULL,
    end_date DATE DEFAULT NULL
)
RETURNS TABLE (
    id UUID,
    contact_id UUID,
    contact_name TEXT,
    company_name TEXT,
    meeting_date DATE,
    location_name TEXT,
    event_name TEXT,
    occasion_type TEXT,
    relationship_type TEXT,
    notes TEXT,
    follow_up_required BOOLEAN,
    follow_up_date DATE
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        mc.id,
        mc.contact_id,
        c.full_name as contact_name,
        co.name as company_name,
        mc.meeting_date,
        mc.location_name,
        mc.event_name,
        mc.occasion_type,
        mc.relationship_type,
        mc.notes,
        mc.follow_up_required,
        mc.follow_up_date
    FROM meeting_contexts mc
    INNER JOIN contacts c ON mc.contact_id = c.id
    LEFT JOIN companies co ON c.company_id = co.id
    WHERE mc.user_id = user_uuid
    AND (start_date IS NULL OR mc.meeting_date >= start_date)
    AND (end_date IS NULL OR mc.meeting_date <= end_date)
    ORDER BY mc.meeting_date DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public;

-- =====================================================
-- 3. ADD RATE LIMITING FUNCTION (for future use)
-- =====================================================

-- Create a simple rate limiting table
CREATE TABLE IF NOT EXISTS rate_limits (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL,
    action_type TEXT NOT NULL,
    window_start TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    request_count INTEGER NOT NULL DEFAULT 1,
    UNIQUE(user_id, action_type, window_start)
);

-- Enable RLS
ALTER TABLE rate_limits ENABLE ROW LEVEL SECURITY;

-- Rate limit policy
CREATE POLICY "Users can only see own rate limits"
    ON rate_limits FOR ALL
    TO authenticated
    USING (user_id = auth.uid());

-- Function to check rate limit
CREATE OR REPLACE FUNCTION check_rate_limit(
    p_user_id UUID,
    p_action TEXT,
    p_max_requests INTEGER DEFAULT 100,
    p_window_minutes INTEGER DEFAULT 60
)
RETURNS BOOLEAN AS $$
DECLARE
    v_count INTEGER;
    v_window_start TIMESTAMPTZ;
BEGIN
    v_window_start := date_trunc('hour', NOW());

    SELECT COALESCE(SUM(request_count), 0) INTO v_count
    FROM rate_limits
    WHERE user_id = p_user_id
    AND action_type = p_action
    AND window_start >= NOW() - (p_window_minutes || ' minutes')::INTERVAL;

    IF v_count >= p_max_requests THEN
        RETURN FALSE;
    END IF;

    -- Increment or insert
    INSERT INTO rate_limits (user_id, action_type, window_start, request_count)
    VALUES (p_user_id, p_action, v_window_start, 1)
    ON CONFLICT (user_id, action_type, window_start)
    DO UPDATE SET request_count = rate_limits.request_count + 1;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public;

-- =====================================================
-- 4. CLEANUP OLD RATE LIMIT RECORDS (scheduled job)
-- =====================================================

CREATE OR REPLACE FUNCTION cleanup_old_rate_limits()
RETURNS void AS $$
BEGIN
    DELETE FROM rate_limits
    WHERE window_start < NOW() - INTERVAL '24 hours';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public;

-- =====================================================
-- COMMENTS
-- =====================================================
COMMENT ON FUNCTION check_rate_limit IS 'Check if user has exceeded rate limit for an action';
COMMENT ON FUNCTION cleanup_old_rate_limits IS 'Clean up rate limit records older than 24 hours';
COMMENT ON TABLE rate_limits IS 'Track API request rates per user for rate limiting';
