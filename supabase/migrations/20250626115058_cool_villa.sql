/*
  # Add consent_records table
  
  1. New Tables
    - `consent_records`
      - `id` (uuid, primary key)
      - `patient_id` (uuid, references profiles)
      - `consent_type` (text)
      - `granted` (boolean)
      - `granted_at` (timestamp with time zone, nullable)
      - `revoked_at` (timestamp with time zone, nullable)
      - `ip_address` (text)
      - `user_agent` (text)
      - `created_at` (timestamp with time zone)
  
  2. Security
    - Enable RLS on `consent_records` table
    - Add policies for patients to manage their own records
    - Add policies for providers to manage all records
*/

-- Create consent_records table if it doesn't exist
CREATE TABLE IF NOT EXISTS consent_records (
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

-- Patients can read their own consent records
CREATE POLICY "Patients can read their own consent records"
  ON consent_records
  FOR SELECT
  TO authenticated
  USING (auth.uid() = patient_id);

-- Patients can insert their own consent records
CREATE POLICY "Authenticated users can insert their own consent records"
  ON consent_records
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = patient_id);

-- Patients can update their own consent records
CREATE POLICY "Patients can update their own consent records"
  ON consent_records
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = patient_id)
  WITH CHECK (auth.uid() = patient_id);

-- Providers can read all consent records
CREATE POLICY "Providers can read all consent records"
  ON consent_records
  FOR SELECT
  TO authenticated
  USING ((SELECT role FROM profiles WHERE id = auth.uid()) IN ('nurse', 'coordinator', 'admin', 'sales'));

-- Providers can insert consent records for any patient
CREATE POLICY "Providers can insert consent records for any patient"
  ON consent_records
  FOR INSERT
  TO authenticated
  WITH CHECK ((SELECT role FROM profiles WHERE id = auth.uid()) IN ('nurse', 'coordinator', 'admin', 'sales'));

-- Providers can update any consent record
CREATE POLICY "Providers can update any consent record"
  ON consent_records
  FOR UPDATE
  TO authenticated
  USING ((SELECT role FROM profiles WHERE id = auth.uid()) IN ('nurse', 'coordinator', 'admin', 'sales'))
  WITH CHECK ((SELECT role FROM profiles WHERE id = auth.uid()) IN ('nurse', 'coordinator', 'admin', 'sales'));

-- Providers can delete consent records
CREATE POLICY "Providers can delete consent records"
  ON consent_records
  FOR DELETE
  TO authenticated
  USING ((SELECT role FROM profiles WHERE id = auth.uid()) IN ('nurse', 'coordinator', 'admin', 'sales'));