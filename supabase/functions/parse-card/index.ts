// Supabase Edge Function: parse-card
// Uses GPT-4o-mini to intelligently parse business card OCR text into structured fields
// Replaces naive heuristic parsing with AI-based field extraction

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const OPENAI_API_URL = "https://api.openai.com/v1/chat/completions"

const SYSTEM_PROMPT = `You are a business card OCR text parser. Given raw OCR text from a business card, extract structured contact information.

Rules:
- Distinguish brand/logo text from the formal company name. Logo text (e.g. "ILITEK") is NOT the company name if a formal name like "ILI TECHNOLOGY CORP." exists.
- Formal company names often include: Corp., Inc., Ltd., Co., LLC, 股份有限公司, 有限公司, etc.
- "Marketing Division III", "Business Development Center", "R&D Department" are departments, NOT company names.
- Job titles include: Director, Manager, Engineer, VP, CEO, CTO, 經理, 總監, 工程師, etc.
- The person's name is usually 2-4 words (English) or 2-3 characters (Chinese).
- If multiple phone numbers exist, pick the mobile one. Include country code and extension if present.
- For address, combine all address-related lines into one string.
- If a field cannot be determined, set it to null.

Output ONLY valid JSON, no other text:
{
  "fullName": "person's full name",
  "title": "job title",
  "department": "department name or null",
  "company": "formal company name",
  "phone": "phone number with country code",
  "email": "email address",
  "website": "website URL",
  "address": "full address"
}`

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Verify authentication
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Missing authorization header' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY')!

    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    })

    const { data: { user }, error: userError } = await supabase.auth.getUser()
    if (userError || !user) {
      return new Response(
        JSON.stringify({ error: 'User not authenticated' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Get OpenAI API key
    const openaiApiKey = Deno.env.get('OPENAI_API_KEY')
    if (!openaiApiKey) {
      console.error('OPENAI_API_KEY not configured')
      return new Response(
        JSON.stringify({ error: 'AI parsing service not configured' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Parse request body
    const body = await req.json()
    const { text } = body

    if (!text || text.trim().length === 0) {
      return new Response(
        JSON.stringify({ error: 'Missing OCR text' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Call OpenAI GPT-4o-mini
    const openaiResponse = await fetch(OPENAI_API_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${openaiApiKey}`,
      },
      body: JSON.stringify({
        model: 'gpt-4o-mini',
        messages: [
          { role: 'system', content: SYSTEM_PROMPT },
          { role: 'user', content: `Parse this business card OCR text:\n\n${text}` }
        ],
        temperature: 0,
        max_tokens: 500,
      })
    })

    if (!openaiResponse.ok) {
      const errorData = await openaiResponse.json()
      console.error('OpenAI API error:', errorData)
      return new Response(
        JSON.stringify({ error: 'AI parsing failed', details: errorData.error?.message }),
        { status: 502, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const openaiData = await openaiResponse.json()
    const content = openaiData.choices?.[0]?.message?.content || '{}'

    // Parse the JSON response from GPT
    let parsed
    try {
      // Remove markdown code fences if present
      const cleanContent = content.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim()
      parsed = JSON.parse(cleanContent)
    } catch {
      console.error('Failed to parse GPT response:', content)
      parsed = {}
    }

    return new Response(
      JSON.stringify({
        success: true,
        parsed: {
          fullName: parsed.fullName || null,
          title: parsed.title || null,
          department: parsed.department || null,
          company: parsed.company || null,
          phone: parsed.phone || null,
          email: parsed.email || null,
          website: parsed.website || null,
          address: parsed.address || null,
        }
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Parse card error:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error', message: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
