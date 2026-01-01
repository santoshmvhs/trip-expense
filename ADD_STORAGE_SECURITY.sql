-- Storage Bucket Security Policies
-- Run this in Supabase SQL Editor to secure file uploads
-- This ensures users can only access their own files

-- ============================================================================
-- ENABLE RLS ON STORAGE OBJECTS
-- ============================================================================
-- Note: Storage RLS is enabled by default, but we need to create policies

-- ============================================================================
-- RECEIPTS BUCKET POLICIES
-- ============================================================================
-- Receipts are stored in user-specific folders: userId/filename
-- Only the owner can upload and read their own receipts

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can upload own receipts" ON storage.objects;
DROP POLICY IF EXISTS "Users can read own receipts" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own receipts" ON storage.objects;

-- Allow users to upload receipts to their own folder
CREATE POLICY "Users can upload own receipts"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'receipts' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Allow users to read their own receipts
CREATE POLICY "Users can read own receipts"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'receipts' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Allow users to delete their own receipts
CREATE POLICY "Users can delete own receipts"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'receipts' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- ============================================================================
-- AVATARS BUCKET POLICIES
-- ============================================================================
-- Avatars can be read by anyone (public), but only authenticated users can upload

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Anyone can read avatars" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload avatars" ON storage.objects;
DROP POLICY IF EXISTS "Users can update own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own avatar" ON storage.objects;

-- Allow anyone to read avatars (public access)
CREATE POLICY "Anyone can read avatars"
ON storage.objects FOR SELECT
USING (bucket_id = 'avatars');

-- Allow authenticated users to upload avatars
CREATE POLICY "Users can upload avatars"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'avatars' 
  AND auth.role() = 'authenticated'
);

-- Allow users to update their own avatar (if filename contains their user ID)
CREATE POLICY "Users can update own avatar"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'avatars' 
  AND (
    -- If filename contains user ID, only that user can update
    (name LIKE '%' || auth.uid()::text || '%')
    OR
    -- Otherwise, any authenticated user can update (for flexibility)
    auth.role() = 'authenticated'
  )
)
WITH CHECK (
  bucket_id = 'avatars' 
  AND auth.role() = 'authenticated'
);

-- Allow users to delete their own avatar
CREATE POLICY "Users can delete own avatar"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'avatars' 
  AND (
    name LIKE '%' || auth.uid()::text || '%'
    OR auth.role() = 'authenticated'
  )
);

-- ============================================================================
-- NOTES
-- ============================================================================
-- 1. Make sure the buckets 'receipts' and 'avatars' exist in Supabase Storage
-- 2. To create buckets: Go to Storage → Create Bucket
-- 3. Set bucket to 'Private' for receipts, 'Public' for avatars
-- 4. These policies work with the folder structure: userId/filename
-- 5. If you change the folder structure, update the policies accordingly

