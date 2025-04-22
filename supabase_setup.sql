-- 1. First, add is_admin column to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_admin BOOLEAN DEFAULT FALSE;

-- 2. Create resources table
CREATE TABLE IF NOT EXISTS resources (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  category TEXT NOT NULL,
  department TEXT NOT NULL,
  semester INTEGER NOT NULL,
  file_path TEXT NOT NULL,
  file_url TEXT NOT NULL,
  file_type TEXT NOT NULL,
  file_size BIGINT NOT NULL,
  uploaded_by UUID REFERENCES auth.users(id) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- 3. Create storage bucket for resources if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
SELECT 'resources', 'resources', true
WHERE NOT EXISTS (
  SELECT 1 FROM storage.buckets WHERE id = 'resources'
);

-- 4. Set up storage policies

-- Allow authenticated users to read files
CREATE POLICY "Allow authenticated users to read"
ON storage.objects FOR SELECT
USING (bucket_id = 'resources' AND auth.role() = 'authenticated');

-- Allow admin users to upload files
CREATE POLICY "Allow admin users to upload"
ON storage.objects FOR INSERT
USING (
  bucket_id = 'resources' AND 
  (SELECT is_admin FROM public.users WHERE id = auth.uid())
);

-- Allow admin users to update their files
CREATE POLICY "Allow admin users to update"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'resources' AND 
  (SELECT is_admin FROM public.users WHERE id = auth.uid())
);

-- Allow admin users to delete their files
CREATE POLICY "Allow admin users to delete"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'resources' AND 
  (SELECT is_admin FROM public.users WHERE id = auth.uid())
);

-- 5. Set up policies for the resources table

-- Allow all authenticated users to read resources
CREATE POLICY "Allow authenticated users to select resources"
ON resources FOR SELECT
USING (auth.role() = 'authenticated');

-- Allow only admin users to insert resources
CREATE POLICY "Allow admin users to insert resources"
ON resources FOR INSERT
WITH CHECK ((SELECT is_admin FROM public.users WHERE id = auth.uid()));

-- Allow admin users to update resources
CREATE POLICY "Allow admin users to update resources"
ON resources FOR UPDATE
USING ((SELECT is_admin FROM public.users WHERE id = auth.uid()));

-- Allow admin users to delete resources
CREATE POLICY "Allow admin users to delete resources"
ON resources FOR DELETE
USING ((SELECT is_admin FROM public.users WHERE id = auth.uid()));

-- 6. Set an existing user as admin (replace with your user ID)
UPDATE users SET is_admin = TRUE WHERE id = auth.uid();

-- Create buckets table if it doesn't exist (sometimes needed for older Supabase versions)
CREATE TABLE IF NOT EXISTS storage.buckets (
  id text NOT NULL,
  name text NOT NULL,
  owner uuid,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  public boolean DEFAULT false,
  PRIMARY KEY (id)
);

-- Create objects table if it doesn't exist
CREATE TABLE IF NOT EXISTS storage.objects (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  bucket_id text,
  name text,
  owner uuid,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  last_accessed_at timestamptz DEFAULT now(),
  metadata jsonb,
  path_tokens text[] GENERATED ALWAYS AS (string_to_array(name, '/')) STORED,
  PRIMARY KEY (id),
  CONSTRAINT objects_bucketid_fkey FOREIGN KEY (bucket_id) REFERENCES storage.buckets(id)
);

-- Reset policies (drop and recreate)
DROP POLICY IF EXISTS "Allow public read access" ON storage.objects;
DROP POLICY IF EXISTS "Allow individual insert access" ON storage.objects;
DROP POLICY IF EXISTS "Allow individual update access" ON storage.objects;
DROP POLICY IF EXISTS "Allow individual delete access" ON storage.objects;
DROP POLICY IF EXISTS "Allow bucket creation" ON storage.buckets;
DROP POLICY IF EXISTS "Allow public access" ON storage.buckets;

-- Make sure we have RLS enabled
ALTER TABLE storage.buckets ENABLE ROW LEVEL SECURITY;
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Fix users table recursion issue
DROP POLICY IF EXISTS "User policy" ON public.users;

-- Create new policies
-- 1. Allow users to create buckets (critical for your app)
CREATE POLICY "Allow bucket creation" ON storage.buckets
FOR INSERT
TO authenticated
WITH CHECK (true);

-- 2. Allow public access to buckets (needed to read/access files)
CREATE POLICY "Allow public access" ON storage.buckets
FOR SELECT
TO public
USING (true);

-- 3. Allow users to upload objects to buckets
CREATE POLICY "Allow individual insert access" ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (true);

-- 4. Allow public read access to objects
CREATE POLICY "Allow public read access" ON storage.objects
FOR SELECT
TO public
USING (true);

-- 5. Allow users to update and delete their own objects
CREATE POLICY "Allow individual update access" ON storage.objects
FOR UPDATE
TO authenticated
USING (owner = auth.uid())
WITH CHECK (owner = auth.uid());

CREATE POLICY "Allow individual delete access" ON storage.objects
FOR DELETE
TO authenticated
USING (owner = auth.uid());

-- 6. Fix users table policy to prevent recursion
CREATE POLICY "User policy - fixed" ON public.users
FOR ALL
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- Create resources bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('resources', 'resources', true)
ON CONFLICT (id) DO NOTHING;

-- Add RPC function to insert resources
CREATE OR REPLACE FUNCTION insert_resource(
  p_title TEXT,
  p_description TEXT,
  p_category TEXT,
  p_department TEXT,
  p_semester INTEGER,
  p_file_path TEXT,
  p_file_url TEXT,
  p_file_type TEXT,
  p_file_size BIGINT,
  p_uploaded_by UUID
) RETURNS uuid AS $$
DECLARE
  v_id UUID;
BEGIN
  INSERT INTO resources (
    title, 
    description, 
    category, 
    department, 
    semester, 
    file_path, 
    file_url, 
    file_type, 
    file_size, 
    uploaded_by
  ) VALUES (
    p_title, 
    p_description, 
    p_category, 
    p_department, 
    p_semester, 
    p_file_path, 
    p_file_url, 
    p_file_type, 
    p_file_size, 
    p_uploaded_by
  ) RETURNING id INTO v_id;
  
  RETURN v_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RPC function to get admin status
CREATE OR REPLACE FUNCTION get_admin_status(user_id UUID) RETURNS BOOLEAN AS $$
BEGIN
  RETURN (SELECT is_admin FROM public.users WHERE id = user_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RPC function to set admin status
CREATE OR REPLACE FUNCTION set_admin_status(user_id UUID, is_admin BOOLEAN) RETURNS VOID AS $$
BEGIN
  INSERT INTO public.users (id, is_admin)
  VALUES (user_id, is_admin)
  ON CONFLICT (id) DO UPDATE SET is_admin = EXCLUDED.is_admin;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
