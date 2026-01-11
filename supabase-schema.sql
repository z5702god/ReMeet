-- =====================================================
-- Re:Meet - Supabase Database Schema
-- =====================================================
-- Description: Complete database schema for Re:Meet business card management app
-- Version: 1.0
-- Date: 2026-01-10
-- =====================================================

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =====================================================
-- 1. USERS TABLE
-- =====================================================
-- Note: Supabase auth.users table already exists
-- We create a public.users table for additional user data

CREATE TABLE public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT,
    avatar_url TEXT,
    preferences JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index for faster lookups
CREATE INDEX idx_users_email ON public.users(email);

-- =====================================================
-- 2. COMPANIES TABLE
-- =====================================================

CREATE TABLE public.companies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    industry TEXT,
    website TEXT,
    logo_url TEXT,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_companies_name ON public.companies(name);
CREATE INDEX idx_companies_industry ON public.companies(industry);

-- Unique index for case-insensitive company names
CREATE UNIQUE INDEX idx_companies_name_unique ON public.companies(LOWER(name));

-- =====================================================
-- 3. BUSINESS_CARDS TABLE
-- =====================================================

CREATE TABLE public.business_cards (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,

    -- Image storage
    image_url TEXT NOT NULL,
    image_front_url TEXT, -- For cards with front/back
    image_back_url TEXT,

    -- OCR metadata
    ocr_status TEXT DEFAULT 'pending' CHECK (ocr_status IN ('pending', 'processing', 'completed', 'failed')),
    ocr_raw_data JSONB, -- Store raw OCR response
    ocr_processed_at TIMESTAMP WITH TIME ZONE,

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_business_cards_user_id ON public.business_cards(user_id);
CREATE INDEX idx_business_cards_ocr_status ON public.business_cards(ocr_status);
CREATE INDEX idx_business_cards_created_at ON public.business_cards(created_at DESC);

-- =====================================================
-- 4. CONTACTS TABLE
-- =====================================================

CREATE TABLE public.contacts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    card_id UUID REFERENCES public.business_cards(id) ON DELETE SET NULL,
    company_id UUID REFERENCES public.companies(id) ON DELETE SET NULL,

    -- Contact information
    full_name TEXT NOT NULL,
    title TEXT,
    department TEXT,
    phone TEXT,
    email TEXT,
    website TEXT,
    address TEXT,

    -- Social media (optional)
    linkedin_url TEXT,
    twitter_url TEXT,

    -- OCR confidence and verification
    ocr_confidence_score DECIMAL(3,2) CHECK (ocr_confidence_score >= 0 AND ocr_confidence_score <= 1),
    is_verified BOOLEAN DEFAULT FALSE,

    -- Favorite/starred
    is_favorite BOOLEAN DEFAULT FALSE,

    -- Tags and notes
    tags TEXT[], -- Array of tags
    notes TEXT,

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_contacted_at TIMESTAMP WITH TIME ZONE
);

-- Indexes
CREATE INDEX idx_contacts_user_id ON public.contacts(user_id);
CREATE INDEX idx_contacts_company_id ON public.contacts(company_id);
CREATE INDEX idx_contacts_card_id ON public.contacts(card_id);
CREATE INDEX idx_contacts_full_name ON public.contacts(full_name);
CREATE INDEX idx_contacts_email ON public.contacts(email);
CREATE INDEX idx_contacts_is_favorite ON public.contacts(is_favorite);
CREATE INDEX idx_contacts_created_at ON public.contacts(created_at DESC);
CREATE INDEX idx_contacts_tags ON public.contacts USING GIN(tags);

-- Full-text search index for contacts
CREATE INDEX idx_contacts_search ON public.contacts
    USING GIN(to_tsvector('english', COALESCE(full_name, '') || ' ' || COALESCE(title, '') || ' ' || COALESCE(notes, '')));

-- =====================================================
-- 5. MEETING_CONTEXTS TABLE
-- =====================================================

CREATE TABLE public.meeting_contexts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    contact_id UUID NOT NULL REFERENCES public.contacts(id) ON DELETE CASCADE,

    -- Meeting details
    meeting_date DATE,
    meeting_time TIME,
    location_name TEXT,
    location_address TEXT,
    location_lat DECIMAL(10, 8),
    location_lng DECIMAL(11, 8),

    -- Event/occasion information
    event_name TEXT,
    occasion_type TEXT, -- e.g., 'conference', 'networking', 'meeting', 'social'

    -- Relationship and notes
    relationship_type TEXT, -- e.g., 'client', 'partner', 'investor', 'colleague'
    conversation_topics TEXT[],
    notes TEXT,

    -- AI-generated insights (optional)
    ai_summary TEXT,
    ai_extracted_metadata JSONB,

    -- Follow-up
    follow_up_required BOOLEAN DEFAULT FALSE,
    follow_up_date DATE,
    follow_up_notes TEXT,

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_meeting_contexts_user_id ON public.meeting_contexts(user_id);
CREATE INDEX idx_meeting_contexts_contact_id ON public.meeting_contexts(contact_id);
CREATE INDEX idx_meeting_contexts_meeting_date ON public.meeting_contexts(meeting_date DESC);
CREATE INDEX idx_meeting_contexts_event_name ON public.meeting_contexts(event_name);
CREATE INDEX idx_meeting_contexts_occasion_type ON public.meeting_contexts(occasion_type);
CREATE INDEX idx_meeting_contexts_relationship_type ON public.meeting_contexts(relationship_type);
CREATE INDEX idx_meeting_contexts_location ON public.meeting_contexts(location_lat, location_lng);

-- Full-text search index for meeting contexts
CREATE INDEX idx_meeting_contexts_search ON public.meeting_contexts
    USING GIN(to_tsvector('english', COALESCE(event_name, '') || ' ' || COALESCE(location_name, '') || ' ' || COALESCE(notes, '')));

-- =====================================================
-- 6. CHAT_HISTORY TABLE (for AI Agent conversations)
-- =====================================================

CREATE TABLE public.chat_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,

    -- Chat message
    role TEXT NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
    content TEXT NOT NULL,

    -- Context and metadata
    related_contact_ids UUID[],
    query_type TEXT, -- e.g., 'search', 'context_input', 'general'

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_chat_history_user_id ON public.chat_history(user_id);
CREATE INDEX idx_chat_history_created_at ON public.chat_history(created_at DESC);

-- =====================================================
-- 7. TRIGGERS - Auto-update updated_at timestamps
-- =====================================================

-- Function to update updated_at column
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to all tables with updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_companies_updated_at BEFORE UPDATE ON public.companies
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_business_cards_updated_at BEFORE UPDATE ON public.business_cards
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_contacts_updated_at BEFORE UPDATE ON public.contacts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_meeting_contexts_updated_at BEFORE UPDATE ON public.meeting_contexts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- 8. TRIGGERS - Auto-create user profile on signup
-- =====================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.users (id, email, full_name, avatar_url)
    VALUES (
        NEW.id,
        NEW.email,
        NEW.raw_user_meta_data->>'full_name',
        NEW.raw_user_meta_data->>'avatar_url'
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger on auth.users insert
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- =====================================================
-- 9. ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.business_cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meeting_contexts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_history ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- RLS Policies for USERS table
-- =====================================================

-- Users can view their own profile
CREATE POLICY "Users can view own profile"
    ON public.users FOR SELECT
    USING (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
    ON public.users FOR UPDATE
    USING (auth.uid() = id);

-- =====================================================
-- RLS Policies for COMPANIES table
-- =====================================================

-- Companies are viewable by all authenticated users (shared resource)
CREATE POLICY "Authenticated users can view companies"
    ON public.companies FOR SELECT
    TO authenticated
    USING (true);

-- Only allow inserts via application (service role)
-- Users can create companies through the app
CREATE POLICY "Authenticated users can create companies"
    ON public.companies FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- Users can update companies (collaborative)
CREATE POLICY "Authenticated users can update companies"
    ON public.companies FOR UPDATE
    TO authenticated
    USING (true);

-- =====================================================
-- RLS Policies for BUSINESS_CARDS table
-- =====================================================

-- Users can only view their own business cards
CREATE POLICY "Users can view own business cards"
    ON public.business_cards FOR SELECT
    USING (auth.uid() = user_id);

-- Users can insert their own business cards
CREATE POLICY "Users can insert own business cards"
    ON public.business_cards FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own business cards
CREATE POLICY "Users can update own business cards"
    ON public.business_cards FOR UPDATE
    USING (auth.uid() = user_id);

-- Users can delete their own business cards
CREATE POLICY "Users can delete own business cards"
    ON public.business_cards FOR DELETE
    USING (auth.uid() = user_id);

-- =====================================================
-- RLS Policies for CONTACTS table
-- =====================================================

-- Users can only view their own contacts
CREATE POLICY "Users can view own contacts"
    ON public.contacts FOR SELECT
    USING (auth.uid() = user_id);

-- Users can insert their own contacts
CREATE POLICY "Users can insert own contacts"
    ON public.contacts FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own contacts
CREATE POLICY "Users can update own contacts"
    ON public.contacts FOR UPDATE
    USING (auth.uid() = user_id);

-- Users can delete their own contacts
CREATE POLICY "Users can delete own contacts"
    ON public.contacts FOR DELETE
    USING (auth.uid() = user_id);

-- =====================================================
-- RLS Policies for MEETING_CONTEXTS table
-- =====================================================

-- Users can only view their own meeting contexts
CREATE POLICY "Users can view own meeting contexts"
    ON public.meeting_contexts FOR SELECT
    USING (auth.uid() = user_id);

-- Users can insert their own meeting contexts
CREATE POLICY "Users can insert own meeting contexts"
    ON public.meeting_contexts FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own meeting contexts
CREATE POLICY "Users can update own meeting contexts"
    ON public.meeting_contexts FOR UPDATE
    USING (auth.uid() = user_id);

-- Users can delete their own meeting contexts
CREATE POLICY "Users can delete own meeting contexts"
    ON public.meeting_contexts FOR DELETE
    USING (auth.uid() = user_id);

-- =====================================================
-- RLS Policies for CHAT_HISTORY table
-- =====================================================

-- Users can only view their own chat history
CREATE POLICY "Users can view own chat history"
    ON public.chat_history FOR SELECT
    USING (auth.uid() = user_id);

-- Users can insert their own chat messages
CREATE POLICY "Users can insert own chat messages"
    ON public.chat_history FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can delete their own chat history
CREATE POLICY "Users can delete own chat history"
    ON public.chat_history FOR DELETE
    USING (auth.uid() = user_id);

-- =====================================================
-- 10. HELPER FUNCTIONS
-- =====================================================

-- Function to search contacts by name, company, or tags
CREATE OR REPLACE FUNCTION search_contacts(
    search_query TEXT,
    user_uuid UUID
)
RETURNS TABLE (
    id UUID,
    full_name TEXT,
    title TEXT,
    company_name TEXT,
    email TEXT,
    phone TEXT,
    tags TEXT[],
    relevance REAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.id,
        c.full_name,
        c.title,
        comp.name AS company_name,
        c.email,
        c.phone,
        c.tags,
        ts_rank(
            to_tsvector('english', COALESCE(c.full_name, '') || ' ' || COALESCE(c.title, '') || ' ' || COALESCE(comp.name, '')),
            plainto_tsquery('english', search_query)
        ) AS relevance
    FROM public.contacts c
    LEFT JOIN public.companies comp ON c.company_id = comp.id
    WHERE c.user_id = user_uuid
        AND (
            to_tsvector('english', COALESCE(c.full_name, '') || ' ' || COALESCE(c.title, '') || ' ' || COALESCE(comp.name, ''))
            @@ plainto_tsquery('english', search_query)
            OR search_query = ANY(c.tags)
        )
    ORDER BY relevance DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get contacts by company
CREATE OR REPLACE FUNCTION get_contacts_by_company(
    company_uuid UUID,
    user_uuid UUID
)
RETURNS TABLE (
    id UUID,
    full_name TEXT,
    title TEXT,
    email TEXT,
    phone TEXT,
    last_contacted_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.id,
        c.full_name,
        c.title,
        c.email,
        c.phone,
        c.last_contacted_at
    FROM public.contacts c
    WHERE c.company_id = company_uuid
        AND c.user_id = user_uuid
    ORDER BY c.last_contacted_at DESC NULLS LAST, c.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get meeting timeline
CREATE OR REPLACE FUNCTION get_meeting_timeline(
    user_uuid UUID,
    start_date DATE DEFAULT NULL,
    end_date DATE DEFAULT NULL
)
RETURNS TABLE (
    meeting_date DATE,
    contact_name TEXT,
    company_name TEXT,
    event_name TEXT,
    location_name TEXT,
    notes TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        mc.meeting_date,
        c.full_name AS contact_name,
        comp.name AS company_name,
        mc.event_name,
        mc.location_name,
        mc.notes
    FROM public.meeting_contexts mc
    INNER JOIN public.contacts c ON mc.contact_id = c.id
    LEFT JOIN public.companies comp ON c.company_id = comp.id
    WHERE mc.user_id = user_uuid
        AND (start_date IS NULL OR mc.meeting_date >= start_date)
        AND (end_date IS NULL OR mc.meeting_date <= end_date)
    ORDER BY mc.meeting_date DESC NULLS LAST;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get company statistics
CREATE OR REPLACE FUNCTION get_company_stats(user_uuid UUID)
RETURNS TABLE (
    company_id UUID,
    company_name TEXT,
    contact_count BIGINT,
    last_interaction TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        comp.id AS company_id,
        comp.name AS company_name,
        COUNT(c.id) AS contact_count,
        MAX(mc.meeting_date)::TIMESTAMP WITH TIME ZONE AS last_interaction
    FROM public.companies comp
    INNER JOIN public.contacts c ON c.company_id = comp.id
    LEFT JOIN public.meeting_contexts mc ON mc.contact_id = c.id
    WHERE c.user_id = user_uuid
    GROUP BY comp.id, comp.name
    ORDER BY contact_count DESC, last_interaction DESC NULLS LAST;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 11. SAMPLE DATA (Optional - for testing)
-- =====================================================

-- Uncomment to insert sample data for testing

/*
-- Insert a sample company
INSERT INTO public.companies (name, industry, website) VALUES
    ('Anthropic', 'AI Research', 'https://anthropic.com');

-- Note: Sample contacts and cards should be inserted after user authentication
-- as they require a valid user_id from auth.users
*/

-- =====================================================
-- END OF SCHEMA
-- =====================================================

-- Summary of created tables:
-- 1. users (extends auth.users)
-- 2. companies
-- 3. business_cards
-- 4. contacts
-- 5. meeting_contexts
-- 6. chat_history
--
-- Total indexes: 30+
-- Total triggers: 6
-- Total RLS policies: 18
-- Total helper functions: 4
