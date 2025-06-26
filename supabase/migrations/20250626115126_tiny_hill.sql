/*
  # Consent Records Table and Policies

  1. New Tables
    - `consent_records` - Stores patient consent information
      - `id` (uuid, primary key)
      - `patient_id` (uuid, references profiles)
      - `consent_type` (text)
      - `granted` (boolean)
      - `granted_at` (timestamptz)
      - `revoked_at` (timestamptz)
      - `ip_address` (text)
      - `user_agent` (text)
      - `created_at` (timestamptz)
  
  2. Security
    - Enable RLS on `consent_records` table
    - Add policies for patients to manage their own records
    - Add policies for providers to manage all records
*/

-- Create consent_records table if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'consent_records') THEN
    CREATE TABLE consent_records (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      patient_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
      consent_type TEXT NOT NULL,
      granted BOOLEAN NOT NULL,
      granted_at TIMESTAMPTZ,
      revoked_at TIMESTAMPTZ,
      ip_address TEXT NOT NULL,
      user_agent TEXT NOT NULL,
      created_at TIMESTAMPTZ NOT NULL DEFAULT now()
    );
    
    -- Enable Row Level Security
    ALTER TABLE consent_records ENABLE ROW LEVEL SECURITY;
  END IF;
END $$;

-- Create policies only if they don't exist
DO $$ 
BEGIN
  -- Patients can read their own consent records
  IF NOT EXISTS (SELECT FROM pg_policies WHERE tablename = 'consent_records' AND policyname = 'Patients can read their own consent records') THEN
    CREATE POLICY "Patients can read their own consent records"
      ON consent_records
      FOR SELECT
      TO authenticated
      USING (auth.uid() = patient_id);
  END IF;

  -- Patients can insert their own consent records
  IF NOT EXISTS (SELECT FROM pg_policies WHERE tablename = 'consent_records' AND policyname = 'Authenticated users can insert their own consent records') THEN
    CREATE POLICY "Authenticated users can insert their own consent records"
      ON consent_records
      FOR INSERT
      TO authenticated
      WITH CHECK (auth.uid() = patient_id);
  END IF;

  -- Patients can update their own consent records
  IF NOT EXISTS (SELECT FROM pg_policies WHERE tablename = 'consent_records' AND policyname = 'Patients can update their own consent records') THEN
    CREATE POLICY "Patients can update their own consent records"
      ON consent_records
      FOR UPDATE
      TO authenticated
      USING (auth.uid() = patient_id)
      WITH CHECK (auth.uid() = patient_id);
  END IF;

  -- Providers can read all consent records
  IF NOT EXISTS (SELECT FROM pg_policies WHERE tablename = 'consent_records' AND policyname = 'Providers can read all consent records') THEN
    CREATE POLICY "Providers can read all consent records"
      ON consent_records
      FOR SELECT
      TO authenticated
      USING ((SELECT role FROM profiles WHERE id = auth.uid()) IN ('nurse', 'coordinator', 'admin', 'sales'));
  END IF;

  -- Providers can insert consent records for any patient
  IF NOT EXISTS (SELECT FROM pg_policies WHERE tablename = 'consent_records' AND policyname = 'Providers can insert consent records for any patient') THEN
    CREATE POLICY "Providers can insert consent records for any patient"
      ON consent_records
      FOR INSERT
      TO authenticated
      WITH CHECK ((SELECT role FROM profiles WHERE id = auth.uid()) IN ('nurse', 'coordinator', 'admin', 'sales'));
  END IF;

  -- Providers can update any consent record
  IF NOT EXISTS (SELECT FROM pg_policies WHERE tablename = 'consent_records' AND policyname = 'Providers can update any consent record') THEN
    CREATE POLICY "Providers can update any consent record"
      ON consent_records
      FOR UPDATE
      TO authenticated
      USING ((SELECT role FROM profiles WHERE id = auth.uid()) IN ('nurse', 'coordinator', 'admin', 'sales'))
      WITH CHECK ((SELECT role FROM profiles WHERE id = auth.uid()) IN ('nurse', 'coordinator', 'admin', 'sales'));
  END IF;

  -- Providers can delete consent records
  IF NOT EXISTS (SELECT FROM pg_policies WHERE tablename = 'consent_records' AND policyname = 'Providers can delete consent records') THEN
    CREATE POLICY "Providers can delete consent records"
      ON consent_records
      FOR DELETE
      TO authenticated
      USING ((SELECT role FROM profiles WHERE id = auth.uid()) IN ('nurse', 'coordinator', 'admin', 'sales'));
  END IF;
END $$;