/*
  # Add consent_records table

  1. New Tables
    - `consent_records`
      - `id` (uuid, primary key)
      - `patient_id` (uuid, foreign key to profiles.id)
      - `consent_type` (text)
      - `granted` (boolean)
      - `granted_at` (timestamptz, nullable)
      - `revoked_at` (timestamptz, nullable)
      - `ip_address` (text)
      - `user_agent` (text)
      - `created_at` (timestamptz)
  
  2. Security
    - Enable RLS on `consent_records` table
    - Add policies for patients to manage their own consent records
    - Add policies for providers to manage all consent records
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
  USING (uid() = patient_id);

-- Patients can insert their own consent records
CREATE POLICY "Authenticated users can insert their own consent records"
  ON consent_records
  FOR INSERT
  TO authenticated
  WITH CHECK (uid() = patient_id);

-- Patients can update their own consent records
CREATE POLICY "Patients can update their own consent records"
  ON consent_records
  FOR UPDATE
  TO authenticated
  USING (uid() = patient_id)
  WITH CHECK (uid() = patient_id);

-- Providers can read all consent records
CREATE POLICY "Providers can read all consent records"
  ON consent_records
  FOR SELECT
  TO authenticated
  USING ((SELECT role FROM profiles WHERE id = uid()) IN ('nurse', 'coordinator', 'admin', 'sales'));

-- Providers can insert consent records for any patient
CREATE POLICY "Providers can insert consent records for any patient"
  ON consent_records
  FOR INSERT
  TO authenticated
  WITH CHECK ((SELECT role FROM profiles WHERE id = uid()) IN ('nurse', 'coordinator', 'admin', 'sales'));

-- Providers can update any consent record
CREATE POLICY "Providers can update any consent record"
  ON consent_records
  FOR UPDATE
  TO authenticated
  USING ((SELECT role FROM profiles WHERE id = uid()) IN ('nurse', 'coordinator', 'admin', 'sales'))
  WITH CHECK ((SELECT role FROM profiles WHERE id = uid()) IN ('nurse', 'coordinator', 'admin', 'sales'));

-- Providers can delete consent records
CREATE POLICY "Providers can delete consent records"
  ON consent_records
  FOR DELETE
  TO authenticated
  USING ((SELECT role FROM profiles WHERE id = uid()) IN ('nurse', 'coordinator', 'admin', 'sales'));