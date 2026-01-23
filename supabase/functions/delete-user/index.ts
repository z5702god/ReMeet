// Supabase Edge Function: delete-user
// Completely deletes a user account including auth.users record
// This is required for GDPR "right to be forgotten" compliance

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight request
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Get the authorization header
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      throw new Error('Missing authorization header')
    }

    // Create Supabase client with user's JWT
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

    // Extract JWT token from Authorization header
    const token = authHeader.replace('Bearer ', '')

    // Client with user's auth - to verify the user is authenticated
    const supabaseUser = createClient(supabaseUrl, supabaseAnonKey, {
      global: {
        headers: { Authorization: authHeader },
      },
    })

    // Verify the user is authenticated using the token
    const { data: { user }, error: userError } = await supabaseUser.auth.getUser(token)

    if (userError || !user) {
      throw new Error('User not authenticated')
    }

    const userId = user.id
    console.log(`Deleting user account: ${userId}`)

    // Create admin client with service role key - for deleting auth.users
    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    })

    // Delete user data in order (respecting foreign key constraints)
    // 1. Delete meeting contexts
    const { error: meetingError } = await supabaseAdmin
      .from('meeting_contexts')
      .delete()
      .eq('user_id', userId)

    if (meetingError) {
      console.error('Error deleting meeting contexts:', meetingError)
    }

    // 2. Delete business cards
    const { error: cardsError } = await supabaseAdmin
      .from('business_cards')
      .delete()
      .eq('user_id', userId)

    if (cardsError) {
      console.error('Error deleting business cards:', cardsError)
    }

    // 3. Delete contacts
    const { error: contactsError } = await supabaseAdmin
      .from('contacts')
      .delete()
      .eq('user_id', userId)

    if (contactsError) {
      console.error('Error deleting contacts:', contactsError)
    }

    // 4. Delete storage files
    try {
      const { data: files } = await supabaseAdmin.storage
        .from('business-cards')
        .list(userId)

      if (files && files.length > 0) {
        const paths = files.map(f => `${userId}/${f.name}`)
        await supabaseAdmin.storage
          .from('business-cards')
          .remove(paths)
      }
    } catch (storageError) {
      console.error('Warning: Failed to delete storage files:', storageError)
      // Continue anyway - storage deletion is not critical
    }

    // 5. Delete users table record
    const { error: userTableError } = await supabaseAdmin
      .from('users')
      .delete()
      .eq('id', userId)

    if (userTableError) {
      console.error('Error deleting user record:', userTableError)
    }

    // 6. Delete from auth.users using Admin API
    const { error: authDeleteError } = await supabaseAdmin.auth.admin.deleteUser(userId)

    if (authDeleteError) {
      console.error('Error deleting auth user:', authDeleteError)
      throw new Error('Failed to delete authentication record')
    }

    console.log(`Successfully deleted user: ${userId}`)

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Account successfully deleted'
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200
      }
    )

  } catch (error) {
    console.error('Delete user error:', error)

    return new Response(
      JSON.stringify({
        success: false,
        error: error.message || 'Failed to delete account'
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400
      }
    )
  }
})
