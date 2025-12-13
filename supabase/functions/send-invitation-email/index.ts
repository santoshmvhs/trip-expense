// @ts-nocheck
// Note: TypeScript errors here are expected - this code runs on Deno (Supabase Edge Functions)
// The IDE uses Node.js types, but Supabase uses Deno runtime. These errors won't affect deployment.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// Resend API configuration
const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY') || 're_ESV5eFps_2ewphsgvvp26VgniRaVnocf3'
const EMAIL_FROM = Deno.env.get('EMAIL_FROM') || 'noreply@pureborn.in'

serve(async (req) => {
  try {
    // Get JWT token from Authorization header (optional - for logging)
    const authHeader = req.headers.get('Authorization')
    console.log('Function called with auth:', authHeader ? 'Yes' : 'No')
    
    const { email, groupName, groupId, token } = await req.json()
    console.log('Sending email to:', email, 'for group:', groupName)

    // Get Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Build invitation link
    const invitationLink = `${Deno.env.get('APP_URL') || 'https://yourapp.com'}/invite/${token}`

    // Send email using Resend API
    console.log('=== RESEND EMAIL DEBUG ===')
    console.log('Using API key:', RESEND_API_KEY.substring(0, 10) + '...')
    console.log('Full API key length:', RESEND_API_KEY.length)
    console.log('API key from env:', Deno.env.get('RESEND_API_KEY') ? 'YES' : 'NO (using fallback)')
    console.log('Sending from:', EMAIL_FROM)
    console.log('Sending to:', email)
    console.log('Email from env:', Deno.env.get('EMAIL_FROM') ? Deno.env.get('EMAIL_FROM') : 'NO (using fallback)')
    
    const requestBody = {
      from: EMAIL_FROM,
      to: email,
      subject: `You've been invited to join ${groupName}`,
      html: `
          <!DOCTYPE html>
          <html>
          <head>
            <style>
              body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
              .container { max-width: 600px; margin: 0 auto; padding: 20px; }
              .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
              .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
              .button { display: inline-block; padding: 12px 30px; background: #667eea; color: white; text-decoration: none; border-radius: 5px; margin: 20px 0; }
              .footer { text-align: center; margin-top: 20px; color: #666; font-size: 12px; }
            </style>
          </head>
          <body>
            <div class="container">
              <div class="header">
                <h1>💰 You've Been Invited!</h1>
              </div>
              <div class="content">
                <p>Hi there!</p>
                <p>You've been invited to join the expense group <strong>"${groupName}"</strong> on SettleUp.</p>
                <p>Click the button below to accept the invitation and start splitting expenses:</p>
                <p style="text-align: center;">
                  <a href="${invitationLink}" class="button">Accept Invitation</a>
                </p>
                <p>Or sign up at: <a href="${Deno.env.get('APP_URL') || 'https://yourapp.com'}/signup">${Deno.env.get('APP_URL') || 'https://yourapp.com'}/signup</a></p>
                <p>If you didn't expect this invitation, you can safely ignore this email.</p>
              </div>
              <div class="footer">
                <p>This invitation will expire in 30 days.</p>
              </div>
            </div>
          </body>
          </html>
        `,
    }
    
    console.log('Request body (without HTML):', JSON.stringify({ ...requestBody, html: '[HTML content]' }))
    console.log('Making fetch request to Resend...')
    
    const emailResponse = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${RESEND_API_KEY}`,
      },
      body: JSON.stringify(requestBody),
    })

    console.log('=== RESEND RESPONSE ===')
    console.log('Status:', emailResponse.status)
    console.log('Status Text:', emailResponse.statusText)
    
    const responseText = await emailResponse.text()
    console.log('Response body:', responseText)
    
    try {
      const responseJson = JSON.parse(responseText)
      console.log('Parsed response:', JSON.stringify(responseJson, null, 2))
    } catch (e) {
      console.log('Response is not JSON')
    }

    if (!emailResponse.ok) {
      let errorMessage = `Email service error: ${emailResponse.statusText}`
      try {
        const errorData = JSON.parse(responseText)
        if (errorData.message) {
          errorMessage = `Resend API error: ${errorData.message}`
        }
      } catch (e) {
        // If response isn't JSON, use status text
      }
      
      // Provide helpful error messages
      if (emailResponse.status === 403) {
        errorMessage += ' (Forbidden - Check: 1) API key is valid, 2) Domain is verified in Resend, 3) "from" email matches verified domain)'
      } else if (emailResponse.status === 401) {
        errorMessage += ' (Unauthorized - API key is invalid or expired)'
      }
      
      throw new Error(errorMessage)
    }

    return new Response(
      JSON.stringify({ success: true, message: 'Email sent successfully' }),
      { headers: { 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Error sending email:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})

