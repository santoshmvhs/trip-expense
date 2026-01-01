# Supabase Password Reset URL Configuration

## Configure Password Reset URL in Supabase Dashboard

To set the password reset URL to `momentra.pureborn.in`, follow these steps:

### 1. Go to Supabase Dashboard
1. Log in to your Supabase project at https://supabase.com
2. Navigate to your project

### 2. Configure Authentication URLs
1. Go to **Authentication** → **URL Configuration** (or **Settings** → **Auth** → **URL Configuration`)
2. Find the **Site URL** field and set it to:
   ```
   https://momentra.pureborn.in
   ```
3. Find the **Redirect URLs** section and add:
   ```
   https://momentra.pureborn.in/**
   ```
   This allows redirects to any path under your domain.

### 3. Email Templates (Optional)
1. Go to **Authentication** → **Email Templates**
2. Find the **Reset Password** template
3. Update the redirect URL in the email template to use:
   ```
   {{ .SiteURL }}/auth/reset-password?token={{ .TokenHash }}&type=recovery
   ```
   Or if you have a custom path:
   ```
   https://momentra.pureborn.in/auth/reset-password?token={{ .TokenHash }}&type=recovery
   ```

### 4. Save Changes
Click **Save** to apply the changes.

## Notes
- The Site URL is used as the base URL for all authentication redirects
- The Redirect URLs list specifies which URLs are allowed for OAuth and email link redirects
- After changing these settings, password reset emails will use the new domain
- Make sure your domain `momentra.pureborn.in` is properly configured and accessible

## Testing
After configuration:
1. Use the "Forgot Password" feature in the app
2. Check the email you receive
3. The reset link should point to `momentra.pureborn.in`

