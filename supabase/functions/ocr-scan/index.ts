// Supabase Edge Function: ocr-scan
// Proxies Google Cloud Vision API requests to keep API key server-side
// This prevents exposure of the Google API key in the iOS app binary

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// Google Cloud Vision API endpoint
const VISION_API_URL = "https://vision.googleapis.com/v1/images:annotate"

serve(async (req) => {
  // Handle CORS preflight request
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

    // Verify the user is authenticated using Supabase
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

    // Get Google API key from environment (stored as Supabase secret)
    const googleApiKey = Deno.env.get('GOOGLE_CLOUD_VISION_API_KEY')
    if (!googleApiKey) {
      console.error('GOOGLE_CLOUD_VISION_API_KEY not configured')
      return new Response(
        JSON.stringify({ error: 'OCR service not configured' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Parse request body
    const body = await req.json()
    const { image, languageHints } = body

    if (!image) {
      return new Response(
        JSON.stringify({ error: 'Missing image data' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Build Google Vision API request
    const visionRequest = {
      requests: [
        {
          image: { content: image },
          features: [
            { type: "TEXT_DETECTION", maxResults: 1 }
          ],
          imageContext: {
            languageHints: languageHints || ["zh-TW", "zh-CN", "en", "ja"]
          }
        }
      ]
    }

    // Call Google Vision API
    const visionResponse = await fetch(`${VISION_API_URL}?key=${googleApiKey}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(visionRequest)
    })

    if (!visionResponse.ok) {
      const errorData = await visionResponse.json()
      console.error('Google Vision API error:', errorData)
      return new Response(
        JSON.stringify({
          error: 'OCR processing failed',
          details: errorData.error?.message || 'Unknown error'
        }),
        { status: 502, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const visionData = await visionResponse.json()

    // Extract text from response
    let extractedText = ''
    if (visionData.responses?.[0]?.textAnnotations?.[0]?.description) {
      extractedText = visionData.responses[0].textAnnotations[0].description
    }

    // Return the extracted text
    return new Response(
      JSON.stringify({
        success: true,
        text: extractedText,
        // Optionally include full annotations for advanced parsing
        fullAnnotations: visionData.responses?.[0]?.textAnnotations
      }),
      {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )

  } catch (error) {
    console.error('OCR scan error:', error)
    return new Response(
      JSON.stringify({
        error: 'Internal server error',
        message: error.message
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
